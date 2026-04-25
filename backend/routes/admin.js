const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

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

// Clear post reports
router.post('/posts/:postId/clear-reports', async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .update({ isReported: false })
      .eq('id', req.params.postId);
    
    if (error) throw error;
    res.json({ message: 'Reports cleared' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
