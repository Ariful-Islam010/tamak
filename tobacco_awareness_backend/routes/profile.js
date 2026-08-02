const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');
const { requireAuth } = require('../middleware/auth');

// GET /api/profile
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('GET', '/rest/v1/user_profiles?select=*', {
      token: req.token,
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    const data = result.data;
    if (Array.isArray(data) && data.length > 0) {
      return res.json(data[0]);
    }
    return res.json(data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/profile
router.post('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('POST', '/rest/v1/user_profiles', {
      token: req.token,
      jsonData: req.body,
      prefer: 'resolution=merge-duplicates,return=representation',
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    const data = result.data;
    if (Array.isArray(data) && data.length > 0) {
      return res.json(data[0]);
    }
    return res.json(data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
