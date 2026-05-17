const { Client, GatewayIntentBits, REST, Routes, SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const axios = require('axios');

// Configure Bot
const TOKEN = process.env.DISCORD_BOT_TOKEN;
const CLIENT_ID = process.env.DISCORD_CLIENT_ID;
const API_URL = process.env.TRACE_API_URL || 'https://trace-self.vercel.app/api';

if (!TOKEN || !CLIENT_ID) {
  console.error('⚠️ Missing environment variables: DISCORD_BOT_TOKEN and DISCORD_CLIENT_ID are required.');
}

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages]
});

// Premium Style System Colors (Jade Green Brand Theme)
const COLORS = {
  PRIMARY: 0x00A86B, // Jade Green (Brand Primary)
  RED: 0xE74C3C,     // Crimson Red (Lost Items & Errors)
  GREEN: 0x2ECC71,   // Sage/Emerald Green (Found Items & Confirmations)
  GOLD: 0xF1C40F,    // Gold (Leaderboards & Ranks)
  SLATE: 0x7F8C8D    // Slate Gray (Search Results & Detailed Cards)
};

// Slash Commands Definition
const commands = [
  new SlashCommandBuilder()
    .setName('help')
    .setDescription('View the interactive guide and list of available commands'),

  new SlashCommandBuilder()
    .setName('link')
    .setDescription('Link your Discord account to your Trace account')
    .addStringOption(option => option.setName('code').setDescription('The 6-character linking code from the Trace app').setRequired(true)),
  
  new SlashCommandBuilder()
    .setName('unlink')
    .setDescription('Unlink your Discord from your Trace account'),

  new SlashCommandBuilder()
    .setName('lost')
    .setDescription('Report a lost item')
    .addStringOption(option => option.setName('item').setDescription('Name or type of the lost item').setRequired(true))
    .addStringOption(option => option.setName('location').setDescription('Location where the item was lost').setRequired(true))
    .addStringOption(option => option.setName('description').setDescription('Optional item description or details')),

  new SlashCommandBuilder()
    .setName('found')
    .setDescription('Report a found item')
    .addStringOption(option => option.setName('item').setDescription('Name or type of the found item').setRequired(true))
    .addStringOption(option => option.setName('location').setDescription('Location where the item was found').setRequired(true))
    .addStringOption(option => option.setName('description').setDescription('Optional item description or details')),

  new SlashCommandBuilder()
    .setName('recent')
    .setDescription('View recent posts from Trace')
    .addIntegerOption(option => option.setName('limit').setDescription('Number of recent posts to retrieve (max 10)')),

  new SlashCommandBuilder()
    .setName('myitems')
    .setDescription('View all lost & found items you have reported'),

  new SlashCommandBuilder()
    .setName('claim')
    .setDescription('Claim an item from the lost/found posts')
    .addStringOption(option => option.setName('post_id').setDescription('The ID of the post you want to claim').setRequired(true)),

  new SlashCommandBuilder()
    .setName('resolve')
    .setDescription('Mark your own item/post as resolved')
    .addStringOption(option => option.setName('post_id').setDescription('The ID of the post to resolve').setRequired(true)),

  new SlashCommandBuilder()
    .setName('leaderboard')
    .setDescription('View top helpful community members on campus'),

  new SlashCommandBuilder()
    .setName('stats')
    .setDescription('View Trace community statistics & impact metrics'),

  new SlashCommandBuilder()
    .setName('search')
    .setDescription('Search reported lost & found items')
    .addStringOption(option => option.setName('query').setDescription('The keyword or location to search for').setRequired(true)),

  new SlashCommandBuilder()
    .setName('post')
    .setDescription('Inspect a specific post card by its ID')
    .addStringOption(option => option.setName('post_id').setDescription('The ID of the post to lookup').setRequired(true)),
].map(command => command.toJSON());

// Register Slash Commands
const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
  try {
    console.log('🔄 Started refreshing application (/) commands...');
    await rest.put(
      Routes.applicationCommands(CLIENT_ID),
      { body: commands },
    );
    console.log('✅ Successfully reloaded application (/) commands.');
  } catch (error) {
    console.error('❌ Failed to refresh application commands:', error);
  }
})();

