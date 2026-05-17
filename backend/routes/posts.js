const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');
const BlockchainService = require('../services/blockchain_service');
const NotificationService = require('../services/notification_service');
const MatchmakerService = require('../services/matchmaker_service');
const { verifyToken, checkRole } = require('../middleware/auth');
const { cache, invalidate } = require('../middleware/cache');

// Helper matching logic delegated to proactive MatchmakerService
async function runMatchingLogic(newPost) {
  try {
    await MatchmakerService.runMatching(newPost);
  } catch (err) {
    console.error('Error running matchmaking system:', err);
  }
}

// Valid transitions check
const validTransitions = {
  'open': ['matched', 'claimed', 'resolved'],
  'matched': ['claimed', 'resolved'],
  'claimed': ['resolved'],
  'resolved': []
};

// Get all posts with scalable server-side filtering and cursor offset pagination
// Layer 2 Performance: 15-second high-speed RAM buffer caching
router.get('/', cache(15), async (req, res) => {
  try {
    const { type, status, limit, offset, building, category, search, recency } = req.query;
    
    let query = supabase
      .from('posts')
      .select('id, userId, type, title, description, imageUrl, location_name, buildingName, floor, location_room, location_lat, location_lng, timestamp, status, aiTags, reportCount, viewCount, likeCount, isCMSVerified')
      .order('timestamp', { ascending: false });

    // Basic exact matches
    if (type) query = query.eq('type', type);
    if (status) query = query.eq('status', status);
    if (building) query = query.ilike('buildingName', `%${building}%`);
    // if (category) query = query.eq('category', category); // Disabled: Database schema mismatch

    // High-performance date-partition query pruning
    if (recency) {
      const now = new Date();
      if (recency === 'Today') now.setDate(now.getDate() - 1);
      else if (recency === 'Last 3 Days') now.setDate(now.getDate() - 3);
      else if (recency === 'This Week') now.setDate(now.getDate() - 7);
      else if (recency === 'This Month') now.setMonth(now.getMonth() - 1);
      
      if (['Today', 'Last 3 Days', 'This Week', 'This Month'].includes(recency)) {
        // Handle ISO or numeric epoch timestamps safely
        query = query.or(`timestamp.gte.${now.toISOString()},timestamp.gte.${now.getTime()}`);
      }
    }

    // Full Text / Substring Parallel Lookup
    if (search && search.trim().length > 0) {
      const cleanSearch = search.trim();
      query = query.or(`title.ilike.%${cleanSearch}%,description.ilike.%${cleanSearch}%,buildingName.ilike.%${cleanSearch}%`);
    }

    // Infinite Page Windows applied AFTER constraints
    if (limit) {
      const start = parseInt(offset) || 0;
      const end = start + (parseInt(limit) - 1);
      query = query.range(start, end);
    }

    const { data, error } = await query;

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get comments for a post
// Active 30-second RAM buffer for read-heavy comment threads
router.get('/:postId/comments', cache(30), async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('comments')
      .select('*')
      .eq('postId', req.params.postId)
      .order('timestamp', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add comment to a post
router.post('/:postId/comments', verifyToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const comment = req.body;
    comment.userId = req.user.uid;
    
    const { error } = await supabase
      .from('comments')
      .insert(comment);
    
    if (error) throw error;

    // Notify post owner
    try {
      const { data: post } = await supabase
        .from('posts')
        .select('userId, title')
        .eq('id', postId)
        .single();

      if (post && post.userId !== comment.userId) {
        await NotificationService.sendToUser(post.userId, {
          title: '💬 New Comment',
          body: `${comment.userName || 'Someone'} commented on "${post.title}"`,
          type: 'comment',
          data: { postId, type: 'comment' }
        });
      }
    } catch (notifErr) {
      console.error('Failed to send comment notification:', notifErr);
    }

    res.json({ message: 'Comment added' });
    // Bust comments cache so newly added comment shows instantly
    invalidate(`/${postId}/comments`);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Increment view count
router.post('/:postId/view', async (req, res) => {
  try {
    const { error } = await supabase.rpc('increment_view_count', { post_id: req.params.postId });
    if (error) throw error;
    res.json({ message: 'View count incremented' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Check if liked
router.get('/:postId/liked/:userId', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('likes')
      .select('*')
      .eq('postId', req.params.postId)
      .eq('userId', req.params.userId)
      .single();

    res.json({ liked: !!data });
  } catch (error) {
    res.json({ liked: false });
  }
});

// Toggle like
router.post('/:postId/like', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { postId } = req.params;

    const { data: existing } = await supabase
      .from('likes')
      .select('*')
      .eq('postId', postId)
      .eq('userId', userId)
      .single();

    if (existing) {
      await supabase.from('likes').delete().eq('id', existing.id);
      res.json({ liked: false });
    } else {
      await supabase.from('likes').insert({ postId, userId });
      
      // Notify post owner
      try {
        const { data: post } = await supabase
          .from('posts')
          .select('userId, title')
          .eq('id', postId)
          .single();

        if (post && post.userId !== userId) {
          const { data: liker } = await supabase.from('users').select('name').eq('uid', userId).single();
          const likerName = liker ? liker.name : 'Someone';
          await NotificationService.sendToUser(post.userId, {
            title: '❤️ New Like',
            body: `${likerName} liked your post "${post.title}"`,
            type: 'like',
            data: { postId, type: 'like' }
          });
        }
      } catch (notifErr) {
        console.error('Failed to send like notification:', notifErr);
      }

      res.json({ liked: true });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Report post
router.post('/:postId/report', verifyToken, async (req, res) => {
  try {
    const { error } = await supabase
      .from('posts')
      .update({ isReported: true })
      .eq('id', req.params.postId);
    
    if (error) throw error;

    await NotificationService.broadcastToRole('admin', {
      title: '🚨 Post Reported',
      body: `A post has been reported for moderation.`,
      data: { postId: req.params.postId, type: 'report' }
    });

    res.json({ message: 'Post reported' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get post by ID
// Layer 2 Static Cache for isolated objects
router.get('/:id', cache(60), async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('id', req.params.id)
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ error: 'Post not found' });
    }
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create post
router.post('/', verifyToken, async (req, res) => {
  try {
    const post = req.body;
    post.userId = req.user.uid;
    post.timestamp = post.timestamp || Date.now();
    post.status = post.status || 'open';
    
    const { data, error } = await supabase
      .from('posts')
      .insert([post])
      .select();

    if (error) throw error;

    // Run matching engine asynchronously
    runMatchingLogic(data[0]).catch(e => console.error('Matching system error:', e));

    // Auto-evict static post lists to maintain real-time feed integrity
    invalidate('/posts');

    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update post
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // Fetch current post
    const { data: oldPost, error: fetchErr } = await supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchErr || !oldPost) return res.status(404).json({ error: 'Post not found' });

    // USER OWNERSHIP ENFORCEMENT
    if (oldPost.userId !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden: You do not own this post' });
    }

    // STATE TRANSITION VALIDATION
    if (updates.status && updates.status !== oldPost.status) {
      const allowed = validTransitions[oldPost.status] || [];
      if (!allowed.includes(updates.status)) {
        return res.status(400).json({ error: `Invalid transition from ${oldPost.status} to ${updates.status}` });
      }
    }

    const { data: updatedPost, error } = await supabase
      .from('posts')
      .update(updates)
      .eq('id', id)
      .select();

    if (error) throw error;

    // Check for resolution
    if (updates.status === 'resolved' && oldPost.status !== 'resolved') {
      await NotificationService.sendToUser(oldPost.userId, {
        title: '🏁 Item Resolved',
        body: `Your post "${oldPost.title}" has been marked as resolved.`,
        type: 'resolution',
        data: { postId: id, type: 'resolution' }
      });

      if (oldPost.claimedBy) {
        await NotificationService.sendToUser(oldPost.claimedBy, {
          title: '🌟 Karma Earned!',
          body: `You earned 50 Karma points for helping resolve "${oldPost.title}"!`,
          type: 'karma',
          data: { postId: id, type: 'karma' }
        });
      }
    } else {
      // Run matching if status hasn't resolved
      runMatchingLogic(updatedPost[0]).catch(e => console.error('Matching system error:', e));
    }

    invalidate('/posts');
    res.json(updatedPost[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete post
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: oldPost, error: fetchErr } = await supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchErr || !oldPost) return res.status(404).json({ error: 'Post not found' });

    // USER OWNERSHIP ENFORCEMENT
    if (oldPost.userId !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden: You do not own this post' });
    }

    const { error } = await supabase
      .from('posts')
      .delete()
      .eq('id', id);

    if (error) throw error;
    invalidate('/posts');
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get personalized AI matches for the user
router.get('/for-you', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const matches = await MatchmakerService.getMatchesForUser(userId);
    res.json(matches);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
