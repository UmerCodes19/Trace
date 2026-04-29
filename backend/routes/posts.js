const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const BlockchainService = require('../services/blockchain_service');
const NotificationService = require('../services/notification_service');
const { verifyToken, checkRole } = require('../middleware/auth');


// Get all posts
router.get('/', async (req, res) => {
  try {
    const { type, status, limit, offset } = req.query;
    let query = supabase.from('posts').select('*').order('timestamp', { ascending: false });

    if (type) query = query.eq('type', type);
    if (status) query = query.eq('status', status);
    if (limit) query = query.range(offset || 0, (parseInt(offset) || 0) + (parseInt(limit) - 1));

    const { data, error } = await query;

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get comments for a post
router.get('/:postId/comments', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('comments')
      .select('*')
      .eq('postId', req.params.postId)
      .order('timestamp', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add comment to a post
router.post('/:postId/comments', async (req, res) => {
  try {
    const { postId } = req.params;
    const comment = req.body;
    
    const { error } = await supabase
      .from('comments')
      .insert(comment);
    
    if (error) throw error;

    // Notify post owner
    try {
      const { data: post } = await supabase
        .from('posts')
        .select('userId, title')
        .eq('id', postId)
        .single();

      if (post && post.userId !== comment.userId) {
        await NotificationService.sendToUser(post.userId, {
          title: '💬 New Comment',
          body: `${comment.userName || 'Someone'} commented on "${post.title}"`,
          type: 'comment',
          data: { postId, type: 'comment' }
        });
      }
    } catch (notifErr) {
      console.error('Failed to send comment notification:', notifErr);
    }

    res.json({ message: 'Comment added' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Increment view count
router.post('/:postId/view', async (req, res) => {
  try {
    const { error } = await supabase.rpc('increment_view_count', { post_id: req.params.postId });
    if (error) throw error;
    res.json({ message: 'View count incremented' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Check if liked
router.get('/:postId/liked/:userId', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('likes')
      .select('*')
      .eq('postId', req.params.postId)
      .eq('userId', req.params.userId)
      .single();

    res.json({ liked: !!data });
  } catch (error) {
    res.json({ liked: false });
  }
});

// Toggle like
router.post('/:postId/like', async (req, res) => {
  try {
    const { userId } = req.body;
    const { postId } = req.params;

    const { data: existing } = await supabase
      .from('likes')
      .select('*')
      .eq('postId', postId)
      .eq('userId', userId)
      .single();

    if (existing) {
      await supabase.from('likes').delete().eq('id', existing.id);
      res.json({ liked: false });
    } else {
      await supabase.from('likes').insert({ postId, userId });
      
      // Notify post owner
      try {
        const { data: post } = await supabase
          .from('posts')
          .select('userId, title')
          .eq('id', postId)
          .single();

        if (post && post.userId !== userId) {
          await NotificationService.sendToUser(post.userId, {
            title: '❤️ New Like',
            body: `Someone liked your post "${post.title}"`,
            type: 'like',
            data: { postId, type: 'like' }
          });
        }
      } catch (notifErr) {
        console.error('Failed to send like notification:', notifErr);
      }

      res.json({ liked: true });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Report post
router.post('/:postId/report', verifyToken, async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .update({ isReported: true })
      .eq('id', req.params.postId);
    
    if (error) throw error;

    // Notify admins/staff about report
    await NotificationService.broadcastToRole('admin', {
      title: '🚨 Post Reported',
      body: `A post has been reported for moderation.`,
      data: { postId: req.params.postId, type: 'report' }
    });

    res.json({ message: 'Post reported' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Claim an item
router.post('/:id/claim', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    // 1. Fetch post to get owner
    const { data: post, error: fetchError } = await supabase
      .from('posts')
      .select('userId, title, status')
      .eq('id', id)
      .single();

    if (fetchError || !post) throw new Error('Post not found');
    if (post.status !== 'open') throw new Error('Item is no longer available');
    if (post.userId === userId) throw new Error('You cannot claim your own item');

    // 2. Update post status
    const { error: updateError } = await supabase
      .from('posts')
      .update({ status: 'claimed', claimedBy: userId })
      .eq('id', id);

    if (updateError) throw updateError;

    // 3. Record in Blockchain Log
    const claimData = {
      action: 'CLAIM_INITIATED',
      itemId: id,
      itemTitle: post.title,
      claimerId: userId,
      ownerId: post.userId
    };
    const logEntry = await BlockchainService.recordClaim(id, claimData);

    // 4. Notify Post Owner
    await NotificationService.sendToUser(post.userId, {
      title: '🎁 New Claim!',
      body: `Someone has claimed your item: "${post.title}"`,
      data: { postId: id, type: 'claim', claimId: logEntry.id }
    });

    res.json({ message: 'Claim initiated successfully', logId: logEntry.id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// Delete post
router.delete('/:postId', async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .delete()
      .eq('id', req.params.postId);
    
    if (error) throw error;
    res.json({ message: 'Post deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get post by ID
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create post
router.post('/', async (req, res) => {
  try {
    const post = req.body;
    post.timestamp = post.timestamp || Date.now();
    post.status = post.status || 'open';
    
    const { data, error } = await supabase
      .from('posts')
      .insert([post])
      .select();

    if (error) throw error;

    // Broadcast new post notification to all users
    try {
      await NotificationService.broadcastToAll({
        title: `🔍 New ${post.type === 'lost' ? 'Lost' : 'Found'} Item`,
        body: `${post.title} has been reported in ${post.location || 'campus'}.`,
        type: 'new_post',
        data: { postId: data[0].id, type: 'post' }
      });
    } catch (notifErr) {
      console.error('Failed to broadcast new post notification:', notifErr);
    }

    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update post
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // 1. Fetch current post to check status change
    const { data: oldPost } = await supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .single();

    const { data: updatedPost, error } = await supabase
      .from('posts')
      .update(updates)
      .eq('id', id)
      .select();

    if (error) throw error;

    // 2. Check for resolution
    if (updates.status === 'resolved' && oldPost && oldPost.status !== 'resolved') {
      // Notify Owner
      await NotificationService.sendToUser(oldPost.userId, {
        title: '🏁 Item Resolved',
        body: `Your post "${oldPost.title}" has been marked as resolved.`,
        type: 'resolution',
        data: { postId: id, type: 'resolution' }
      });

      // Notify Claimer (if exists)
      if (oldPost.claimedBy) {
        await NotificationService.sendToUser(oldPost.claimedBy, {
          title: '🌟 Karma Earned!',
          body: `You earned 50 Karma points for helping resolve "${oldPost.title}"!`,
          type: 'karma',
          data: { postId: id, type: 'karma' }
        });
      }
    }

    res.json(updatedPost[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete post
router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
