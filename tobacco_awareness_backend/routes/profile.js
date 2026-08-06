const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/profile
router.get('/', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const result = await query(
      `SELECT up.id, u.email, up.display_name, up.photo_url, up.age, up.gender,
              up.educational_info, up.plan_duration, up.quit_date, up.ai_quit_plan,
              up.created_at, up.updated_at
       FROM user_profiles up
       LEFT JOIN users u ON up.id = u.id
       WHERE up.id = $1`,
      [userId]
    );
    
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
    const { 
      display_name, 
      photo_url, 
      educational_info, 
      plan_duration, 
      quit_date, 
      ai_quit_plan, 
      age, 
      gender 
    } = req.body;
    
    // UPSERT style query into user_profiles
    const result = await query(
      `INSERT INTO user_profiles (id, display_name, photo_url, educational_info, plan_duration, quit_date, ai_quit_plan, age, gender)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (id) DO UPDATE SET
         display_name = EXCLUDED.display_name,
         photo_url = EXCLUDED.photo_url,
         educational_info = EXCLUDED.educational_info,
         plan_duration = EXCLUDED.plan_duration,
         quit_date = EXCLUDED.quit_date,
         ai_quit_plan = EXCLUDED.ai_quit_plan,
         age = EXCLUDED.age,
         gender = EXCLUDED.gender,
         updated_at = NOW()
       RETURNING *`,
      [userId, display_name, photo_url, educational_info, plan_duration, quit_date, ai_quit_plan, age, gender]
    );

    return res.json(result.rows[0]);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
