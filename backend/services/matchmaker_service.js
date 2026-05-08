const supabase = require('../utils/supabase');
const NotificationService = require('./notification_service');

class MatchmakerService {
  /**
   * Compares a newly created post against potential matches of opposite type
   * @param {Object} newPost - The post object that was just created/updated
   */
  static async runMatching(newPost) {
    if (newPost.status === 'resolved') return;
    const oppositeType = newPost.type === 'lost' ? 'found' : 'lost';

    const { data: potentialMatches, error } = await supabase
      .from('posts')
      .select('*')
      .eq('type', oppositeType)
      .neq('status', 'resolved');

    if (error || !potentialMatches) return;

    const matchesFound = [];

    for (const match of potentialMatches) {
      let score = 0;

      // 1. Exact Category Match (Weight: 30%)
      if (newPost.category && match.category && newPost.category.toLowerCase() === match.category.toLowerCase()) {
        score += 30;
      }

      // 2. Title Keyword Similarity (Weight: 25%)
      const titleSim = this.calculateTitleSimilarity(newPost.title, match.title);
      score += titleSim * 25;

      // 3. AI Tags Overlap Intersection-over-Union (Weight: 25%)
      const tagIoU = this.calculateTagOverlap(newPost.aiTags, match.aiTags);
      score += tagIoU * 25;

      // 4. Spatiotemporal & Location Closeness (Weight: 20%)
      let geoScore = 0;
      if (newPost.buildingName && match.buildingName && newPost.buildingName.toLowerCase() === match.buildingName.toLowerCase()) {
        geoScore += 10;
        if (newPost.floor === match.floor) {
          geoScore += 5;
        }
        if (newPost.location_room && match.location_room && newPost.location_room.toLowerCase() === match.location_room.toLowerCase()) {
          geoScore += 5;
        }
      }
      score += geoScore;

      // Check if threshold met (Score >= 75%)
      if (score >= 75) {
        matchesFound.push({ post: match, score: Math.round(score) });
      }
    }

    // Sort descending by match score
    matchesFound.sort((a, b) => b.score - a.score);
    const topMatches = matchesFound.slice(0, 3);

    for (const m of topMatches) {
      // Notify current post owner
      await NotificationService.sendToUser(newPost.userId, {
        title: '🔍 Proactive AI Match Detected!',
        body: `We found a ${m.score}% match for your post "${newPost.title}" with "${m.post.title}".`,
        type: 'match',
        data: { postId: newPost.id, matchPostId: m.post.id, score: String(m.score) }
      });

      // Notify matched post owner
      await NotificationService.sendToUser(m.post.userId, {
        title: '🔍 Proactive AI Match Detected!',
        body: `We found a ${m.score}% match for your post "${m.post.title}" with "${newPost.title}".`,
        type: 'match',
        data: { postId: m.post.id, matchPostId: newPost.id, score: String(m.score) }
      });
    }
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

  static calculateTagOverlap(tagsA, tagsB) {
    const listA = this.parseTags(tagsA);
    const listB = this.parseTags(tagsB);
    if (listA.length === 0 || listB.length === 0) return 0;

    const intersection = listA.filter(t => listB.includes(t)).length;
    const union = new Set([...listA, ...listB]).size;
    return union === 0 ? 0 : intersection / union;
  }

  static parseTags(tagsInput) {
    if (!tagsInput) return [];
    if (Array.isArray(tagsInput)) return tagsInput.map(t => String(t).toLowerCase());
    if (typeof tagsInput === 'string') {
      try {
        const parsed = JSON.parse(tagsInput);
        if (Array.isArray(parsed)) return parsed.map(t => String(t).toLowerCase());
      } catch (_) {
        return tagsInput.split(',').map(t => t.trim().toLowerCase()).filter(Boolean);
      }
    }
    return [];
  }
}

module.exports = MatchmakerService;
