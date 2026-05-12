const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
const compression = require('compression');

dotenv.config();

const supabase = require('./utils/supabase');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  // Fallback for development if individual variables are provided
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      })
    });
  } catch (e) {
    console.error('Firebase Admin failed to initialize. Notifications will not work.');
  }
}


// Initialize Rate Limiters
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again after 15 minutes' }
});

const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 15, // strict limit on critical auth actions per IP
  message: { error: 'Too many authentication attempts, please try again in an hour' }
});

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(compression()); // Add GZIP compression for extreme response shrinking
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use('/api/', globalLimiter); // Apply basic threshold globally to ALL API endpoints

// Routes placeholder
app.get('/', (req, res) => {
  res.json({ message: 'Lost&Found API is running' });
});

// Import routes
const postRoutes = require('./routes/posts');
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats');
const cmsRoutes = require('./routes/cms');
const adminRoutes = require('./routes/admin');
const claimLogRoutes = require('./routes/claim_logs');
const claimRoutes = require('./routes/claims');
const notificationRoutes = require('./routes/notifications');
const securityRoutes = require('./routes/auth_security');
const { verifyToken, checkRole } = require('./middleware/auth');


// Use routes
// Debug endpoint to check DB schema
app.get('/api/debug-db', async (req, res) => {
  try {
    const { data, error } = await supabase.rpc('get_table_info', { table_name: 'users' });
    if (error) {
      // Fallback if RPC doesn't exist
      const { data: cols, error: err2 } = await supabase.from('users').select('*').limit(1);
      return res.json({
        message: "Check these keys to see if they match exactly (case sensitive!)",
        keys: cols && cols.length > 0 ? Object.keys(cols[0]) : "No users found to check keys"
      });
    }
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', verifyToken, chatRoutes);
app.use('/api/cms', authLimiter, cmsRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', authLimiter, verifyToken, checkRole(['admin', 'staff']), adminRoutes);
app.use('/api/claim-logs', verifyToken, claimLogRoutes);
app.use('/api/claims', claimRoutes);
app.use('/api/security', securityRoutes);


app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
