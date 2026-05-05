const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  const token = authHeader.split('Bearer ')[1];
  try {
    const admin = require('firebase-admin');
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(token);
    } catch (e) {
      // Fallback: Check if token is a valid UID in the users table
      const { data: testUser } = await supabase
        .from('users')
        .select('uid, email, role, isBanned')
        .eq('uid', token)
        .single();

      if (testUser) {
        if (testUser.isBanned) {
          return res.status(403).json({ error: 'User is banned' });
        }
        req.user = {
          uid: testUser.uid,
          email: testUser.email || `${testUser.uid}@bahria.edu.pk`,
          role: testUser.role || 'user'
        };
        return next();
      }
      throw e;
    }

    const { data: user } = await supabase
      .from('users')
      .select('role, isBanned')
      .eq('uid', decodedToken.uid)
      .single();

    if (user && user.isBanned) {
      return res.status(403).json({ error: 'User is banned' });
    }

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: user ? user.role : 'user'
    };
    next();
  } catch (error) {
    console.error('Auth Error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Get notification history for a user
router.get('/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    if (req.user.uid !== userId) {
      return res.status(403).json({ error: 'Access denied: You cannot view notifications for other users.' });
    }

    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark a single notification as read
router.post('/:notificationId/read', verifyToken, async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    // Validate that the user owns the notification
    const { data: notif } = await supabase
      .from('notifications')
      .select('user_id')
      .eq('id', notificationId)
      .single();

    if (!notif || notif.user_id !== req.user.uid) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark all as read for a user
router.post('/user/:userId/read-all', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    if (req.user.uid !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
