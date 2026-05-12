const express = require('express');
const router = express.Router();
const { authenticator } = require('otplib');
const qrcode = require('qrcode');
const supabase = require('../utils/supabase');
const { verifyToken } = require('../middleware/auth');

/**
 * Step 1: Generate temporary TOTP Secret & QR Code
 * Endpoint: GET /api/security/2fa/setup
 */
router.get('/setup', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Fetch current user email for label creation
    const { data: user, error: userErr } = await supabase
      .from('users')
      .select('email')
      .eq('uid', userId)
      .single();
      
    if (userErr) throw new Error('User not found');

    // 1. Generate high-entropy random base32 secret
    const secret = authenticator.generateSecret();
    
    // 2. Format key uri standard for Google Authenticator/Authy
    const otpauthUrl = authenticator.keyuri(
      user.email || userId,
      'TracePlatform',
      secret
    );

    // 3. Render directly to DataURL image string so device doesn't need external generator
    const qrImageUrl = await qrcode.toDataURL(otpauthUrl);

    // Return proposed secret + visual payload
    res.json({
      proposedSecret: secret,
      qrImageUrl: qrImageUrl,
      setupUrl: otpauthUrl
    });
    
  } catch (err) {
    res.status(500).json({ error: 'Failed to initialize 2FA config: ' + err.message });
  }
});

/**
 * Step 2: Verify the setup code and PERSIST it to Supabase definitively.
 * Endpoint: POST /api/security/2fa/activate
 */
router.post('/activate', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { proposedSecret, token } = req.body;

    if (!proposedSecret || !token) {
      return res.status(400).json({ error: 'Proposed secret and validation token required' });
    }

    // Validate the entered token against proposed secret
    const isValid = authenticator.verify({
      token: token,
      secret: proposedSecret,
      window: 1
    });

    if (!isValid) {
      return res.status(400).json({ error: 'Invalid authenticator code. Please try again.' });
    }

    // Securely store the finalized secret and enable flag in user record
    // NOTE: Requires 'twoFactorSecret' and 'twoFactorEnabled' in Supabase user profile
    const { data, error } = await supabase
      .from('users')
      .update({
        twoFactorSecret: proposedSecret,
        twoFactorEnabled: true
      })
      .eq('uid', userId)
      .select();

    if (error) {
      // Defensive check: column might not exist yet on older db schemas
      if (error.message.includes('does not exist')) {
         return res.status(422).json({ 
           error: 'Feature requires DB Schema update: Add twoFactorSecret (text) and twoFactorEnabled (bool) to users table.' 
         });
      }
      throw error;
    }

    res.json({ success: true, message: 'Multi-Factor Authentication safely established.' });

  } catch (err) {
    res.status(500).json({ error: 'Activation flow failed: ' + err.message });
  }
});

/**
 * Validation Check: Intercepts potential intrusions
 * Endpoint: POST /api/security/2fa/check
 */
router.post('/check', async (req, res) => {
  try {
    const { userId, token } = req.body;

    if (!userId || !token) {
      return res.status(400).json({ error: 'Identity identifier and code required.' });
    }

    // Fetch current definitive secret
    const { data: user, error } = await supabase
      .from('users')
      .select('twoFactorSecret, twoFactorEnabled')
      .eq('uid', userId)
      .single();

    if (error || !user) {
      return res.status(404).json({ error: 'User security record not located.' });
    }

    if (!user.twoFactorEnabled || !user.twoFactorSecret) {
      // User hasn't enforced 2FA, consider it approved implicitly or bypassable
      return res.json({ valid: true, enforced: false });
    }

    const valid = authenticator.verify({
      token: token,
      secret: user.twoFactorSecret,
      window: 1
    });

    res.json({ valid: valid, enforced: true });

  } catch (err) {
    res.status(500).json({ error: 'Validation circuit malfunction: ' + err.message });
  }
});

module.exports = router;
