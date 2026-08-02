const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');
const { requireAuth } = require('../middleware/auth');

// GET /api/gamification
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('GET', '/rest/v1/gamification_progress?select=*', {
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

// POST /api/gamification
router.post('/', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('POST', '/rest/v1/gamification_progress', {
      token: req.token,
      jsonData: req.body,
      prefer: 'resolution=merge-duplicates,return=representation',
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// GET /api/gamification/stats
router.get('/stats', requireAuth, async (req, res) => {
  try {
    const checkinsRes = await supabaseReq('GET', '/rest/v1/daily_checkins?select=check_in_date,used_tobacco&order=check_in_date.asc', {
      token: req.token,
    });
    const checkins = checkinsRes.ok && Array.isArray(checkinsRes.data) ? checkinsRes.data : [];

    const savingsRes = await supabaseReq('GET', '/rest/v1/savings_logs?select=amount', {
      token: req.token,
    });
    const savings = savingsRes.ok && Array.isArray(savingsRes.data) ? savingsRes.data : [];
    const total_savings = savings.reduce((acc, row) => acc + (parseInt(row.amount, 10) || 0), 0);

    const profileRes = await supabaseReq('GET', '/rest/v1/user_profiles?select=plan_duration,quit_date', {
      token: req.token,
    });
    const profileData = profileRes.ok && Array.isArray(profileRes.data) ? profileRes.data : [];
    const profile = profileData.length > 0 ? profileData[0] : {};

    const sosRes = await supabaseReq('GET', '/rest/v1/sos_logs?select=id', {
      token: req.token,
    });
    const sos_count = sosRes.ok && Array.isArray(sosRes.data) ? sosRes.data.length : 0;

    const userRes = await supabaseReq('GET', '/auth/v1/user', {
      token: req.token,
    });
    let userId = null;
    if (userRes.ok && userRes.data) {
      userId = userRes.data.id;
    }

    let messages_count = 0;
    if (userId) {
      const messagesRes = await supabaseReq('GET', `/rest/v1/peer_support_messages?select=id&sender_id=eq.${userId}`, {
        token: req.token,
      });
      if (messagesRes.ok && Array.isArray(messagesRes.data)) {
        messages_count = messagesRes.data.length;
      }
    }

    return res.json({
      checkins,
      total_savings,
      plan_duration: profile.plan_duration || 7,
      quit_date: profile.quit_date || null,
      sos_count,
      messages_count,
    });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
