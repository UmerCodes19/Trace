const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const supabase = require('../utils/supabase');

const PUBLIC_KEY = process.env.DISCORD_PUBLIC_KEY;

// Verify Discord Request Signature middleware
function verifyDiscordRequest(req, res, next) {
  const signature = req.get('X-Signature-Ed25519');
  const timestamp = req.get('X-Signature-Timestamp');
  
  // Use rawBody if available, or reconstruct from JSON stringify
  const body = req.rawBody || JSON.stringify(req.body);

  if (!signature || !timestamp || !body) {
    return res.status(401).send('Missing headers');
  }

  if (!PUBLIC_KEY) {
    console.error('DISCORD_PUBLIC_KEY is not configured in environment variables');
    return res.status(500).send('Discord Public Key not configured');
  }

  try {
    const isVerified = crypto.verify(
      null,
      Buffer.from(timestamp + body),
      `-----BEGIN PUBLIC KEY-----\n${Buffer.from(
        "302a300506032b6570032100" + PUBLIC_KEY,
        "hex"
      ).toString("base64")}\n-----END PUBLIC KEY-----`,
      Buffer.from(signature, 'hex')
    );

    if (!isVerified) {
      return res.status(401).send('Invalid request signature');
    }
  } catch (error) {
    return res.status(401).send('Signature verification failed');
  }

  next();
}

router.get('/', (req, res) => {
  res.send('Discord Interactions endpoint is active and ready for POST requests.');
});

