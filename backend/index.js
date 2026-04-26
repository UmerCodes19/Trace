const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

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
app.use('/api/chats', chatRoutes);
app.use('/api/cms', cmsRoutes);
app.use('/api/admin', adminRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
