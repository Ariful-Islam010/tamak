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

// POST /api/goals (Create or Update goal current_amount)
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const { title, target_amount, current_amount, is_completed, icon_name } = req.body;

    if (!title || !target_amount) {
      return res.status(400).json({ detail: 'Title and target_amount are required' });
    }

    const existing = await query(
      'SELECT id FROM money_saver_goals WHERE user_id = $1 AND title = $2',
      [userId, title]
    );

    let result;
    if (existing.rowCount > 0) {
      result = await query(
        `UPDATE money_saver_goals
         SET current_amount = $1, is_completed = $2, target_amount = $3
         WHERE id = $4 RETURNING *`,
        [current_amount || 0, is_completed || false, target_amount, existing.rows[0].id]
      );
    } else {
      result = await query(
        `INSERT INTO money_saver_goals (user_id, title, target_amount, current_amount, is_completed, icon_name)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [userId, title, target_amount, current_amount || 0, is_completed || false, icon_name || 'star']
      );
    }
    return res.json(result.rows);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
