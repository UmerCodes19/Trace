const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

// Get notification history for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('userId', userId)
      .order('timestamp', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark a single notification as read
router.post('/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { error } = await supabase
      .from('notifications')
      .update({ isRead: true })
      .eq('id', notificationId);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark all as read for a user
router.post('/user/:userId/read-all', async (req, res) => {
  try {
    const { userId } = req.params;
    const { error } = await supabase
      .from('notifications')
      .update({ isRead: true })
      .eq('userId', userId)
      .eq('isRead', false);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
