const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/goals
router.get('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const result = await query(
      'SELECT * FROM money_saver_goals WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    return res.json(result.rows);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/goals
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const body = req.body;
    body.user_id = body.user_id || userId;

    const keys = Object.keys(body);
    const values = Object.values(body);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    
    const result = await query(
      `INSERT INTO money_saver_goals (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
    );
    return res.json(result.rows);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
