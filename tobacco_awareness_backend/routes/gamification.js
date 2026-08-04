const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/gamification
router.get('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const result = await query('SELECT * FROM gamification_progress WHERE user_id = $1', [userId]);
    
    if (result.rowCount > 0) {
      return res.json(result.rows[0]);
    }
    return res.json(null);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/gamification
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const { user_id, current_level, total_points, badges } = req.body;
    const targetUserId = user_id || userId;
    
    // UPSERT style query
    const result = await query(
      `INSERT INTO gamification_progress (user_id, current_level, total_points, badges)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id) DO UPDATE SET
         current_level = EXCLUDED.current_level,
         total_points = EXCLUDED.total_points,
         badges = EXCLUDED.badges
       RETURNING *`,
      [targetUserId, current_level, total_points, JSON.stringify(badges)]
    );
    
    return res.json(result.rows[0]);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// GET /api/gamification/stats
router.get('/stats', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;

    const checkinsRes = await query(
      'SELECT check_in_date, used_tobacco FROM daily_checkins WHERE user_id = $1 ORDER BY check_in_date ASC',
      [userId]
    );
    const checkins = checkinsRes.rows;

    const savingsRes = await query(
      'SELECT amount FROM savings_logs WHERE user_id = $1',
      [userId]
    );
    const total_savings = savingsRes.rows.reduce((acc, row) => acc + (parseInt(row.amount, 10) || 0), 0);

    const profileRes = await query(
      'SELECT plan_duration, quit_date FROM user_profiles WHERE id = $1',
      [userId]
    );
    const profile = profileRes.rows.length > 0 ? profileRes.rows[0] : {};

    const sosRes = await query(
      'SELECT id FROM sos_logs WHERE user_id = $1',
      [userId]
    );
    const sos_count = sosRes.rowCount;

    const messagesRes = await query(
      'SELECT id FROM peer_support_messages WHERE sender_id = $1',
      [userId]
    );
    const messages_count = messagesRes.rowCount;

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
