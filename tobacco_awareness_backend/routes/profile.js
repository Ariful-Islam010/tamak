const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/profile
router.get('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const result = await query('SELECT * FROM user_profiles WHERE id = $1', [userId]);
    
    if (result.rowCount === 0) {
      return res.json({});
    }
    return res.json(result.rows[0]);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/profile
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const { name, avatar_url, quit_date, cigs_per_day, price_per_pack, currency, target_goal, language } = req.body;
    
    // UPSERT style query since the original logic was resolution=merge-duplicates
    const result = await query(
      `INSERT INTO user_profiles (id, name, avatar_url, quit_date, cigs_per_day, price_per_pack, currency, target_goal, language)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         avatar_url = EXCLUDED.avatar_url,
         quit_date = EXCLUDED.quit_date,
         cigs_per_day = EXCLUDED.cigs_per_day,
         price_per_pack = EXCLUDED.price_per_pack,
         currency = EXCLUDED.currency,
         target_goal = EXCLUDED.target_goal,
         language = EXCLUDED.language
       RETURNING *`,
      [userId, name, avatar_url, quit_date, cigs_per_day, price_per_pack, currency, target_goal, language]
    );

    return res.json(result.rows[0]);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
