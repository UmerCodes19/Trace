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
      const { data } = await supabase
        .from('cms_timetable')
        .select('*')
        .eq('enrollment', `discord:${discordId}`)
        .single();
      return data ? data.courseCode : null;
    };

    // Command: /link
    if (name === 'link') {
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

      await supabase.from('cms_timetable').insert([entry]);
      await supabase.from('cms_timetable').delete().eq('enrollment', `link_code:${code}`);

      return res.json({
        type: 4,
        data: { content: `✅ Successfully linked your Discord to Trace account: **${discordName}**!` }
      });
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
      await supabase
        .from('cms_timetable')
        .delete()
        .eq('enrollment', `discord:${discordId}`);
      return res.json({
        type: 4,
        data: { content: `✅ Disconnected from your Trace account successfully.` }
      });
    }

    // Command: /lost and /found
    if (name === 'lost' || name === 'found') {
      const item = getOption('item');
      const loc = getOption('location');
      const desc = getOption('description') || `Reported via Discord by ${discordName}`;

      const { data: post, error } = await supabase
        .from('posts')
        .insert({
          userId,
          type: name,
          title: item,
          description: desc,
          location_name: loc,
          buildingName: loc,
          floor: 0,
          status: 'open',
          timestamp: new Date().toISOString()
        })
        .select()
        .single();

      if (error) {
        return res.json({
          type: 4,
          data: { content: `❌ Failed to submit your report. Please try again later.` }
        });
      }

      const emoji = name === 'lost' ? '🔴' : '🟢';
      return res.json({
        type: 4,
        data: {
          content: `### ${emoji} ${name.toUpperCase()} Item Reported\n**Item:** ${item}\n**Location:** ${loc}\n**Posted by:** ${discordName}\n**Status:** Looking for item\n**Post ID:** \`${post.id}\``
        }
      });
    }

    // Command: /recent
    if (name === 'recent') {
      const limit = getOption('limit') || 5;
      const { data: posts } = await supabase
        .from('posts')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(Math.min(limit, 10));

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
    }

    // Command: /myitems
    if (name === 'myitems') {
      const { data: posts } = await supabase
        .from('posts')
        .select('*')
        .eq('userId', userId);

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
    }

    // Command: /claim
    if (name === 'claim') {
      const postId = getOption('post_id');
      const { data: post } = await supabase
        .from('posts')
        .select('*')
        .eq('id', postId)
        .single();

      if (!post) {
        return res.json({
          type: 4,
          data: { content: '❌ Post not found. Verify the ID and try again.' }
        });
      }

      await supabase.from('claims').insert({
        post_id: postId,
        claimer_id: userId,
        proof_text: `Claimed via Discord by ${discordName}`,
        proof_image_url: '',
        status: 'pending'
      });

      return res.json({
        type: 4,
        data: { content: `✅ Claim request submitted successfully for item **${post.title}**. The owner has been notified!` }
      });
    }

    // Command: /resolve
    if (name === 'resolve') {
      const postId = getOption('post_id');
      const { error } = await supabase
        .from('posts')
        .update({ status: 'resolved' })
        .eq('id', postId)
        .eq('userId', userId);

      if (error) {
        return res.json({
          type: 4,
          data: { content: '❌ Failed to mark post as resolved. Ensure you are the author.' }
        });
      }

      return res.json({
        type: 4,
        data: { content: '✅ Item marked as resolved successfully!' }
      });
    }
  }

  res.status(400).send('Unsupported interaction type');
});

module.exports = router;
