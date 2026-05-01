const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const { verifyToken } = require('../middleware/auth');

// Get notifications for a user
router.get('/:uid', verifyToken, async (req, res) => {
  try {
    if (req.user.uid !== req.params.uid) {
      return res.status(403).json({ error: 'Access denied: You cannot view notifications for other users.' });
    }

    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('userId', req.params.uid)
      .order('timestamp', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark notification as read
router.post('/:id/read', verifyToken, async (req, res) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ isRead: true })
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark all as read
router.post('/user/:uid/read-all', verifyToken, async (req, res) => {
  try {
    if (req.user.uid !== req.params.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { error } = await supabase
      .from('notifications')
      .update({ isRead: true })
      .eq('userId', req.params.uid);

    if (error) throw error;
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
