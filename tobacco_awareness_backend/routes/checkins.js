const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');
const { requireAuth } = require('../middleware/auth');
const { getBstTodayStr } = require('../utils/time_utils');

// GET /api/checkins/today
router.get('/today', requireAuth, async (req, res) => {
  try {
    const today = getBstTodayStr();
    const result = await supabaseReq('GET', `/rest/v1/daily_checkins?select=*&check_in_date=eq.${today}`, {
      token: req.token,
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    const data = result.data;
    if (Array.isArray(data) && data.length > 0) {
      return res.json(data[0]);
    }
    return res.json(null);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/checkins
router.post('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('POST', '/rest/v1/daily_checkins', {
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
