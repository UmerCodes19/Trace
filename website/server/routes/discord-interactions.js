const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const supabase = require('../utils/supabase');

const PUBLIC_KEY = process.env.DISCORD_PUBLIC_KEY;

// Premium Style System Colors (Jade Green Brand Theme)
const COLORS = {
  PRIMARY: 0x00A86B, // Jade Green (Brand Primary)
  RED: 0xE74C3C,     // Crimson Red (Lost Items & Errors)
  GREEN: 0x2ECC71,   // Sage/Emerald Green (Found Items & Confirmations)
  GOLD: 0xF1C40F,    // Gold (Leaderboards & Ranks)
  SLATE: 0x7F8C8D    // Slate Gray (Search Results & Detailed Cards)
};

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
        data: {
          embeds: [{
            color: COLORS.RED,
            title: '❌ Profile Retrieval Failed',
            description: 'Could not retrieve your Discord user profile from the interaction.'
          }]
        }
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

    // Command: /help
    if (name === 'help') {
      const avatarUrl = discordUser.avatar 
        ? `https://cdn.discordapp.com/avatars/${discordId}/${discordUser.avatar}.png`
        : `https://ui-avatars.com/api/?name=${encodeURIComponent(discordName)}&background=10B981&color=fff`;

      return res.json({
        type: 4,
        data: {
          embeds: [{
            color: COLORS.PRIMARY,
            title: '🟢 Trace Help Portal',
            description: 'Welcome to **Trace**, the premium university Lost & Found platform. Below is a structured guide to all active slash commands. Interacting with the campus property catalog is simple and automated!',
            fields: [
              { 
                name: '🔐 Account Identity', 
                value: '`/link <code>` - Link your Discord profile to your Trace mobile app.\n`/unlink` - Disconnect your Discord profile from Trace.'
              },
              { 
                name: '📋 Property Reporting', 
                value: '`/lost <item> <location> [description]` - Report property you have lost.\n`/found <item> <location> [description]` - Report property you have found.'
              },
              { 
                name: '🔍 Discovery & Search', 
                value: '`/search <query>` - Query reported items by keyword or location.\n`/recent [limit]` - List up to 10 recent items posted on campus.\n`/post <post_id>` - Look up the complete inspection card for any post.'
              },
              { 
                name: '📊 Community Stats & Reputation', 
                value: '`/leaderboard` - Honored list of top campus contributors.\n`/stats` - Overall campus safety and item return metrics.\n`/myitems` - Manage property that you reported.'
              },
              { 
                name: '🤝 Resolution & Claims', 
                value: '`/claim <post_id>` - Submit a claim request for a found item.\n`/resolve <post_id>` - Complete recovery of your reported item (+10 Karma).'
              }
            ],
            thumbnail: { url: avatarUrl },
            footer: { text: 'Trace Lost & Found • Active Campus Support' },
            timestamp: new Date().toISOString()
          }]
        }
      });
    }

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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Account Linking Failed',
                description: 'Invalid or expired code. Please generate a new code in the Trace app.',
                footer: { text: 'Trace Identity Error' }
              }]
            }
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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Database Error',
                description: `Database insertion failed: ${insError.message || JSON.stringify(insError)}`,
                footer: { text: 'Trace Identity Error' }
              }]
            }
          });
        }

        await supabase.from('cms_timetable').delete().eq('enrollment', `link_code:${code}`);

        const avatarUrl = discordUser.avatar 
          ? `https://cdn.discordapp.com/avatars/${discordId}/${discordUser.avatar}.png`
          : `https://ui-avatars.com/api/?name=${encodeURIComponent(discordName)}&background=10B981&color=fff`;

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.GREEN,
              title: '🔗 Account Linked Successfully!',
              description: `Welcome, **${discordName}**! Your Discord profile has been securely synchronized with your Trace account. You can now report and manage items directly from Discord.`,
              thumbnail: { url: avatarUrl },
              footer: { text: 'Trace Identity Manager' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Error While Linking',
              description: err.message || JSON.stringify(err),
              footer: { text: 'Trace Identity Error' }
            }]
          }
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
            embeds: [{
              color: COLORS.RED,
              title: '🔒 Authentication Required',
              description: `You must link your Discord account first to access this command.\n\n**Linking Process:**\n1️⃣ Open the **Trace Mobile App**.\n2️⃣ Navigate to **Settings** → **Link Discord Account**.\n3️⃣ Copy the 6-character code and run:\n\`/link code:YOUR_CODE\` here in Discord.`,
              footer: { text: 'Trace Security Verification' }
            }],
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
          data: {
            embeds: [{
              color: COLORS.GREEN,
              title: '🔗 Account Disconnected',
              description: 'Your Discord account has been disconnected from your Trace mobile account successfully.',
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Unlinking Failed',
              description: 'Failed to disconnect from your Trace account. Please try again later.',
              timestamp: new Date().toISOString()
            }]
          }
        });
      }
    }

    // Command: /lost and /found
    if (name === 'lost' || name === 'found') {
      const item = getOption('item');
      const loc = getOption('location');
      const desc = getOption('description') || `Reported via Discord by ${discordName}`;

      try {
        const isLost = name === 'lost';
        const { data: posts, error } = await supabase
          .from('posts')
          .insert([{
            id: crypto.randomUUID(),
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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Submission Failed',
                description: `Failed to submit your report: ${error?.message || JSON.stringify(error)}`
              }]
            }
          });
        }

        const post = posts[0];
        const avatarUrl = discordUser.avatar 
          ? `https://cdn.discordapp.com/avatars/${discordId}/${discordUser.avatar}.png`
          : `https://ui-avatars.com/api/?name=${encodeURIComponent(discordName)}&background=10B981&color=fff`;

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: isLost ? COLORS.RED : COLORS.GREEN,
              title: `${isLost ? '🔴' : '🟢'} New ${name.toUpperCase()} Item Reported`,
              description: `**${item}**`,
              fields: [
                { name: '📍 Location', value: loc, inline: true },
                { name: '👤 Reported By', value: discordName, inline: true },
                { name: '🏷️ Status', value: 'Open (Active)', inline: true },
                { name: '📝 Details', value: desc }
              ],
              thumbnail: { url: avatarUrl },
              footer: { text: `Post ID: ${post.id} • Trace Property Registry` },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Submission Error',
              description: `Error processing your post: ${err.message || JSON.stringify(err)}`
            }]
          }
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
            data: {
              embeds: [{
                color: COLORS.SLATE,
                title: '📭 Live Campus Board',
                description: 'No recent posts found on the Trace platform.',
                timestamp: new Date().toISOString()
              }]
            }
          });
        }

        let description = '';
        posts.forEach((p, idx) => {
          const emoji = p.type === 'lost' ? '🔴' : '🟢';
          description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
        });

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.PRIMARY,
              title: `📋 Recent Reports (${posts.length})`,
              description: description,
              footer: { text: 'Use /post <post_id> to inspect any item details.' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Loading Failed',
              description: `Failed to load recent posts: ${err.message || JSON.stringify(err)}`
            }]
          }
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
            data: {
              embeds: [{
                color: COLORS.SLATE,
                title: '📂 Personal Property Folder',
                description: 'You have not reported any items on Trace yet.'
              }],
              flags: 64
            }
          });
        }

        let description = '';
        posts.forEach((p, idx) => {
          const emoji = p.type === 'lost' ? '🔴' : '🟢';
          description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
        });

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.PRIMARY,
              title: `📂 Your Items (${posts.length})`,
              description: description,
              footer: { text: 'Manage these items in your Trace mobile application.' },
              timestamp: new Date().toISOString()
            }],
            flags: 64
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Retrieval Failed',
              description: `Failed to load items: ${err.message || JSON.stringify(err)}`,
              flags: 64
            }]
          }
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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Claim Request Failed',
                description: 'Post not found. Verify the ID and try again.'
              }]
            }
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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Claim Request Failed',
                description: `Failed to request claim: ${claimError.message || JSON.stringify(claimError)}`
              }]
            }
          });
        }

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.GREEN,
              title: '✅ Claim Request Submitted!',
              description: `Your claim request for **${post.title || 'the item'}** has been successfully registered. The owner of the post has been notified of your contact request.`,
              fields: [
                { name: '👤 Claimer', value: discordName, inline: true },
                { name: '🏷️ Status', value: 'Pending Owner Review', inline: true }
              ],
              footer: { text: 'Trace Claims & Verifications' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Claim Request Error',
              description: `Error submitting claim: ${err.message || JSON.stringify(err)}`
            }]
          }
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
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Resolution Failed',
                description: 'Failed to mark post as resolved. Ensure you are the author and that the ID is correct.'
              }]
            }
          });
        }

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.GREEN,
              title: '🎉 Item Successfully Recovered!',
              description: 'Fantastic! The item has been marked as **Resolved & Returned** on the Trace network. Good karma is heading your way! (+10 Karma Points)',
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Error Resolving Post',
              description: `Error resolving post: ${err.message || JSON.stringify(err)}`
            }]
          }
        });
      }
    }

    // Command: /leaderboard
    if (name === 'leaderboard') {
      try {
        const { data: topUsers, error } = await supabase
          .from('users')
          .select('name, karmaPoints, itemsReturned')
          .order('karmaPoints', { ascending: false })
          .limit(10);

        if (error) throw error;

        if (!topUsers || topUsers.length === 0) {
          return res.json({
            type: 4,
            data: {
              embeds: [{
                color: COLORS.GOLD,
                title: '🏆 Trace Community Leaderboard',
                description: 'The podium is currently empty! Get active on campus to earn karma and claim the top rank.',
                timestamp: new Date().toISOString()
              }]
            }
          });
        }

        let description = 'Honoring our top helpful university members who are active in restoring lost property and spreading positive karma on campus!\n\n';
        topUsers.forEach((u, idx) => {
          const medal = idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `\`#${idx + 1}\``;
          description += `${medal} **${u.name || 'Anonymous User'}**\n✨ Karma: \`${u.karmaPoints || 0}\` • 🤝 Returned: \`${u.itemsReturned || 0}\` items\n\n`;
        });

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.GOLD,
              title: '🏆 Trace Community Leaderboard',
              description: description,
              footer: { text: 'Earn Karma by posting found items and returning them to their rightful owners.' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Leaderboard Unavailable',
              description: 'Failed to retrieve the leaderboard. Please try again later.'
            }]
          }
        });
      }
    }

    // Command: /stats
    if (name === 'stats') {
      try {
        const { data: allPosts, error } = await supabase
          .from('posts')
          .select('*');

        if (error) throw error;

        const totalCount = allPosts.length;
        const resolvedCount = allPosts.filter(p => p.status === 'resolved').length;
        const lostCount = allPosts.filter(p => p.type === 'lost').length;
        const foundCount = allPosts.filter(p => p.type === 'found').length;
        const recoveryRate = totalCount > 0 ? ((resolvedCount / totalCount) * 100).toFixed(1) : '0.0';

        let activeUsers = 'N/A';
        try {
          const { data: usersData } = await supabase
            .from('users')
            .select('uid');
          if (usersData) activeUsers = usersData.length.toString();
        } catch (err) {}

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.PRIMARY,
              title: '📈 Trace Platform Impact Metrics',
              description: 'Providing full transparency into our university network efficiency. Here is how our campus stands:',
              fields: [
                { name: '📊 Total Reports', value: `\`${totalCount}\` items`, inline: true },
                { name: '✅ Resolved Property', value: `\`${resolvedCount}\` items`, inline: true },
                { name: '📈 Recovery Rate', value: `\`${recoveryRate}%\``, inline: true },
                { name: '🔴 Lost Reports', value: `\`${lostCount}\``, inline: true },
                { name: '🟢 Found Reports', value: `\`${foundCount}\``, inline: true },
                { name: '👥 Active Members', value: `\`${activeUsers}\``, inline: true }
              ],
              footer: { text: 'Making our university a safer, more connected place.' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Statistics Unavailable',
              description: 'Failed to compile campus statistics. Please try again later.'
            }]
          }
        });
      }
    }

    // Command: /search
    if (name === 'search') {
      try {
        const query = getOption('query');
        const { data: allPosts, error } = await supabase
          .from('posts')
          .select('*');

        if (error) throw error;

        const cleanQuery = query.toLowerCase();
        const matches = allPosts.filter(p => 
          p.title?.toLowerCase().includes(cleanQuery) || 
          p.location_name?.toLowerCase().includes(cleanQuery) || 
          p.description?.toLowerCase().includes(cleanQuery)
        ).slice(0, 8);

        if (matches.length === 0) {
          return res.json({
            type: 4,
            data: {
              embeds: [{
                color: COLORS.SLATE,
                title: '🔍 Search Dashboard',
                description: `No items found matching the search criteria: **"${query}"**.\nTry using different keywords or checking spelling.`,
                timestamp: new Date().toISOString()
              }]
            }
          });
        }

        let description = `Showing the top matching items for **"${query}"**:\n\n`;
        matches.forEach((p, idx) => {
          const emoji = p.type === 'lost' ? '🔴' : '🟢';
          description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 Location: *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
        });

        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.SLATE,
              title: '🔍 Trace Property Catalog Search',
              description: description,
              footer: { text: 'Use /post <post_id> to inspect any item details.' },
              timestamp: new Date().toISOString()
            }]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Search Interrupted',
              description: 'Failed to perform the catalog search. Please try again in a few minutes.'
            }]
          }
        });
      }
    }

    // Command: /post
    if (name === 'post') {
      try {
        const postId = getOption('post_id');
        const { data: p, error } = await supabase
          .from('posts')
          .select('*')
          .eq('id', postId)
          .single();

        if (error || !p) {
          return res.json({
            type: 4,
            data: {
              embeds: [{
                color: COLORS.RED,
                title: '❌ Item Lookup Failed',
                description: 'Could not locate a post with the provided ID. Please double-check the ID spelling and try again.',
                timestamp: new Date().toISOString()
              }]
            }
          });
        }

        const isLost = p.type === 'lost';
        const embed = {
          color: isLost ? COLORS.RED : COLORS.GREEN,
          title: `${isLost ? '🔴' : '🟢'} ${p.type.toUpperCase()}: ${p.title}`,
          description: p.description || 'No additional description provided.',
          fields: [
            { name: '📍 Location', value: p.location_name || p.buildingName || 'Campus Ground', inline: true },
            { name: '🏢 Building Structure', value: `${p.buildingName || 'General Area'} (Floor ${p.floor || 0})`, inline: true },
            { name: '🏷️ Catalog Status', value: `\`${p.status.toUpperCase()}\``, inline: true },
            { name: '👤 Reported By', value: p.posterName || 'Trace Member', inline: true },
            { name: '📅 Date Logged', value: new Date(p.timestamp).toLocaleDateString(), inline: true },
            { name: '❤️ Likes & Views', value: `❤️ ${p.likeCount || 0} Likes • 👁️ ${p.viewCount || 0} Views`, inline: true }
          ],
          footer: { text: `Post ID: ${p.id} • Trace Security & Logistics` },
          timestamp: new Date().toISOString()
        };

        if (p.posterAvatarUrl) {
          embed.thumbnail = { url: p.posterAvatarUrl };
        }

        return res.json({
          type: 4,
          data: {
            embeds: [embed]
          }
        });
      } catch (err) {
        return res.json({
          type: 4,
          data: {
            embeds: [{
              color: COLORS.RED,
              title: '❌ Item Lookup Error',
              description: 'An unexpected error occurred while looking up this item. Please try again later.'
            }]
          }
        });
      }
    }
  }

  res.status(400).send('Unsupported interaction type');
});

module.exports = router;
