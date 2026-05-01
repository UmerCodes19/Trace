const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

// In-memory storage for pending link codes (valid for 10 mins)
const activeLinkCodes = {};

// Periodic cleanup
setInterval(() => {
  const now = Date.now();
  for (const [code, data] of Object.entries(activeLinkCodes)) {
    if (now > data.expiresAt) {
      delete activeLinkCodes[code];
    }
  }
}, 30 * 1000);

// Endpoint 1: Generate 6-char code, store with user_id
router.post('/link-code', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    activeLinkCodes[code] = {
      userId,
      expiresAt: Date.now() + 10 * 60 * 1000
    };

    res.json({ code });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint 2: Link discord_id to user_id
router.post('/verify', async (req, res) => {
  try {
    const { code, discord_id, discord_name } = req.body;
    if (!code || !discord_id || !discord_name) {
      return res.status(400).json({ error: 'code, discord_id, and discord_name are required' });
    }

    const data = activeLinkCodes[code];
    if (!data || Date.now() > data.expiresAt) {
      return res.status(400).json({ error: 'Invalid or expired code. Generate a new code in the Trace app.' });
    }

    // Safe mapping without string/BigInt parsing into the 'day' integer column
    const entry = {
      enrollment: `discord:${discord_id}`,
      courseCode: data.userId,
      courseTitle: discord_name,
      roomName: discord_id,
      buildingName: '#discord_link',
      day: 1
    };

    // Remove old mapping just in case
    await supabase
      .from('cms_timetable')
      .delete()
      .eq('enrollment', `discord:${discord_id}`);

    const { error } = await supabase
      .from('cms_timetable')
      .insert([entry]);

    if (error) throw error;

    delete activeLinkCodes[code];

    res.json({ message: 'Linked successfully!', user_id: data.userId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint 3: Get user_id from discord_id
router.get('/user/:discord_id', async (req, res) => {
  try {
    const { discord_id } = req.params;
    const { data, error } = await supabase
      .from('cms_timetable')
      .select('*')
      .eq('enrollment', `discord:${discord_id}`)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Discord ID is not linked to any Trace account' });
    }

    res.json({ user_id: data.courseCode });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint 4: Remove discord link
router.post('/unlink', async (req, res) => {
  try {
    const { discord_id } = req.body;
    if (!discord_id) {
      return res.status(400).json({ error: 'discord_id is required' });
    }

    const { error } = await supabase
      .from('cms_timetable')
      .delete()
      .eq('enrollment', `discord:${discord_id}`);

    if (error) throw error;

    res.json({ message: 'Unlinked successfully!' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
