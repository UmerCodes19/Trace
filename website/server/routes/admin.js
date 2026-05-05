const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const NotificationService = require('../services/notification_service');
const { verifyToken, checkRole } = require('../middleware/auth');


// Get admin stats
router.get('/stats', async (req, res) => {
  try {
    const { count: totalPosts } = await supabase.from('posts').select('*', { count: 'exact', head: true });
    const { count: resolvedPosts } = await supabase.from('posts').select('*', { count: 'exact', head: true }).eq('status', 'resolved');
    const { count: totalUsers } = await supabase.from('users').select('*', { count: 'exact', head: true });
    const { count: totalComments } = await supabase.from('comments').select('*', { count: 'exact', head: true });

    const resolutionRate = totalPosts > 0 ? (resolvedPosts / totalPosts) * 100 : 0;

    res.json({
      totalPosts,
      resolutionRate,
      totalUsers,
      totalComments
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get flagged posts
router.get('/flagged-posts', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('isReported', true);
    
    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users
router.get('/users', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*');
    
    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Set user ban status
router.post('/users/:uid/ban', async (req, res) => {
  try {
    const { isBanned } = req.body;
    const { error } = await supabase
      .from('users')
      .update({ isBanned })
      .eq('uid', req.params.uid);
    
    if (error) throw error;
    res.json({ message: 'Ban status updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Approve or reject post
router.post('/posts/:postId/moderation', async (req, res) => {
  try {
    const { status, note } = req.body; // status: 'open' or 'rejected'
    
    const { data: post, error: fetchError } = await supabase
      .from('posts')
      .select('userId, title')
      .eq('id', req.params.postId)
      .single();

    if (fetchError) throw fetchError;

    const { error } = await supabase
      .from('posts')
      .update({ 
        status, 
        isReported: false,
        moderatorNote: note
      })
      .eq('id', req.params.postId);
    
    if (error) throw error;

    // Notify user about moderation action
    await NotificationService.sendToUser(post.userId, {
      title: status === 'open' ? '✅ Post Approved' : '❌ Post Rejected',
      body: status === 'open' 
        ? `Your post "${post.title}" is now visible to everyone.`
        : `Your post "${post.title}" was rejected: ${note || 'Violates community guidelines.'}`,
      data: { postId: req.params.postId, type: 'moderation' }
    });

    res.json({ message: `Post ${status}` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user role (Admin only)
router.post('/users/:uid/role', checkRole(['admin']), async (req, res) => {
  try {
    const { role } = req.body;
    const { error } = await supabase
      .from('users')
      .update({ role })
      .eq('uid', req.params.uid);
    
    if (error) throw error;
    res.json({ message: `Role updated to ${role}` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all claim logs (Audit trail)
router.get('/audit-logs', async (req, res) => {
  try {
    const { data: logs, error } = await supabase
      .from('claim_logs')
      .select('*')
      .order('timestamp', { ascending: false });

    if (error) throw error;
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


module.exports = router;
