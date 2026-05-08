const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const BlockchainService = require('../services/blockchain_service');
const NotificationService = require('../services/notification_service');
const MatchmakerService = require('../services/matchmaker_service');
const { verifyToken, checkRole } = require('../middleware/auth');

// Helper matching logic delegated to proactive MatchmakerService
async function runMatchingLogic(newPost) {
  try {
    await MatchmakerService.runMatching(newPost);
  } catch (err) {
    console.error('Error running matchmaking system:', err);
  }
}

// Valid transitions check
const validTransitions = {
  'open': ['matched', 'claimed', 'resolved'],
  'matched': ['claimed', 'resolved'],
  'claimed': ['resolved'],
  'resolved': []
};

// Get all posts
router.get('/', async (req, res) => {
  try {
    const { type, status, limit, offset } = req.query;
    let query = supabase.from('posts').select('id, userId, type, title, description, imageUrl, location_name, buildingName, floor, location_room, location_lat, location_lng, timestamp, status, aiTags, reportCount, viewCount, likeCount, isCMSVerified, category').order('timestamp', { ascending: false });

    if (type) query = query.eq('type', type);
    if (status) query = query.eq('status', status);
    if (limit) query = query.range(parseInt(offset) || 0, (parseInt(offset) || 0) + (parseInt(limit) - 1));

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
router.post('/:postId/comments', verifyToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const comment = req.body;
    comment.userId = req.user.uid;
    
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
router.post('/:postId/like', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
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
          const { data: liker } = await supabase.from('users').select('name').eq('uid', userId).single();
          const likerName = liker ? liker.name : 'Someone';
          await NotificationService.sendToUser(post.userId, {
            title: '❤️ New Like',
            body: `${likerName} liked your post "${post.title}"`,
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
router.post('/', verifyToken, async (req, res) => {
  try {
    const post = req.body;
    post.userId = req.user.uid;
    post.timestamp = post.timestamp || Date.now();
    post.status = post.status || 'open';
    
    const { data, error } = await supabase
      .from('posts')
      .insert([post])
      .select();

    if (error) throw error;

    // Run matching engine asynchronously
    runMatchingLogic(data[0]).catch(e => console.error('Matching system error:', e));

    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update post
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // Fetch current post
    const { data: oldPost, error: fetchErr } = await supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchErr || !oldPost) return res.status(404).json({ error: 'Post not found' });

    // USER OWNERSHIP ENFORCEMENT
    if (oldPost.userId !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden: You do not own this post' });
    }

    // STATE TRANSITION VALIDATION
    if (updates.status && updates.status !== oldPost.status) {
      const allowed = validTransitions[oldPost.status] || [];
      if (!allowed.includes(updates.status)) {
        return res.status(400).json({ error: `Invalid transition from ${oldPost.status} to ${updates.status}` });
      }
    }

    const { data: updatedPost, error } = await supabase
      .from('posts')
      .update(updates)
      .eq('id', id)
      .select();

    if (error) throw error;

    // Check for resolution
    if (updates.status === 'resolved' && oldPost.status !== 'resolved') {
      await NotificationService.sendToUser(oldPost.userId, {
        title: '🏁 Item Resolved',
        body: `Your post "${oldPost.title}" has been marked as resolved.`,
        type: 'resolution',
        data: { postId: id, type: 'resolution' }
      });

      if (oldPost.claimedBy) {
        await NotificationService.sendToUser(oldPost.claimedBy, {
          title: '🌟 Karma Earned!',
          body: `You earned 50 Karma points for helping resolve "${oldPost.title}"!`,
          type: 'karma',
          data: { postId: id, type: 'karma' }
        });
      }
    } else {
      // Run matching if status hasn't resolved
      runMatchingLogic(updatedPost[0]).catch(e => console.error('Matching system error:', e));
    }

    res.json(updatedPost[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete post
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: oldPost, error: fetchErr } = await supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchErr || !oldPost) return res.status(404).json({ error: 'Post not found' });

    // USER OWNERSHIP ENFORCEMENT
    if (oldPost.userId !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden: You do not own this post' });
    }

    const { error } = await supabase
      .from('posts')
      .delete()
      .eq('id', id);

    if (error) throw error;
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
