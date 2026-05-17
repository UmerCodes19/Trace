const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

const { cache } = require('../middleware/cache');

// Get public leaderboard
// Performance Optimization: 60-second ultra-cache for heavy user aggregation
router.get('/leaderboard', cache(60), async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('uid, name, email, photoURL, karmaPoints, itemsReturned')
      .order('karmaPoints', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

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
    
    // Attempt upsert
    let { data, error } = await supabase
      .from('users')
      .upsert(user, { onConflict: 'uid' })
      .select();

    // If column doesn't exist, retry without privacy_settings
    if (error && error.message.includes('privacy_settings')) {
      console.warn('Database missing privacy_settings column. Retrying without it.');
      const { privacy_settings, ...userWithoutPrivacy } = user;
      const retry = await supabase
        .from('users')
        .upsert(userWithoutPrivacy, { onConflict: 'uid' })
        .select();
      
      data = retry.data;
      error = retry.error;
    }

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

// Sync FCM Token with device stealing prevention
router.post('/sync-token', async (req, res) => {
  try {
    const { userId, token, name, email } = req.body;
    if (!userId || !token) return res.status(400).json({ error: 'userId and token are required' });
    
    // 1. Clear this token from any other user (Device sharing prevention)
    // This ensures that if User A logs out and User B logs in on the same phone,
    // User A will no longer receive notifications via this token.
    await supabase
      .from('users')
      .update({ fcm_token: null })
      .eq('fcm_token', token)
      .neq('uid', userId);
      
    // 2. Assign token to THIS user
    const { data, error } = await supabase
      .from('users')
      .update({ 
        fcm_token: token,
        ...(name && { name }),
        ...(email && { email }),
        lastActive: Date.now()
      })
      .eq('uid', userId)
      .select();
      
    if (error) throw error;
    res.json({ message: 'Token successfully assigned to user', user: data ? data[0] : null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
