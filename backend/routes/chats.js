const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const NotificationService = require('../services/notification_service');

// Get chat by ID
router.get('/:chatId', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('chats')
      .select('*')
      .eq('id', req.params.chatId)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all chats for a user
router.get('/user/:uid', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('chats')
      .select('*')
      .contains('participants', [req.params.uid])
      .order('lastMessageTime', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read
router.post('/:chatId/read', async (req, res) => {
  try {
    const { userId } = req.body;
    const { error } = await supabase
      .from('messages')
      .update({ isRead: true })
      .eq('chatId', req.params.chatId)
      .neq('senderId', userId);

    if (error) throw error;
    res.json({ message: 'Messages marked as read' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get unread count for user
router.get('/user/:uid/unread', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('id', { count: 'exact' })
      .eq('isRead', false)
      .neq('senderId', req.params.uid);

    if (error) throw error;
    res.json({ count: data.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create chat
router.post('/', async (req, res) => {
  try {
    const chat = req.body;
    chat.createdAt = chat.createdAt || Date.now();
    
    const { data, error } = await supabase
      .from('chats')
      .upsert(chat, { onConflict: 'id' })
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get messages for a chat with timestamp/cursor pagination
router.get('/:chatId/messages', async (req, res) => {
  try {
    const { limit, before } = req.query;
    let query = supabase
      .from('messages')
      .select('*')
      .eq('chatId', req.params.chatId);

    if (before) {
      query = query.lt('timestamp', parseInt(before));
    }

    query = query.order('timestamp', { ascending: false });

    if (limit) {
      query = query.limit(parseInt(limit));
    } else {
      query = query.limit(50);
    }

    const { data, error } = await query;

    if (error) throw error;
    // Reverse before returning so they are chronological for UI
    res.json(data.reverse());
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message
router.post('/messages', async (req, res) => {
  try {
    const message = req.body;
    message.timestamp = message.timestamp || Date.now();
    message.status = 'sent'; // Backend strictly forces status = "sent"
    
    // 1. Insert message
    const { data: msgData, error: msgError } = await supabase
      .from('messages')
      .insert([message])
      .select();

    if (msgError) throw msgError;

    // 2. Update chat last message
    await supabase
      .from('chats')
      .update({
        lastMessage: message.text || message.content || 'Image',
        lastMessageTime: message.timestamp
      })
      .eq('id', message.chatId);

    // 3. Notify recipient
    try {
      const { data: chat, error: chatError } = await supabase
        .from('chats')
        .select('participants')
        .eq('id', message.chatId)
        .single();

      if (!chatError && chat) {
        const recipientId = chat.participants.find(p => p !== message.senderId);
        if (recipientId) {
          await NotificationService.sendToUser(recipientId, {
            title: 'New Message',
            body: message.text || message.content || 'You received an image',
            data: { 
              chatId: message.chatId, 
              senderId: message.senderId,
              type: 'chat' 
            }
          });
        }
      }
    } catch (notifErr) {
      console.error('Failed to send chat notification:', notifErr);
    }

    res.status(201).json(msgData[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