// Helper function to check if the user is linked
async function checkLink(discordId) {
  try {
    const res = await axios.get(`${API_URL}/discord/user/${discordId}`);
    return res.data.user_id;
  } catch (error) {
    return null;
  }
}

// Bot ready event
client.once('ready', () => {
  console.log(`✅ Trace Bot is ready and logged in as ${client.user.tag}`);
});

// Handling commands
client.on('interactionCreate', async interaction => {
  if (!interaction.isChatInputCommand()) return;

  const { commandName, user } = interaction;

  // Command: /help
  if (commandName === 'help') {
    await interaction.deferReply();
    const helpEmbed = new EmbedBuilder()
      .setColor(COLORS.PRIMARY)
      .setTitle('🟢 Trace Help Portal')
      .setDescription('Welcome to **Trace**, the premium university Lost & Found platform. Below is a structured guide to all active slash commands. Interacting with the campus property catalog is simple and automated!')
      .addFields(
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
      )
      .setThumbnail(client.user.displayAvatarURL() || null)
      .setFooter({ text: 'Trace Lost & Found • Active Campus Support', iconURL: client.user.displayAvatarURL() })
      .setTimestamp();

    await interaction.editReply({ embeds: [helpEmbed] });
    return;
  }

  // Handle command: /link
  if (commandName === 'link') {
    const code = interaction.options.getString('code').toUpperCase();
    try {
      await interaction.deferReply({ ephemeral: true });
      const res = await axios.post(`${API_URL}/discord/verify`, {
        code,
        discord_id: user.id,
        discord_name: user.username
      });

      const linkEmbed = new EmbedBuilder()
        .setColor(COLORS.GREEN)
        .setTitle('🔗 Account Linked Successfully!')
        .setDescription(`Welcome, **${user.username}**! Your Discord profile has been securely synchronized with your Trace account. You can now report and manage items directly from Discord.`)
        .setThumbnail(user.displayAvatarURL())
        .setFooter({ text: 'Trace Identity Manager' })
        .setTimestamp();

      await interaction.editReply({ embeds: [linkEmbed] });
    } catch (err) {
      const msg = err.response?.data?.error || 'Trace service is temporarily unavailable. Try again in a few minutes.';
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Account Linking Failed')
        .setDescription(msg)
        .setFooter({ text: 'Trace Identity Error' });

      await interaction.editReply({ embeds: [errEmbed] });
    }
    return;
  }

  // Check link status for other commands
  let userId = null;
  if (['unlink', 'lost', 'found', 'myitems', 'claim', 'resolve'].includes(commandName)) {
    userId = await checkLink(user.id);
    if (!userId) {
      const authEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('🔒 Authentication Required')
        .setDescription(`You must link your Discord account first to access this command.\n\n**Linking Process:**\n1️⃣ Open the **Trace Mobile App**.\n2️⃣ Navigate to **Settings** → **Link Discord Account**.\n3️⃣ Copy the 6-character code and run:\n\`/link code:YOUR_CODE\` here in Discord.`)
        .setFooter({ text: 'Trace Security Verification' });

      await interaction.reply({ embeds: [authEmbed], ephemeral: true });
      return;
    }
  }

  // Handle /unlink
  if (commandName === 'unlink') {
    try {
      await interaction.deferReply({ ephemeral: true });
      await axios.post(`${API_URL}/discord/unlink`, { discord_id: user.id });

      const unlinkEmbed = new EmbedBuilder()
        .setColor(COLORS.GREEN)
        .setTitle('🔗 Account Disconnected')
        .setDescription('Your Discord account has been disconnected from your Trace mobile account successfully.')
        .setTimestamp();

      await interaction.editReply({ embeds: [unlinkEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Unlinking Failed')
        .setDescription('Failed to disconnect from your Trace account. Please try again later.')
        .setTimestamp();

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /lost and /found
  else if (commandName === 'lost' || commandName === 'found') {
    const item = interaction.options.getString('item');
    const loc = interaction.options.getString('location');
    const desc = interaction.options.getString('description') || `Reported via Discord by ${user.username}`;

    try {
      await interaction.deferReply();
      const isLost = commandName === 'lost';
      
      const res = await axios.post(`${API_URL}/posts`, {
        userId,
        type: commandName,
        title: item,
        description: desc,
        location: {
          name: loc,
          building: loc,
          floor: 0
        },
        status: 'open',
        timestamp: new Date().toISOString()
      });

      const reportEmbed = new EmbedBuilder()
        .setColor(isLost ? COLORS.RED : COLORS.GREEN)
        .setTitle(`${isLost ? '🔴' : '🟢'} New ${commandName.toUpperCase()} Item Reported`)
        .setDescription(`**${item}**`)
        .addFields(
          { name: '📍 Location', value: loc, inline: true },
          { name: '👤 Reported By', value: user.username, inline: true },
          { name: '🏷️ Status', value: 'Open (Active)', inline: true },
          { name: '📝 Details', value: desc }
        )
        .setThumbnail(user.displayAvatarURL())
        .setFooter({ text: `Post ID: ${res.data.id} • Trace Property Registry` })
        .setTimestamp();

      await interaction.editReply({ embeds: [reportEmbed] });
    } catch (err) {
      console.error(err);
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Submission Failed')
        .setDescription('Failed to submit your post. The Trace API service is temporarily unavailable.')
        .setTimestamp();

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /recent
  else if (commandName === 'recent') {
    const limit = interaction.options.getInteger('limit') || 5;
    try {
      await interaction.deferReply();
      const res = await axios.get(`${API_URL}/posts`);
      const items = res.data.slice(0, Math.min(limit, 10));

      if (items.length === 0) {
        const emptyEmbed = new EmbedBuilder()
          .setColor(COLORS.SLATE)
          .setTitle('📭 Live Campus Board')
          .setDescription('No recent posts found on the Trace platform.')
          .setTimestamp();

        await interaction.editReply({ embeds: [emptyEmbed] });
        return;
      }

      let description = '';
      items.forEach((p, idx) => {
        const emoji = p.type === 'lost' ? '🔴' : '🟢';
        description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
      });

      const recentEmbed = new EmbedBuilder()
        .setColor(COLORS.PRIMARY)
        .setTitle(`📋 Recent Reports (${items.length})`)
        .setDescription(description)
        .setFooter({ text: 'Use /post <post_id> to inspect any item details.' })
        .setTimestamp();

      await interaction.editReply({ embeds: [recentEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Loading Failed')
        .setDescription('Failed to load recent posts. Please try again in a few minutes.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /myitems
  else if (commandName === 'myitems') {
    try {
      await interaction.deferReply({ ephemeral: true });
      const res = await axios.get(`${API_URL}/posts`);
      const items = res.data.filter(p => p.userId === userId);

      if (items.length === 0) {
        const emptyEmbed = new EmbedBuilder()
          .setColor(COLORS.SLATE)
          .setTitle('📂 Personal Property Folder')
          .setDescription('You have not reported any items on Trace yet.');

        await interaction.editReply({ embeds: [emptyEmbed] });
        return;
      }

      let description = '';
      items.forEach((p, idx) => {
        const emoji = p.type === 'lost' ? '🔴' : '🟢';
        description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
      });

      const myItemsEmbed = new EmbedBuilder()
        .setColor(COLORS.PRIMARY)
        .setTitle(`📂 Your Items (${items.length})`)
        .setDescription(description)
        .setFooter({ text: 'Manage these items in your Trace mobile application.' })
        .setTimestamp();

      await interaction.editReply({ embeds: [myItemsEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Retrieval Failed')
        .setDescription('Failed to retrieve your reported items.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /claim
  else if (commandName === 'claim') {
    const postId = interaction.options.getString('post_id');
    try {
      await interaction.deferReply();
      const postRes = await axios.get(`${API_URL}/posts/${postId}`);
      const post = postRes.data;

      await axios.post(`${API_URL}/claims/request`, {
        postId,
        proofText: `Claimed via Discord by ${user.username}`,
        proofImageUrl: ''
      }, {
        headers: {
          'Authorization': `Bearer ${userId}`
        }
      });

      const claimEmbed = new EmbedBuilder()
        .setColor(COLORS.GREEN)
        .setTitle('✅ Claim Request Submitted!')
        .setDescription(`Your claim request for **${post.title || 'the item'}** has been successfully registered. The owner of the post has been notified of your contact request.`)
        .addFields(
          { name: '👤 Claimer', value: user.username, inline: true },
          { name: '🏷️ Status', value: 'Pending Owner Review', inline: true }
        )
        .setFooter({ text: 'Trace Claims & Verifications' })
        .setTimestamp();

      await interaction.editReply({ embeds: [claimEmbed] });
    } catch (err) {
      const msg = err.response?.data?.error || 'Trace service is temporarily unavailable. Try again in a few minutes.';
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Claim Request Failed')
        .setDescription(msg);

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /resolve
  else if (commandName === 'resolve') {
    const postId = interaction.options.getString('post_id');
    try {
      await interaction.deferReply();
      await axios.put(`${API_URL}/posts/${postId}`, {
        status: 'resolved'
      }, {
        headers: {
          'Authorization': `Bearer ${userId}`
        }
      });

      const resolveEmbed = new EmbedBuilder()
        .setColor(COLORS.GREEN)
        .setTitle('🎉 Item Successfully Recovered!')
        .setDescription('Fantastic! The item has been marked as **Resolved & Returned** on the Trace network. Good karma is heading your way! (+10 Karma Points)')
        .setTimestamp();

      await interaction.editReply({ embeds: [resolveEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Resolution Failed')
        .setDescription('Failed to mark post as resolved. Ensure you are the original author of the post and that the ID is valid.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /leaderboard
  else if (commandName === 'leaderboard') {
    try {
      await interaction.deferReply();
      const res = await axios.get(`${API_URL}/users/leaderboard`);
      const topUsers = res.data.slice(0, 10);

      if (topUsers.length === 0) {
        const emptyEmbed = new EmbedBuilder()
          .setColor(COLORS.GOLD)
          .setTitle('🏆 Trace Community Leaderboard')
          .setDescription('The podium is currently empty! Get active on campus to earn karma and claim the top rank.')
          .setTimestamp();

        await interaction.editReply({ embeds: [emptyEmbed] });
        return;
      }

      let description = 'Honoring our top helpful university members who are active in restoring lost property and spreading positive karma on campus!\n\n';
      topUsers.forEach((u, idx) => {
        const medal = idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `\`#${idx + 1}\``;
        description += `${medal} **${u.name || 'Anonymous User'}**\n✨ Karma: \`${u.karmaPoints || 0}\` • 🤝 Returned: \`${u.itemsReturned || 0}\` items\n\n`;
      });

      const leaderboardEmbed = new EmbedBuilder()
        .setColor(COLORS.GOLD)
        .setTitle('🏆 Trace Community Leaderboard')
        .setDescription(description)
        .setFooter({ text: 'Earn Karma by posting found items and returning them to their rightful owners.' })
        .setTimestamp();

      await interaction.editReply({ embeds: [leaderboardEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Leaderboard Unavailable')
        .setDescription('Failed to retrieve the leaderboard. Please try again later.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /stats
  else if (commandName === 'stats') {
    try {
      await interaction.deferReply();
      
      const postsRes = await axios.get(`${API_URL}/posts`);
      const allPosts = postsRes.data;
      
      const totalCount = allPosts.length;
      const resolvedCount = allPosts.filter(p => p.status === 'resolved').length;
      const lostCount = allPosts.filter(p => p.type === 'lost').length;
      const foundCount = allPosts.filter(p => p.type === 'found').length;
      const activeCount = allPosts.filter(p => p.status === 'open').length;
      
      const recoveryRate = totalCount > 0 ? ((resolvedCount / totalCount) * 100).toFixed(1) : '0.0';

      let activeUsers = 'N/A';
      try {
        const usersRes = await axios.get(`${API_URL}/users/leaderboard`);
        activeUsers = usersRes.data.length.toString();
      } catch (err) {
        // Fallback if leaderboard endpoint fails
      }

      const statsEmbed = new EmbedBuilder()
        .setColor(COLORS.PRIMARY)
        .setTitle('📈 Trace Platform Impact Metrics')
        .setDescription('Providing full transparency into our university network efficiency. Here is how our campus stands:')
        .addFields(
          { name: '📊 Total Reports', value: `\`${totalCount}\` items`, inline: true },
          { name: '✅ Resolved Property', value: `\`${resolvedCount}\` items`, inline: true },
          { name: '📈 Recovery Rate', value: `\`${recoveryRate}%\``, inline: true },
          { name: '🔴 Lost Reports', value: `\`${lostCount}\``, inline: true },
          { name: '🟢 Found Reports', value: `\`${foundCount}\``, inline: true },
          { name: '👥 Active Members', value: `\`${activeUsers}\``, inline: true }
        )
        .setFooter({ text: 'Making our university a safer, more connected place.' })
        .setTimestamp();

      await interaction.editReply({ embeds: [statsEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Statistics Unavailable')
        .setDescription('Failed to compile campus statistics. Please try again later.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /search
  else if (commandName === 'search') {
    const query = interaction.options.getString('query');
    try {
      await interaction.deferReply();
      const res = await axios.get(`${API_URL}/posts`);
      
      const cleanQuery = query.toLowerCase();
      const matches = res.data.filter(p => 
        p.title?.toLowerCase().includes(cleanQuery) || 
        p.location_name?.toLowerCase().includes(cleanQuery) || 
        p.description?.toLowerCase().includes(cleanQuery)
      ).slice(0, 8);

      if (matches.length === 0) {
        const emptyEmbed = new EmbedBuilder()
          .setColor(COLORS.SLATE)
          .setTitle('🔍 Search Dashboard')
          .setDescription(`No items found matching the search criteria: **"${query}"**.\nTry using different keywords or checking spelling.`)
          .setTimestamp();

        await interaction.editReply({ embeds: [emptyEmbed] });
        return;
      }

      let description = `Showing the top matching items for **"${query}"**:\n\n`;
      matches.forEach((p, idx) => {
        const emoji = p.type === 'lost' ? '🔴' : '🟢';
        description += `**${idx + 1}. ${emoji} ${p.title}**\n📍 Location: *${p.location_name || 'Campus'}* • Status: \`${p.status.toUpperCase()}\`\nPost ID: \`${p.id}\`\n\n`;
      });

      const searchEmbed = new EmbedBuilder()
        .setColor(COLORS.SLATE)
        .setTitle('🔍 Trace Property Catalog Search')
        .setDescription(description)
        .setFooter({ text: 'Use /post <post_id> to inspect any item details.' })
        .setTimestamp();

      await interaction.editReply({ embeds: [searchEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Search Interrupted')
        .setDescription('Failed to perform the catalog search. Please try again in a few minutes.');

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }

  // Handle /post
  else if (commandName === 'post') {
    const postId = interaction.options.getString('post_id');
    try {
      await interaction.deferReply();
      const res = await axios.get(`${API_URL}/posts/${postId}`);
      const p = res.data;

      const isLost = p.type === 'lost';
      
      const postEmbed = new EmbedBuilder()
        .setColor(isLost ? COLORS.RED : COLORS.GREEN)
        .setTitle(`${isLost ? '🔴' : '🟢'} ${p.type.toUpperCase()}: ${p.title}`)
        .setDescription(p.description || 'No additional description provided.')
        .addFields(
          { name: '📍 Location', value: p.location_name || p.buildingName || 'Campus Ground', inline: true },
          { name: '🏢 Building Structure', value: `${p.buildingName || 'General Area'} (Floor ${p.floor || 0})`, inline: true },
          { name: '🏷️ Catalog Status', value: `\`${p.status.toUpperCase()}\``, inline: true },
          { name: '👤 Reported By', value: p.posterName || 'Trace Member', inline: true },
          { name: '📅 Date Logged', value: new Date(p.timestamp).toLocaleDateString(), inline: true },
          { name: '❤️ Likes & Views', value: `❤️ ${p.likeCount || 0} Likes • 👁️ ${p.viewCount || 0} Views`, inline: true }
        )
        .setFooter({ text: `Post ID: ${p.id} • Trace Security & Logistics` })
        .setTimestamp();

      if (p.posterAvatarUrl) {
        postEmbed.setThumbnail(p.posterAvatarUrl);
      }

      await interaction.editReply({ embeds: [postEmbed] });
    } catch (err) {
      const errEmbed = new EmbedBuilder()
        .setColor(COLORS.RED)
        .setTitle('❌ Item Lookup Failed')
        .setDescription('Could not locate a post with the provided ID. Please double-check the ID spelling and try again.')
        .setTimestamp();

      await interaction.editReply({ embeds: [errEmbed] });
    }
  }
});

client.login(TOKEN);
