const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Import routes
const postRoutes = require('./routes/posts');
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats');
const cmsRoutes = require('./routes/cms');

// Use routes
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/cms', cmsRoutes);

module.exports = app;
