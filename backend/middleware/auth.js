const admin = require('firebase-admin');
const supabase = require('../utils/supabase');

/**
 * Middleware to verify Firebase JWT token and attach user to request
 */
const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Fetch user role from database
    const { data: user, error } = await supabase
      .from('users')
      .select('role, isBanned')
      .eq('uid', decodedToken.uid)
      .single();

    if (error && error.code !== 'PGRST116') throw error;

    if (user && user.isBanned) {
      return res.status(403).json({ error: 'User is banned' });
    }

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: user ? user.role : 'user' // Default to 'user' if not in DB yet
    };

    next();
  } catch (error) {
    console.error('Auth Error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};

/**
 * Middleware to restrict access based on roles
 * @param {Array} allowedRoles - List of roles that can access the route
 */
const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied: Insufficient permissions' });
    }

    next();
  };
};

module.exports = {
  verifyToken,
  checkRole
};