router.post('/', verifyDiscordRequest, async (req, res) => {
  const interaction = req.body;
  if (!interaction) return res.status(400).send('Empty body');

  // 1. Respond to ping/verification requests from Discord
  if (interaction.type === 1) {
    return res.json({ type: 1 });
  }

  // 2. Respond to slash command interactions
  if (interaction.type === 2) {
    const { name, options } = interaction.data;
    const discordUser = interaction.user || interaction.member?.user;
    if (!discordUser) {
      return res.json({
        type: 4,
        data: { content: '❌ Could not retrieve your Discord user profile.' }
      });
    }

    const discordId = discordUser.id;
    const discordName = discordUser.username;

    const getOption = (optName) => {
      const opt = options?.find(o => o.name === optName);
      return opt ? opt.value : null;
    };

    const checkLink = async () => {
      try {
        const { data, error } = await supabase
          .from('cms_timetable')
          .select('*')
          .eq('enrollment', `discord:${discordId}`)
          .single();
        if (error || !data) return null;
        return data.courseCode;
      } catch (e) {
        return null;
      }
    };

    // Command: /link
    if (name === 'link') {
      try {
        const code = getOption('code').toUpperCase();

        const { data: codeData, error: linkError } = await supabase
          .from('cms_timetable')
          .select('*')
          .eq('enrollment', `link_code:${code}`)
          .single();

        if (linkError || !codeData) {
          return res.json({
            type: 4,
            data: { content: '❌ Invalid or expired code. Please generate a new code in the Trace app.' }
          });
        }

        const entry = {
          enrollment: `discord:${discordId}`,
          courseCode: codeData.courseCode,
          courseTitle: discordName,
          roomName: discordId,
          buildingName: '#discord_link',
          day: 1
        };

        await supabase
          .from('cms_timetable')
          .delete()
          .eq('enrollment', `discord:${discordId}`);

        const { error: insError } = await supabase.from('cms_timetable').insert([entry]);
        if (insError) {
          return res.json({
            type: 4,
            data: { content: `❌ Database insertion failed: ${insError.message || JSON.stringify(insError)}` }
          });
        }

        await supabase.from('cms_timetable').delete().eq('enrollment', `link_code:${code}`);

        return res.json({
          type: 4,
          data: { content: `✅ Successfully linked your Discord to Trace account: **${discordName}**!` }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Error while linking: ${err.message || JSON.stringify(err)}` }
        });
      }
    }

    let userId = null;
    if (['unlink', 'lost', 'found', 'myitems', 'claim', 'resolve'].includes(name)) {
      userId = await checkLink();
      if (!userId) {
        return res.json({
          type: 4,
          data: {
            content: `❌ Link your Discord first: Open the Trace app → Settings → Link Discord Account`,
            flags: 64
          }
        });
      }
    }

    // Command: /unlink
    if (name === 'unlink') {
      try {
        const { error } = await supabase
          .from('cms_timetable')
          .delete()
          .eq('enrollment', `discord:${discordId}`);
        if (error) throw error;
        return res.json({
          type: 4,
          data: { content: `✅ Disconnected from your Trace account successfully.` }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Failed to unlink: ${err.message || JSON.stringify(err)}` }
        });
      }
    }

    // Command: /lost and /found
    if (name === 'lost' || name === 'found') {
      const item = getOption('item');
      const loc = getOption('location');
      const desc = getOption('description') || `Reported via Discord by ${discordName}`;

      try {
        // Auto-fill poster name/avatar if possible
        let posterName = discordName;
        let posterAvatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(discordName)}&background=1B3C53&color=fff`;

        const { data: user } = await supabase
          .from('users')
          .select('name, photoURL')
          .eq('uid', userId)
          .single();
        
        if (user) {
          posterName = user.name || posterName;
          posterAvatarUrl = user.photoURL || posterAvatarUrl;
        }

        const { data: posts, error } = await supabase
          .from('posts')
          .insert([{
            userId,
            type: name,
            title: item,
            description: desc,
            location_name: loc,
            buildingName: loc,
            floor: 0,
            status: 'open',
            timestamp: new Date().toISOString()
          }])
          .select();

        if (error || !posts || posts.length === 0) {
          return res.json({
            type: 4,
            data: { content: `❌ Failed to submit your report: ${error?.message || JSON.stringify(error)}` }
          });
        }

        const post = posts[0];
        const emoji = name === 'lost' ? '🔴' : '🟢';
        return res.json({
          type: 4,
          data: {
            content: `### ${emoji} ${name.toUpperCase()} Item Reported\n**Item:** ${item}\n**Location:** ${loc}\n**Posted by:** ${discordName}\n**Status:** Looking for item\n**Post ID:** \`${post.id}\``
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Error processing your post: ${err.message || JSON.stringify(err)}` }
        });
      }
    }

    // Command: /recent
    if (name === 'recent') {
      try {
        const limit = getOption('limit') || 5;
        const { data: posts, error } = await supabase
          .from('posts')
          .select('*')
          .order('timestamp', { ascending: false })
          .limit(Math.min(limit, 10));

        if (error) throw error;

        if (!posts || posts.length === 0) {
          return res.json({
            type: 4,
            data: { content: '📭 No recent posts found on Trace.' }
          });
        }

        let reply = `### 📋 Recent Posts (${posts.length})\n`;
        posts.forEach((p, idx) => {
          const emoji = p.type === 'lost' ? '🔴' : '🟢';
          reply += `${idx + 1}. ${emoji} **${p.title}** - \`${p.status.toUpperCase()}\` at *${p.location_name}*\n> *Post ID:* \`${p.id}\`\n`;
        });

        return res.json({
          type: 4,
          data: { content: reply }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Failed to load recent posts: ${err.message || JSON.stringify(err)}` }
        });
      }
    }

    // Command: /myitems
    if (name === 'myitems') {
      try {
        const { data: posts, error } = await supabase
          .from('posts')
          .select('*')
          .eq('userId', userId);

        if (error) throw error;

        if (!posts || posts.length === 0) {
          return res.json({
            type: 4,
            data: { content: '📭 You haven\'t reported any items yet.', flags: 64 }
          });
        }

        let reply = `### 📂 Your Items (${posts.length})\n`;
        posts.forEach((p, idx) => {
          const emoji = p.type === 'lost' ? '🔴' : '🟢';
          reply += `${idx + 1}. ${emoji} **${p.title}** - \`${p.status.toUpperCase()}\` at *${p.location_name}*\n> *Post ID:* \`${p.id}\`\n`;
        });

        return res.json({
          type: 4,
          data: { content: reply, flags: 64 }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Failed to load items: ${err.message || JSON.stringify(err)}`, flags: 64 }
        });
      }
    }

    // Command: /claim
    if (name === 'claim') {
      try {
        const postId = getOption('post_id');
        const { data: post, error: fetchError } = await supabase
          .from('posts')
          .select('*')
          .eq('id', postId)
          .single();

        if (fetchError || !post) {
          return res.json({
            type: 4,
            data: { content: '❌ Post not found. Verify the ID and try again.' }
          });
        }

        const { error: claimError } = await supabase.from('claims').insert([{
          post_id: postId,
          claimer_id: userId,
          proof_text: `Claimed via Discord by ${discordName}`,
          proof_image_url: '',
          status: 'pending'
        }]);

        if (claimError) {
          return res.json({
            type: 4,
            data: { content: `❌ Failed to request claim: ${claimError.message || JSON.stringify(claimError)}` }
          });
        }

        return res.json({
          type: 4,
          data: { content: `✅ Claim request submitted successfully for item **${post.title}**. The owner has been notified!` }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Error submitting claim: ${err.message || JSON.stringify(err)}` }
        });
      }
    }

    // Command: /resolve
    if (name === 'resolve') {
      try {
        const postId = getOption('post_id');
        const { data, error } = await supabase
          .from('posts')
          .update({ status: 'resolved' })
          .eq('id', postId)
          .eq('userId', userId)
          .select();

        if (error || !data || data.length === 0) {
          return res.json({
            type: 4,
            data: { content: '❌ Failed to mark post as resolved. Ensure you are the author and that the ID is correct.' }
          });
        }

        return res.json({
          type: 4,
          data: { content: '✅ Item marked as resolved successfully!' }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: { content: `❌ Error resolving post: ${err.message || JSON.stringify(err)}` }
        });
      }
    }
  }

  res.status(400).send('Unsupported interaction type');
});

module.exports = router;
