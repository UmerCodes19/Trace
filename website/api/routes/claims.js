const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const NotificationService = require('../services/notification_service');

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

/**
 * PHASE 2: The Gatekeeper
 * Create a new claim request for an item.
 */
router.post('/request', verifyToken, async (req, res) => {
  try {
    const { postId, proofText, proofImageUrl } = req.body;
    const userId = req.user.uid;

    // 1. Check if post exists and is open
    const { data: post, error: postError } = await supabase
      .from('posts')
      .select('userId, title, status')
      .eq('id', postId)
      .single();

    if (postError || !post) return res.status(404).json({ error: 'Post not found' });
    if (post.status !== 'open') return res.status(400).json({ error: 'Item is not available for claiming' });
    if (post.userId === userId) return res.status(400).json({ error: 'You cannot claim your own item' });

    // 2. Check if a pending claim already exists
    const { data: existing } = await supabase
      .from('claims')
      .select('*')
      .eq('post_id', postId)
      .eq('claimer_id', userId)
      .single();

    if (existing) return res.status(400).json({ error: 'You have already submitted a claim for this item' });

    // 3. Create the claim request
    const { data: claim, error: claimError } = await supabase
      .from('claims')
      .insert({
        post_id: postId,
        claimer_id: userId,
        proof_text: proofText,
        proof_image_url: proofImageUrl,
        status: 'pending'
      })
      .select()
      .single();

    if (claimError) throw claimError;

    if (post && post.userId !== userId) {
      await NotificationService.sendToUser(post.userId, {
        title: '🎁 New Claim Request',
        body: `Someone wants to claim "${post.title}". Review their proof now.`,
        type: 'claim_request',
        data: { claimId: claim.id, postId: postId }
      });
    }

    res.status(201).json(claim);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Respond to a claim (Approve/Reject)
 */
router.put('/respond/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'approved' or 'rejected'
    const userId = req.user.uid;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    // 1. Fetch claim and check if current user is the post owner
    const { data: claim, error: fetchError } = await supabase
      .from('claims')
      .select('*, posts(userId, title)')
      .eq('id', id)
      .single();

    if (fetchError || !claim) return res.status(404).json({ error: 'Claim not found' });
    if (claim.posts.userId !== userId) return res.status(403).json({ error: 'Unauthorized' });

    // 2. Update claim status
    const { data: updatedClaim, error: updateError } = await supabase
      .from('claims')
      .update({ status })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    if (claim && claim.claimer_id !== req.user.uid) {
      await NotificationService.sendToUser(claim.claimer_id, {
        title: status === 'approved' ? '✅ Claim Approved!' : '❌ Claim Rejected',
        body: status === 'approved' 
          ? `Your claim for "${claim.posts.title}" was approved. You can now chat with the finder.`
          : `Your claim for "${claim.posts.title}" was rejected by the finder.`,
        type: 'claim_response',
        data: { claimId: id, status }
      });
    }

    res.json(updatedClaim);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get claims made by the current user (the claimer)
 */
router.get('/my', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { data, error } = await supabase
      .from('claims')
      .select('*, posts(*)')
      .eq('claimer_id', userId);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get claims for a specific post (for the finder)
 */
router.get('/post/:postId', verifyToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('claims')
      .select('*, users:claimer_id(name, email, photoURL)')
      .eq('post_id', req.params.postId);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
