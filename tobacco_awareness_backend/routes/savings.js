const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');
const { requireAuth } = require('../middleware/auth');

// GET /api/savings
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('GET', '/rest/v1/savings_logs?select=*', {
      token: req.token,
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/savings
router.post('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('POST', '/rest/v1/savings_logs', {
      token: req.token,
      jsonData: req.body,
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
