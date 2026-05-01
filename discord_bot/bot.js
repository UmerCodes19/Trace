const { Client, GatewayIntentBits, REST, Routes, SlashCommandBuilder } = require('discord.js');
const axios = require('axios');

// Configure Bot
const TOKEN = process.env.DISCORD_BOT_TOKEN;
const CLIENT_ID = process.env.DISCORD_CLIENT_ID;
const API_URL = process.env.TRACE_API_URL || 'https://trace-self.vercel.app/api';

if (!TOKEN || !CLIENT_ID) {
  console.error('Missing environment variables: DISCORD_BOT_TOKEN and DISCORD_CLIENT_ID are required.');
}

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages]
});

// Slash Commands Definition
const commands = [
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
].map(command => command.toJSON());

// Register Slash Commands
const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
  try {
    console.log('Started refreshing application (/) commands...');
    await rest.put(
      Routes.applicationCommands(CLIENT_ID),
      { body: commands },
    );
    console.log('Successfully reloaded application (/) commands.');
  } catch (error) {
    console.error(error);
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
      await interaction.editReply(`✅ Your Discord account is now linked to Trace account. Welcome back, ${user.username}!`);
    } catch (err) {
      const msg = err.response?.data?.error || '⚠️ Trace service is temporarily unavailable. Try again in a few minutes.';
      await interaction.editReply(`❌ ${msg}`);
    }
    return;
  }

  // Check link status for other commands
  let userId = null;
  if (['unlink', 'lost', 'found', 'myitems', 'claim', 'resolve'].includes(commandName)) {
    userId = await checkLink(user.id);
    if (!userId) {
      await interaction.reply({
        content: `❌ Link your Discord first: Open the Trace app → Settings → Link Discord Account`,
        ephemeral: true
      });
      return;
    }
  }

  // Handle /unlink
  if (commandName === 'unlink') {
    try {
      await interaction.deferReply({ ephemeral: true });
      await axios.post(`${API_URL}/discord/unlink`, { discord_id: user.id });
      await interaction.editReply(`✅ Disconnected from your Trace account successfully.`);
    } catch (err) {
      await interaction.editReply(`❌ Failed to unlink. Please try again later.`);
    }
  }

  // Handle /lost and /found
  else if (commandName === 'lost' || commandName === 'found') {
    const item = interaction.options.getString('item');
    const loc = interaction.options.getString('location');
    const desc = interaction.options.getString('description') || `Reported via Discord by ${user.username}`;

    try {
      await interaction.deferReply();
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

      const emoji = commandName === 'lost' ? '🔴' : '🟢';
      await interaction.editReply({
        content: `### ${emoji} ${commandName.toUpperCase()} Item Reported\n**Item:** ${item}\n**Location:** ${loc}\n**Posted by:** ${user.username}\n**Status:** Looking for item\n**Post ID:** \`${res.data.id}\``
      });
    } catch (err) {
      console.error(err);
      await interaction.editReply(`❌ Failed to submit your post. Trace service is temporarily unavailable.`);
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
        await interaction.editReply('📭 No recent posts found on Trace.');
        return;
      }

      let reply = `### 📋 Recent Posts (${items.length})\n`;
      items.forEach((p, idx) => {
        const emoji = p.type === 'lost' ? '🔴' : '🟢';
        reply += `${idx + 1}. ${emoji} **${p.title}** - \`${p.status.toUpperCase()}\` at *${p.location_name}*\n> *Post ID:* \`${p.id}\`\n`;
      });

      await interaction.editReply(reply);
    } catch (err) {
      await interaction.editReply(`❌ Failed to load recent posts. Please try again in a few minutes.`);
    }
  }

  // Handle /myitems
  else if (commandName === 'myitems') {
    try {
      await interaction.deferReply({ ephemeral: true });
      const res = await axios.get(`${API_URL}/posts`);
      const items = res.data.filter(p => p.userId === userId);

      if (items.length === 0) {
        await interaction.editReply('📭 You haven\'t reported any items yet.');
        return;
      }

      let reply = `### 📂 Your Items (${items.length})\n`;
      items.forEach((p, idx) => {
        const emoji = p.type === 'lost' ? '🔴' : '🟢';
        reply += `${idx + 1}. ${emoji} **${p.title}** - \`${p.status.toUpperCase()}\` at *${p.location_name}*\n> *Post ID:* \`${p.id}\`\n`;
      });

      await interaction.editReply(reply);
    } catch (err) {
      await interaction.editReply(`❌ Failed to retrieve your items.`);
    }
  }

  // Handle /claim
  else if (commandName === 'claim') {
    const postId = interaction.options.getString('post_id');
    try {
      await interaction.deferReply();
      const res = await axios.post(`${API_URL}/claims/request`, {
        postId,
        proofText: `Claimed via Discord by ${user.username}`,
        proofImageUrl: ''
      }, {
        headers: {
          'Authorization': `Bearer ${userId}` // UID works as fallback token
        }
      });

      await interaction.editReply(`✅ Claim request submitted successfully for item **${postId}**. The owner has been notified!`);
    } catch (err) {
      const msg = err.response?.data?.error || '⚠️ Trace service is temporarily unavailable. Try again in a few minutes.';
      await interaction.editReply(`❌ ${msg}`);
    }
  }

  // Handle /resolve
  else if (commandName === 'resolve') {
    const postId = interaction.options.getString('post_id');
    try {
      await interaction.deferReply();
      const res = await axios.put(`${API_URL}/posts/${postId}`, {
        status: 'resolved'
      }, {
        headers: {
          'Authorization': `Bearer ${userId}`
        }
      });
      await interaction.editReply(`✅ Item marked as resolved successfully!`);
    } catch (err) {
      await interaction.editReply(`❌ Failed to resolve post. Make sure you are the author and that the Post ID is correct.`);
    }
  }
});

client.login(TOKEN);
