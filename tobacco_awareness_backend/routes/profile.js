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
    
    // UPSERT with COALESCE so partial updates (e.g. photo/email) NEVER wipe existing assessment fields!
    const result = await query(
      `INSERT INTO user_profiles (id, display_name, photo_url, educational_info, plan_duration, quit_date, ai_quit_plan, age, gender)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (id) DO UPDATE SET
         display_name = COALESCE(EXCLUDED.display_name, user_profiles.display_name),
         photo_url = COALESCE(EXCLUDED.photo_url, user_profiles.photo_url),
         educational_info = COALESCE(EXCLUDED.educational_info, user_profiles.educational_info),
         plan_duration = COALESCE(EXCLUDED.plan_duration, user_profiles.plan_duration),
         quit_date = COALESCE(EXCLUDED.quit_date, user_profiles.quit_date),
         ai_quit_plan = COALESCE(EXCLUDED.ai_quit_plan, user_profiles.ai_quit_plan),
         age = COALESCE(EXCLUDED.age, user_profiles.age),
         gender = COALESCE(EXCLUDED.gender, user_profiles.gender),
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
