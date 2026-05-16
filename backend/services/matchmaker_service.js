const supabase = require('../utils/supabase');
const NotificationService = require('./notification_service');
const AIService = require('./ai_service');
const NodeCache = require('node-cache');

// Cache matches for 1 hour to keep "For You" feed efficient
const matchCache = new NodeCache({ stdTTL: 3600 });

class MatchmakerService {
  /**
   * Compares a newly created post against potential matches of opposite type
   * @param {Object} newPost - The post object that was just created/updated
   */
  static async runMatching(newPost) {
    console.log(`[Matchmaker] Running matching for post: ${newPost.id} ("${newPost.title}")`);
    if (newPost.status === 'resolved') return;
    const oppositeType = newPost.type === 'lost' ? 'found' : 'lost';

    const { data: potentialMatches, error } = await supabase
      .from('posts')
      .select('*')
      .eq('type', oppositeType)
      .neq('status', 'resolved');

    if (error || !potentialMatches) {
      console.error('[Matchmaker] Error fetching candidates:', error);
      return;
    }

    console.log(`[Matchmaker] Found ${potentialMatches.length} potential ${oppositeType} candidates.`);

    // Phase 1: Efficiency Layer (Heuristic Pre-filtering)
    const filteredCandidates = potentialMatches.filter(match => {
      let score = 0;
      if (newPost.category && match.category && newPost.category.toLowerCase() === match.category.toLowerCase()) score += 30;
      if (newPost.buildingName && match.buildingName && newPost.buildingName.toLowerCase() === match.buildingName.toLowerCase()) score += 20;
      
      const titleSim = this.calculateTitleSimilarity(newPost.title, match.title);
      score += titleSim * 30;

      const passed = score >= 20; // Lowered threshold to be more inclusive
      if (passed) console.log(`[Matchmaker] Candidate "${match.title}" passed heuristic with score: ${score}`);
      return passed;
    }).slice(0, 10); // Increase to 10 candidates

    if (filteredCandidates.length === 0) {
      console.log('[Matchmaker] No candidates passed the heuristic filter.');
      return;
    }

    console.log(`[Matchmaker] Sending ${filteredCandidates.length} candidates to AI for deep evaluation...`);

    // Phase 2: AI Deep Dive
    const aiMatches = await AIService.comparePosts(newPost, filteredCandidates);
    console.log(`[Matchmaker] AI returned ${aiMatches.length} results.`);
    
    const finalMatches = aiMatches
      .filter(m => m.score >= 50) // Lowered confidence threshold for testing
      .map(m => {
        const fullPost = filteredCandidates.find(c => c.id === m.candidateId);
        return { ...m, post: fullPost };
      });

    console.log(`[Matchmaker] ${finalMatches.length} matches met the confidence threshold.`);

    // Phase 3: Persistence & Notification
    if (finalMatches.length > 0) {
      this.saveMatchesToCache(newPost.userId, newPost.id, finalMatches);
      console.log(`[Matchmaker] Saved matches to cache for user ${newPost.userId}`);

      for (const m of finalMatches) {
        // Notify current post owner
        await NotificationService.sendToUser(newPost.userId, {
          title: 'AI Match Detected',
          body: `High match (${m.score}%) for "${newPost.title}". Reason: ${m.reason}`,
          type: 'match',
          data: { 
            postId: newPost.id, 
            matchPostId: m.post.id, 
            score: String(m.score),
            reason: m.reason 
          }
        });

        // Notify matched post owner (inverse)
        this.saveMatchesToCache(m.post.userId, m.post.id, [{ ...m, post: newPost }]);
        await NotificationService.sendToUser(m.post.userId, {
          title: 'AI Match Detected',
          body: `High match (${m.score}%) for your item "${m.post.title}".`,
          type: 'match',
          data: { 
            postId: m.post.id, 
            matchPostId: newPost.id, 
            score: String(m.score),
            reason: m.reason 
          }
        });
      }
    }
  }

  static saveMatchesToCache(userId, postId, matches) {
    const key = `matches_${userId}`;
    const existing = matchCache.get(key) || {};
    existing[postId] = matches;
    matchCache.set(key, existing);
  }

  static async getMatchesForUser(userId) {
    const key = `matches_${userId}`;
    let userMatches = matchCache.get(key);

    if (!userMatches) {
      console.log(`[Matchmaker] Cache empty for user ${userId}. Triggering proactive scan...`);
      // Trigger matching for all of this user's posts
      const { data: userPosts } = await supabase
        .from('posts')
        .select('*')
        .eq('userId', userId)
        .neq('status', 'resolved');

      if (userPosts && userPosts.length > 0) {
        for (const post of userPosts) {
          await this.runMatching(post);
        }
      }
      userMatches = matchCache.get(key) || {};
    }

    // Flatten all matches for all user posts into a single list
    return Object.values(userMatches).flat();
  }

  static calculateTitleSimilarity(titleA, titleB) {
    if (!titleA || !titleB) return 0;
    const wordsA = titleA.toLowerCase().split(/\W+/).filter(Boolean);
    const wordsB = titleB.toLowerCase().split(/\W+/).filter(Boolean);
    if (wordsA.length === 0 || wordsB.length === 0) return 0;

    const intersection = wordsA.filter(w => wordsB.includes(w)).length;
    const union = new Set([...wordsA, ...wordsB]).size;
    return union === 0 ? 0 : intersection / union;
  }
}

module.exports = MatchmakerService;
