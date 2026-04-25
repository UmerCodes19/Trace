const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

// Get user profile
router.get('/:uid', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('uid', req.params.uid)
      .single();

    if (error && error.code !== 'PGRST116') throw error; // PGRST116 is not found
    res.json(data || null);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create or update user profile (sync)
router.post('/sync', async (req, res) => {
  try {
    const user = req.body;
    user.lastActive = Date.now();
    
    const { data, error } = await supabase
      .from('users')
      .upsert(user, { onConflict: 'uid' })
      .select();

    if (error) throw error;
    res.json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update stats
router.post('/:uid/stats', async (req, res) => {
  try {
    const { itemsLost, itemsFound, itemsReturned, karmaPoints } = req.body;
    
    // We need to fetch current stats first or use a RPC if we want atomic increments
    // For simplicity, let's assume the app sends the increment values
    const { data: user, error: fetchError } = await supabase
      .from('users')
      .select('itemsLost, itemsFound, itemsReturned, karmaPoints')
      .eq('uid', req.params.uid)
      .single();

    if (fetchError) throw fetchError;

    const updates = {
      itemsLost: (user.itemsLost || 0) + (itemsLost || 0),
      itemsFound: (user.itemsFound || 0) + (itemsFound || 0),
      itemsReturned: (user.itemsReturned || 0) + (itemsReturned || 0),
      karmaPoints: (user.karmaPoints || 0) + (karmaPoints || 0),
      lastActive: Date.now()
    };

    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('uid', req.params.uid)
      .select();

    if (error) throw error;
    res.json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
