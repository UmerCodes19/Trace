const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const NotificationService = require('../services/notification_service');

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
    const { error } = await supabase
      .from('comments')
      .insert(req.body);
    
    if (error) throw error;

    // Send Notification to post owner
    const { data: post } = await supabase.from('posts').select('userId, title').eq('id', req.params.postId).single();
    if (post && post.userId !== req.body.userId) {
      await NotificationService.sendToUser(post.userId, {
        title: 'New Comment',
        body: `${req.body.userName || 'Someone'} commented on "${post.title}"`,
        type: 'comment',
        data: { postId: req.params.postId }
      });
    }

    res.json({ message: 'Comment added' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Report post
router.post('/:postId/report', async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .update({ isReported: true })
      .eq('id', req.params.postId);
    
    if (error) throw error;
    res.json({ message: 'Post reported' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Increment view count
router.post('/:postId/view', async (req, res) => {
  try {
    const { postId } = req.params;
    // Simple update - in a real app, you'd use a RPC for atomic increments
    const { data: post } = await supabase.from('posts').select('"viewCount"').eq('id', postId).single();
    const { data, error } = await supabase
      .from('posts')
      .update({ viewCount: (post?.viewCount || 0) + 1 })
      .eq('id', postId)
      .select();

    if (error) throw error;
    res.json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
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

    const { data: post } = await supabase.from('posts').select('"likeCount"').eq('id', postId).single();

    if (existing) {
      await supabase.from('likes').delete().eq('id', existing.id);
      const { data } = await supabase.from('posts').update({ likeCount: Math.max(0, (post?.likeCount || 0) - 1) }).eq('id', postId).select();
      res.json({ liked: false, likeCount: data[0].likeCount });
    } else {
      await supabase.from('likes').insert({ postId, userId });
      const { data } = await supabase.from('posts').update({ likeCount: (post?.likeCount || 0) + 1 }).eq('id', postId).select();
      
      // Send Notification
      const { data: fullPost } = await supabase.from('posts').select('userId, title').eq('id', postId).single();
      if (fullPost && fullPost.userId !== userId) {
        await NotificationService.sendToUser(fullPost.userId, {
          title: 'New Like',
          body: `Someone liked your post "${fullPost.title}"`,
          type: 'like',
          data: { postId }
        });
      }

      res.json({ liked: true, likeCount: data[0].likeCount });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Check if liked
router.get('/:postId/liked/:userId', async (req, res) => {
  try {
    const { data } = await supabase
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
    
    // Auto-fill poster info if missing
    if (!post.posterName || !post.posterAvatarUrl) {
      const { data: user } = await supabase
        .from('users')
        .select('name, photoURL')
        .eq('uid', post.userId)
        .single();
      
      if (user) {
        post.posterName = post.posterName || user.name;
        post.posterAvatarUrl = post.posterAvatarUrl || user.photoURL;
      }
    }

    const { data, error } = await supabase
      .from('posts')
      .insert([post])
      .select();

    if (error) throw error;

    // Broadcast to Admins/Staff for new post
    await NotificationService.broadcastToRole('admin', {
      title: 'New Report',
      body: `New ${post.type} item: ${post.title}`,
      type: 'admin_alert',
      data: { postId: data[0].id }
    });

    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update post
router.put('/:id', async (req, res) => {
  try {
    const updates = req.body;
    const { data, error } = await supabase
      .from('posts')
      .update(updates)
      .eq('id', req.params.id)
      .select();

    if (error) throw error;

    // Notify user if post is resolved (Karma update)
    if (updates.status === 'resolved') {
      await NotificationService.sendToUser(data[0].userId, {
        title: 'Item Recovered!',
        body: `Congratulations! Your item "${data[0].title}" is marked as resolved. +10 Karma!`,
        type: 'karma_alert',
        data: { postId: req.params.id }
      });
    }

    res.json(data[0]);
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
