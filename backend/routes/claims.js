const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const { verifyToken } = require('../middleware/auth');
const BlockchainService = require('../services/blockchain_service');
const NotificationService = require('../services/notification_service');

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

    // 4. Notify the Finder (Post Owner)
    await NotificationService.sendToUser(post.userId, {
      title: '🎁 New Claim Request',
      body: `Someone wants to claim "${post.title}". Review their proof now.`,
      type: 'claim_request',
      data: { claimId: claim.id, postId: postId }
    });

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

    // 3. If approved, unlock chat (handled by chat route usually, but we notify)
    // and potentially mark other claims as rejected? (Optional)
    
    // 4. Notify Claimer
    await NotificationService.sendToUser(claim.claimer_id, {
      title: status === 'approved' ? '✅ Claim Approved!' : '❌ Claim Rejected',
      body: status === 'approved' 
        ? `Your claim for "${claim.posts.title}" was approved. You can now chat with the finder.`
        : `Your claim for "${claim.posts.title}" was rejected by the finder.`,
      type: 'claim_response',
      data: { claimId: id, status }
    });

    res.json(updatedClaim);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * PHASE 3: The Handshake
 * Verify the QR scan and finalize the recovery
 */
router.post('/handshake/verify', verifyToken, async (req, res) => {
  try {
    const { claimId } = req.body;
    const currentUserId = req.user.uid;

    // 1. Fetch the claim
    const { data: claim, error: fetchError } = await supabase
      .from('claims')
      .select('*, posts(*)')
      .eq('id', claimId)
      .single();

    if (fetchError || !claim) return res.status(404).json({ error: 'Claim not found' });
    
    const validStates = ['approved', 'finder_confirmed', 'owner_confirmed', 'resolved'];
    if (!validStates.includes(claim.status)) {
      return res.status(400).json({ error: 'Claim must be approved' });
    }

    // Single scan immediately resolves the claim, matching the single-scanner Flutter UI
    const newStatus = 'resolved';

    if (currentUserId !== claim.claimer_id && currentUserId !== claim.posts.userId) {
      return res.status(403).json({ error: 'Unauthorized to participate in this handshake' });
    }

    // Update claim status
    const { error: claimUpdateError } = await supabase
      .from('claims')
      .update({ status: newStatus })
      .eq('id', claimId);

    if (claimUpdateError) throw claimUpdateError;

    // If resolved, finalize the Handover
    if (newStatus === 'resolved') {
      const { error: postUpdateError } = await supabase
        .from('posts')
        .update({ status: 'resolved', resolved_at: new Date().toISOString() })
        .eq('id', claim.post_id);

      if (postUpdateError) throw postUpdateError;

      // PHASE 4: Blockchain & Karma
      const claimData = {
        action: 'ITEM_RECOVERED_VIA_HANDSHAKE',
        claimId: claim.id,
        itemId: claim.post_id,
        itemTitle: claim.posts.title,
        claimerId: claim.claimer_id,
        finderId: claim.posts.userId,
        timestamp: Date.now()
      };
      
      await BlockchainService.recordClaim(claim.post_id, claimData);

      // Increment Karma for Finder
      try {
        const { error: rpcError } = await supabase.rpc('increment_karma', { user_id: claim.posts.userId, amount: 50 });
        if (rpcError) {
          const { data: user } = await supabase.from('users').select('karma_points').eq('uid', claim.posts.userId).single();
          await supabase.from('users').update({ karma_points: (user?.karma_points || 0) + 50 }).eq('uid', claim.posts.userId);
        }
      } catch (e) {
        console.error('Karma update failed:', e);
      }

      await NotificationService.sendToUser(claim.claimer_id, {
        title: '🎉 Item Resolved!',
        body: `"${claim.posts.title}" has been successfully returned and recorded on the blockchain.`,
        type: 'item_resolved',
        data: { postId: claim.post_id }
      });

      return res.json({ message: 'Handover complete and verified on blockchain! Karma awarded.', status: 'resolved' });
    }

    res.json({ message: `Confirmation recorded: ${newStatus}`, status: newStatus });
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
