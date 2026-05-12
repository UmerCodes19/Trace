const NodeCache = require('node-cache');

// Standard caching bucket: Default TTL of 60 seconds (adjust per route)
const mainCache = new NodeCache({ stdTTL: 60, checkperiod: 30 });

/**
 * Generates a request-derived cache key including query params
 */
const generateKey = (req) => {
  const baseUrl = req.originalUrl || req.url;
  // Exclude transient auth specific artifacts if needed, 
  // but generally originalUrl encompasses full query uniqueness.
  return baseUrl;
};

/**
 * Global memory caching middleware
 * @param {number} duration Seconds to cache response
 */
const cache = (duration) => {
  return (req, res, next) => {
    // Skip non-GET requests immediately
    if (req.method !== 'GET') {
      return next();
    }

    const key = generateKey(req);
    const cachedResponse = mainCache.get(key);

    if (cachedResponse) {
      // CACHE HIT
      res.setHeader('X-Cache', 'HIT');
      return res.json(cachedResponse);
    }

    // CACHE MISS: Hijack the json output method to store the cache result before it leaves the pipe
    res.setHeader('X-Cache', 'MISS');
    const originalJson = res.json;

    res.json = function (body) {
      // If success response code, cache it
      if (res.statusCode >= 200 && res.statusCode < 300) {
        mainCache.set(key, body, duration);
      }
      
      return originalJson.call(this, body);
    };

    next();
  };
};

// Helper to manually invalidate a key if we know data changed (e.g., after a POST)
const invalidate = (keyPattern) => {
  if (!keyPattern) {
    mainCache.flushAll();
    return;
  }
  const keys = mainCache.keys();
  const matches = keys.filter(k => k.includes(keyPattern));
  if (matches.length > 0) {
    mainCache.del(matches);
  }
};

module.exports = {
  cache,
  invalidate,
  mainCache
};
