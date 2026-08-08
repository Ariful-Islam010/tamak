const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');
const { getBstTodayStr } = require('../utils/time_utils');

// GET /api/checkins/today
router.get('/today', requireAuth, async (req, res) => {
  try {
    const today = getBstTodayStr();
    const userId = req.user.sub;
    
    const result = await query(
      'SELECT * FROM daily_checkins WHERE user_id = $1 AND check_in_date = $2',
      [userId, today]
    );
    
    if (result.rowCount > 0) {
      return res.json(result.rows[0]);
    }
    return res.json(null);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/checkins (UPSERT with note support)
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const { check_in_date, craving_level, mood, used_tobacco, note } = req.body;
    
    const date = check_in_date || getBstTodayStr();
    const isUsedTobacco = used_tobacco === true || used_tobacco === 'true';

    // Ensure profile row exists to satisfy foreign key constraint
    await query('INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING', [userId]);

    const result = await query(
      `INSERT INTO daily_checkins (user_id, check_in_date, craving_level, mood, used_tobacco, note)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, check_in_date) DO UPDATE SET
         craving_level = EXCLUDED.craving_level,
         mood = EXCLUDED.mood,
         used_tobacco = EXCLUDED.used_tobacco,
         note = COALESCE(EXCLUDED.note, daily_checkins.note),
         created_at = NOW()
       RETURNING *`,
      [userId, date, craving_level || 5, mood || 'Normal', isUsedTobacco, note || null]
    );
    
    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Error submitting check-in:', error);
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
