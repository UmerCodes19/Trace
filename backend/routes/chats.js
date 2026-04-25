const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

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
    // This is a simplified version. In a real app, you'd join with messages table
    // or store unread counts in the chat table.
    // For now, let's just return a static 0 or implement a simple query.
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

// Get messages for a chat
router.get('/:chatId/messages', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('chatId', req.params.chatId)
      .order('timestamp', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message
router.post('/messages', async (req, res) => {
  try {
    const message = req.body;
    message.timestamp = message.timestamp || Date.now();
    
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
        lastMessage: message.text || 'Image',
        lastMessageTime: message.timestamp
      })
      .eq('id', message.chatId);

    res.status(201).json(msgData[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
