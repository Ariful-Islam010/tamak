const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const fs = require('fs');
const path = require('path');

// ── Admin Auth Middleware ──────────────────────────────────────────────────────
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'tamak_admin_2024';

function requireAdmin(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.replace('Bearer ', '').trim();
  if (token !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

// ── Serve Admin HTML ───────────────────────────────────────────────────────────
router.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// ── GET /admin/api/stats ───────────────────────────────────────────────────────
router.get('/api/stats', requireAdmin, async (req, res) => {
  try {
    const [
      users, usersToday, messages, goals, checkins,
      sos, storage, activeUsers7d, newUsers7d
    ] = await Promise.all([
      query('SELECT COUNT(*) FROM users'),
      query("SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL '1 day'"),
      query('SELECT COUNT(*) FROM peer_support_messages'),
      query('SELECT COUNT(*) FROM money_saver_goals'),
      query('SELECT COUNT(*) FROM daily_checkins'),
      query('SELECT COUNT(*) FROM sos_logs'),
      query('SELECT COALESCE(SUM(file_size_bytes),0) as total FROM media_files'),
      query("SELECT COUNT(DISTINCT user_id) FROM daily_checkins WHERE created_at >= NOW() - INTERVAL '7 days'"),
      query(`
        SELECT DATE(created_at) as day, COUNT(*) as count
        FROM users
        WHERE created_at >= NOW() - INTERVAL '7 days'
        GROUP BY DATE(created_at)
        ORDER BY day ASC
      `)
    ]);

    res.json({
      total_users: parseInt(users.rows[0].count),
      users_today: parseInt(usersToday.rows[0].count),
      total_messages: parseInt(messages.rows[0].count),
      total_goals: parseInt(goals.rows[0].count),
      total_checkins: parseInt(checkins.rows[0].count),
      total_sos: parseInt(sos.rows[0].count),
      storage_used_bytes: parseInt(storage.rows[0].total),
      active_users_7d: parseInt(activeUsers7d.rows[0].count),
      user_growth_7d: newUsers7d.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/users ───────────────────────────────────────────────────────
router.get('/api/users', requireAdmin, async (req, res) => {
  try {
    const { search = '', page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    const searchParam = `%${search}%`;

    const result = await query(`
      SELECT
        u.id, u.email, u.created_at, u.google_id,
        up.display_name, up.photo_url, up.plan_duration,
        up.quit_date, up.age, up.gender, up.educational_info,
        (SELECT COUNT(*) FROM daily_checkins WHERE user_id = u.id) as checkin_count,
        (SELECT COUNT(*) FROM money_saver_goals WHERE user_id = u.id) as goal_count,
        (SELECT COUNT(*) FROM peer_support_messages WHERE sender_id = u.id) as message_count,
        (SELECT COUNT(*) FROM sos_logs WHERE user_id = u.id) as sos_count
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.id
      WHERE u.email ILIKE $1 OR up.display_name ILIKE $1
      ORDER BY u.created_at DESC
      LIMIT $2 OFFSET $3
    `, [searchParam, limit, offset]);

    const total = await query(`
      SELECT COUNT(*) FROM users u
      LEFT JOIN user_profiles up ON u.id = up.id
      WHERE u.email ILIKE $1 OR up.display_name ILIKE $1
    `, [searchParam]);

    res.json({
      users: result.rows,
      total: parseInt(total.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/users/:id ───────────────────────────────────────────────────
router.get('/api/users/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const [profile, goals, checkins, savings, gamification] = await Promise.all([
      query('SELECT u.*, up.* FROM users u LEFT JOIN user_profiles up ON u.id = up.id WHERE u.id = $1', [id]),
      query('SELECT * FROM money_saver_goals WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      query('SELECT * FROM daily_checkins WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10', [id]),
      query('SELECT * FROM savings_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10', [id]),
      query('SELECT * FROM gamification_progress WHERE user_id = $1', [id]),
    ]);

    if (profile.rowCount === 0) return res.status(404).json({ error: 'User not found' });

    res.json({
      profile: profile.rows[0],
      goals: goals.rows,
      checkins: checkins.rows,
      savings: savings.rows,
      gamification: gamification.rows[0] || null
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /admin/api/users/:id ────────────────────────────────────────────────
router.delete('/api/users/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM users WHERE id = $1', [id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /admin/api/users/bulk/test-accounts ─────────────────────────────────
router.delete('/api/users/bulk/test-accounts', requireAdmin, async (req, res) => {
  try {
    const result = await query("DELETE FROM users WHERE email LIKE '%@example.com' RETURNING id");
    res.json({ deleted: result.rowCount });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/messages ────────────────────────────────────────────────────
router.get('/api/messages', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT p.id, p.content, p.image_url, p.created_at,
             up.display_name, up.photo_url, u.email
      FROM peer_support_messages p
      LEFT JOIN user_profiles up ON p.sender_id = up.id
      LEFT JOIN users u ON p.sender_id = u.id
      ORDER BY p.created_at DESC
      LIMIT 200
    `);
    res.json({ messages: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /admin/api/messages/:id ────────────────────────────────────────────
router.delete('/api/messages/:id', requireAdmin, async (req, res) => {
  try {
    await query('DELETE FROM peer_support_messages WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /admin/api/messages (wipe all) ─────────────────────────────────────
router.delete('/api/messages', requireAdmin, async (req, res) => {
  try {
    await query('TRUNCATE TABLE peer_support_messages');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/files ───────────────────────────────────────────────────────
router.get('/api/files', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT mf.id, mf.file_name, mf.file_size_bytes, mf.mime_type, mf.url, mf.created_at,
             up.display_name, u.email
      FROM media_files mf
      LEFT JOIN user_profiles up ON mf.user_id = up.id
      LEFT JOIN users u ON mf.user_id = u.id
      ORDER BY mf.created_at DESC
    `);
    const totalStorage = await query('SELECT COALESCE(SUM(file_size_bytes),0) as total, COUNT(*) as count FROM media_files');
    res.json({
      files: result.rows,
      total_bytes: parseInt(totalStorage.rows[0].total),
      total_count: parseInt(totalStorage.rows[0].count)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /admin/api/files/:id ───────────────────────────────────────────────
router.delete('/api/files/:id', requireAdmin, async (req, res) => {
  try {
    const result = await query('SELECT file_name FROM media_files WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'File not found' });

    const fileName = result.rows[0].file_name;
    const filePath = path.join(__dirname, '../uploads', fileName);

    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    await query('DELETE FROM media_files WHERE id = $1', [req.params.id]);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/sos ─────────────────────────────────────────────────────────
router.get('/api/sos', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT s.*, up.display_name, u.email
      FROM sos_logs s
      LEFT JOIN user_profiles up ON s.user_id = up.id
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.created_at DESC
    `);
    res.json({ sos_logs: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /admin/api/db-stats ────────────────────────────────────────────────────
router.get('/api/db-stats', requireAdmin, async (req, res) => {
  try {
    const tables = [
      'users', 'user_profiles', 'daily_checkins', 'peer_support_messages',
      'money_saver_goals', 'savings_logs', 'gamification_progress',
      'user_mission_progress', 'wishlist_items', 'sos_logs', 'media_files'
    ];

    const counts = await Promise.all(
      tables.map(t => query(`SELECT COUNT(*) as count FROM ${t}`).then(r => ({ table: t, count: parseInt(r.rows[0].count) })))
    );

    res.json({ tables: counts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
