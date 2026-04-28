const express = require('express');
const router = express.Router();
const BlockchainService = require('../services/blockchain_service');

/**
 * Get all claim logs (Admin only)
 */
router.get('/', async (req, res) => {
  try {
    const { data, error } = await BlockchainService.validateChain();
    
    // We return the logs even if invalid, but include the validation status
    const { data: logs, error: fetchError } = await require('../utils/supabase')
      .from('claim_logs')
      .select('*')
      .order('timestamp', { ascending: false });

    if (fetchError) throw fetchError;

    res.json({
      integrity: data,
      logs: logs
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Manually trigger a chain validation
 */
router.get('/verify', async (req, res) => {
  try {
    const result = await BlockchainService.validateChain();
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
