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

// POST /api/checkins
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const body = req.body;
    
    // Set user_id if not present
    body.user_id = body.user_id || userId;
    
    const keys = Object.keys(body);
    const values = Object.values(body);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    
    const result = await query(
      `INSERT INTO daily_checkins (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
    );
    
    return res.json(result.rows);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
