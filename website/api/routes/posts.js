const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

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
    
    const { data, error } = await supabase
      .from('posts')
      .insert([post])
      .select();

    if (error) throw error;
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
