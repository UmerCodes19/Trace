const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const app = express();

// Initialize Firebase Admin
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('✅ Firebase Admin initialized successfully');
    }
  } catch (e) {
    console.error('❌ Firebase Admin failed to initialize:', e);
  }
} else {
  console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT is missing in environment variables');
}

app.use(cors());
app.use(express.json());

// Import routes
const postRoutes = require('../server/routes/posts');
const userRoutes = require('../server/routes/users');
const chatRoutes = require('../server/routes/chats');
const cmsRoutes = require('../server/routes/cms');
const claimRoutes = require('../server/routes/claims');
const claimLogRoutes = require('../server/routes/claim_logs');
const adminRoutes = require('../server/routes/admin');
const notificationRoutes = require('../server/routes/notifications');
const discordRoutes = require('../server/routes/discord');
const discordInteractionsRoutes = require('../server/routes/discord-interactions');
const { verifyToken, checkRole } = require('../server/middleware/auth');

// Use routes
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/cms', cmsRoutes);
app.use('/api/claims', claimRoutes);
app.use('/api/claim-logs', verifyToken, checkRole(['admin']), claimLogRoutes);
app.use('/api/admin', verifyToken, checkRole(['admin', 'staff']), adminRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/discord', discordRoutes);
app.use('/api/discord-interactions', discordInteractionsRoutes);

module.exports = app;
