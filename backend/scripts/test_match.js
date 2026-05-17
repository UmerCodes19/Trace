const AIService = require('../services/ai_service');
const supabase = require('../utils/supabase');

async function testMatch(postId) {
  console.log(`--- Starting AI Match Test for Post ID: ${postId} ---`);

  // 1. Fetch the target post
  const { data: newPost, error: postErr } = await supabase
    .from('posts')
    .select('*')
    .eq('id', postId)
    .single();

  if (postErr || !newPost) {
    console.error('Error fetching target post:', postErr?.message || 'Post not found');
    process.exit(1);
  }

  console.log(`Target Post: "${newPost.title}" (${newPost.type})`);

  // 2. Fetch potential candidates of opposite type
  const oppositeType = newPost.type === 'lost' ? 'found' : 'lost';
  const { data: candidates, error: candErr } = await supabase
    .from('posts')
    .select('*')
    .eq('type', oppositeType)
    .neq('status', 'resolved')
    .limit(5);

  if (candErr) {
    console.error('Error fetching candidates:', candErr.message);
    process.exit(1);
  }

  if (candidates.length === 0) {
    console.log('No potential candidates found in the database.');
    return;
  }

  console.log(`Found ${candidates.length} potential candidates. Sending to Gemini...`);

  // 3. Run AI Match
  const results = await AIService.comparePosts(newPost, candidates);

  // 4. Print Results
  console.log('\n--- AI Matching Results ---');
  if (results.length === 0) {
    console.log('No results returned from AI.');
  } else {
    results.forEach((res, i) => {
      const cand = candidates.find(c => c.id === res.candidateId);
      console.log(`\nCandidate ${i + 1}: "${cand ? cand.title : 'Unknown'}"`);
      console.log(`Match Score: ${res.score}%`);
      console.log(`Reasoning: ${res.reason}`);
    });
  }
  console.log('\n--- Test Complete ---');
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.log('Usage: node test_match.js <POST_ID>');
  process.exit(1);
}

testMatch(args[0]);
