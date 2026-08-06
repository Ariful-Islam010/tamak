const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const fs = require('fs');
const path = require('path');

// ── Admin Auth Middleware ─────────────────────────────────────────────────────
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'tamak_admin_2024';

function requireAdmin(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.replace('Bearer ', '').trim();
  if (token !== ADMIN_PASSWORD) return res.status(401).json({ error: 'Unauthorized' });
  next();
}

function toCSV(rows) {
  if (!rows || rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const escape = (v) => {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const lines = [headers.join(','), ...rows.map(r => headers.map(h => escape(r[h])).join(','))];
  return lines.join('\n');
}

// ── Serve Admin Static Assets & HTML ──────────────────────────────────────────
router.use(express.static(path.join(__dirname, 'public')));
router.get('/', (req, res) => res.sendFile(path.join(__dirname, 'public', 'admin.html')));

// ── Stats ─────────────────────────────────────────────────────────────────────
router.get('/api/stats', requireAdmin, async (req, res) => {
  try {
    const [users, usersToday, messages, goals, checkins, sos, storage, activeUsers7d, newUsers7d,
      totalSavings, completedGoals, avgMood, smokeFreeUsers] = await Promise.all([
      query('SELECT COUNT(*) FROM users'),
      query("SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL '1 day'"),
      query('SELECT COUNT(*) FROM peer_support_messages'),
      query('SELECT COUNT(*) FROM money_saver_goals'),
      query('SELECT COUNT(*) FROM daily_checkins'),
      query('SELECT COUNT(*) FROM sos_logs'),
      query('SELECT COALESCE(SUM(file_size_bytes),0) as total FROM media_files'),
      query("SELECT COUNT(DISTINCT user_id) FROM daily_checkins WHERE created_at >= NOW() - INTERVAL '7 days'"),
      query(`SELECT DATE(created_at) as day, COUNT(*) as count FROM users WHERE created_at >= NOW() - INTERVAL '7 days' GROUP BY DATE(created_at) ORDER BY day ASC`),
      query('SELECT COALESCE(SUM(amount),0) as total FROM savings_logs'),
      query("SELECT COUNT(*) FROM money_saver_goals WHERE is_completed = true"),
      query('SELECT ROUND(AVG(craving_level),1) as avg FROM daily_checkins WHERE craving_level IS NOT NULL'),
      query("SELECT COUNT(DISTINCT user_id) FROM daily_checkins WHERE smoked_today = false"),
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
      user_growth_7d: newUsers7d.rows,
      total_savings: parseFloat(totalSavings.rows[0].total),
      completed_goals: parseInt(completedGoals.rows[0].count),
      avg_craving_level: parseFloat(avgMood.rows[0].avg) || 0,
      smoke_free_users: parseInt(smokeFreeUsers.rows[0].count),
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Users ─────────────────────────────────────────────────────────────────────
router.get('/api/users', requireAdmin, async (req, res) => {
  try {
    const { search = '', page = 1, limit = 200 } = req.query;
    const offset = (page - 1) * limit;
    const s = `%${search}%`;
    const result = await query(`
      SELECT u.id, u.email, u.created_at, u.google_id,
        up.display_name, up.photo_url, up.plan_duration, up.quit_date, up.age, up.gender, up.educational_info, up.ai_quit_plan,
        (SELECT COUNT(*) FROM daily_checkins WHERE user_id = u.id) as checkin_count,
        (SELECT COUNT(*) FROM money_saver_goals WHERE user_id = u.id) as goal_count,
        (SELECT COUNT(*) FROM peer_support_messages WHERE sender_id = u.id) as message_count,
        (SELECT COUNT(*) FROM sos_logs WHERE user_id = u.id) as sos_count,
        (SELECT COALESCE(SUM(amount),0) FROM savings_logs WHERE user_id = u.id) as total_saved
      FROM users u LEFT JOIN user_profiles up ON u.id = up.id
      WHERE u.email ILIKE $1 OR up.display_name ILIKE $1
      ORDER BY u.created_at DESC LIMIT $2 OFFSET $3`, [s, limit, offset]);
    const total = await query(`SELECT COUNT(*) FROM users u LEFT JOIN user_profiles up ON u.id = up.id WHERE u.email ILIKE $1 OR up.display_name ILIKE $1`, [s]);
    res.json({ users: result.rows, total: parseInt(total.rows[0].count), page: parseInt(page), limit: parseInt(limit) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/users/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT u.id, u.email, u.created_at as joined_at, CASE WHEN u.google_id IS NOT NULL THEN 'Google' ELSE 'Email' END as auth_type,
        up.display_name, up.age, up.gender, up.educational_info, up.plan_duration, up.quit_date,
        (SELECT COUNT(*) FROM daily_checkins WHERE user_id = u.id) as checkin_count,
        (SELECT COUNT(*) FROM money_saver_goals WHERE user_id = u.id) as goal_count,
        (SELECT COALESCE(SUM(amount),0) FROM savings_logs WHERE user_id = u.id) as total_saved_tk,
        (SELECT COUNT(*) FROM sos_logs WHERE user_id = u.id) as sos_count
      FROM users u LEFT JOIN user_profiles up ON u.id = up.id ORDER BY u.created_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_users.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/users/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const [profile, goals, checkins, savings, gamification, wishlist, sos, messages, files, missions] = await Promise.all([
      query('SELECT u.*, up.* FROM users u LEFT JOIN user_profiles up ON u.id = up.id WHERE u.id = $1', [id]),
      query('SELECT * FROM money_saver_goals WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      query('SELECT * FROM daily_checkins WHERE user_id = $1 ORDER BY check_in_date DESC', [id]),
      query('SELECT * FROM savings_logs WHERE user_id = $1 ORDER BY logged_at DESC', [id]),
      query('SELECT * FROM gamification_progress WHERE user_id = $1', [id]),
      query('SELECT * FROM wishlist_items WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      query('SELECT * FROM sos_logs WHERE user_id = $1 ORDER BY trigger_time DESC', [id]),
      query('SELECT * FROM peer_support_messages WHERE sender_id = $1 ORDER BY created_at DESC', [id]),
      query('SELECT * FROM media_files WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      query('SELECT * FROM user_mission_progress WHERE user_id = $1 ORDER BY progress_date DESC', [id]),
    ]);
    if (profile.rowCount === 0) return res.status(404).json({ error: 'Not found' });
    // Build summary stats
    const totalSaved = savings.rows.reduce((a, r) => a + Number(r.amount), 0);
    const smokeFreedays = checkins.rows.filter(c => !c.smoked_today).length;
    const completedGoals = goals.rows.filter(g => g.is_completed).length;
    const summary = {
      total_checkins: checkins.rowCount,
      total_goals: goals.rowCount,
      completed_goals: completedGoals,
      total_saved: totalSaved,
      total_savings_logs: savings.rowCount,
      total_messages: messages.rowCount,
      total_files: files.rowCount,
      total_sos: sos.rowCount,
      total_wishlist: wishlist.rowCount,
      smoke_free_days: smokeFreedays,
      missions_completed: missions.rows.filter(m => m.is_completed).length,
    };
    res.json({
      profile: profile.rows[0],
      summary,
      goals: goals.rows,
      checkins: checkins.rows,
      savings: savings.rows,
      gamification: gamification.rows[0] || null,
      wishlist: wishlist.rows,
      sos: sos.rows,
      messages: messages.rows,
      files: files.rows,
      missions: missions.rows,
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Per-User Full CSV Export ──────────────────────────────────────────────────
router.get('/api/users/:id/export/csv', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const userRow = await query('SELECT u.email, up.display_name FROM users u LEFT JOIN user_profiles up ON u.id = up.id WHERE u.id = $1', [id]);
    if (userRow.rowCount === 0) return res.status(404).json({ error: 'User not found' });
    const { email, display_name } = userRow.rows[0];
    const safeName = (display_name || email || id).replace(/[^a-z0-9]/gi, '_').toLowerCase();

    const sections = {
      profile: await query('SELECT u.id, u.email, u.created_at, up.display_name, up.age, up.gender, up.educational_info, up.plan_duration, up.quit_date, up.ai_quit_plan FROM users u LEFT JOIN user_profiles up ON u.id = up.id WHERE u.id = $1', [id]),
      daily_checkins: await query('SELECT id, check_in_date, mood, craving_level, smoked_today, used_tobacco, cigarettes_smoked, created_at FROM daily_checkins WHERE user_id = $1 ORDER BY check_in_date DESC', [id]),
      money_saver_goals: await query('SELECT id, title, target_amount, current_amount, is_completed, icon_name, created_at FROM money_saver_goals WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      savings_logs: await query('SELECT id, amount, logged_at FROM savings_logs WHERE user_id = $1 ORDER BY logged_at DESC', [id]),
      gamification: await query('SELECT level, current_xp, total_xp, current_streak, longest_streak, badges, last_check_in_date, updated_at FROM gamification_progress WHERE user_id = $1', [id]),
      wishlist_items: await query('SELECT id, item_name, target_amount, category_icon, is_achieved, created_at FROM wishlist_items WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      sos_logs: await query('SELECT id, selected_mode, distraction_clicked, trigger_time FROM sos_logs WHERE user_id = $1 ORDER BY trigger_time DESC', [id]),
      messages: await query('SELECT id, content, image_url, created_at FROM peer_support_messages WHERE sender_id = $1 ORDER BY created_at DESC', [id]),
      media_files: await query('SELECT id, file_name, file_size_bytes, mime_type, url, created_at FROM media_files WHERE user_id = $1 ORDER BY created_at DESC', [id]),
      mission_progress: await query('SELECT mission_id, progress_date, is_completed FROM user_mission_progress WHERE user_id = $1 ORDER BY progress_date DESC', [id]),
    };

    let output = `##### TAMAK USER DATA EXPORT #####\n##### User: ${email} (${display_name || 'No name'}) #####\n##### Exported: ${new Date().toISOString()} #####\n`;
    for (const [name, result] of Object.entries(sections)) {
      output += `\n\n=== ${name.toUpperCase()} (${result.rowCount} rows) ===\n`;
      output += result.rowCount > 0 ? toCSV(result.rows) : '(no data)';
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="tamak_user_${safeName}.csv"`);
    res.send(output);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/api/users/:id', requireAdmin, async (req, res) => {
  try {
    await query('DELETE FROM users WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/api/users/bulk/test-accounts', requireAdmin, async (req, res) => {
  try {
    const result = await query("DELETE FROM users WHERE email LIKE '%@example.com' RETURNING id");
    res.json({ deleted: result.rowCount });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Messages ──────────────────────────────────────────────────────────────────
router.get('/api/messages', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT p.id, p.content, p.image_url, p.created_at, up.display_name, u.email
      FROM peer_support_messages p
      LEFT JOIN user_profiles up ON p.sender_id = up.id
      LEFT JOIN users u ON p.sender_id = u.id
      ORDER BY p.created_at DESC LIMIT 500`);
    res.json({ messages: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/messages/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT p.id, u.email as sender_email, up.display_name as sender_name, p.content, p.image_url, p.created_at
      FROM peer_support_messages p
      LEFT JOIN user_profiles up ON p.sender_id = up.id
      LEFT JOIN users u ON p.sender_id = u.id ORDER BY p.created_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_messages.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/api/messages/:id', requireAdmin, async (req, res) => {
  try {
    await query('DELETE FROM peer_support_messages WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/api/messages', requireAdmin, async (req, res) => {
  try {
    await query('TRUNCATE TABLE peer_support_messages');
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Check-ins ─────────────────────────────────────────────────────────────────
router.get('/api/checkins', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT c.*, up.display_name, u.email
      FROM daily_checkins c
      LEFT JOIN user_profiles up ON c.user_id = up.id
      LEFT JOIN users u ON c.user_id = u.id
      ORDER BY c.created_at DESC LIMIT 500`);
    res.json({ checkins: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/checkins/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT c.id, u.email, up.display_name, c.check_in_date, c.mood, c.craving_level,
        c.smoked_today, c.used_tobacco, c.cigarettes_smoked, c.created_at
      FROM daily_checkins c
      LEFT JOIN user_profiles up ON c.user_id = up.id
      LEFT JOIN users u ON c.user_id = u.id ORDER BY c.check_in_date DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_checkins.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Goals ─────────────────────────────────────────────────────────────────────
router.get('/api/goals', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT g.*, up.display_name, u.email
      FROM money_saver_goals g
      LEFT JOIN user_profiles up ON g.user_id = up.id
      LEFT JOIN users u ON g.user_id = u.id
      ORDER BY g.created_at DESC`);
    res.json({ goals: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/goals/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT g.id, u.email, up.display_name, g.title, g.target_amount, g.current_amount,
        g.is_completed, g.icon_name, g.created_at
      FROM money_saver_goals g
      LEFT JOIN user_profiles up ON g.user_id = up.id
      LEFT JOIN users u ON g.user_id = u.id ORDER BY g.created_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_goals.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Savings ───────────────────────────────────────────────────────────────────
router.get('/api/savings', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT s.*, up.display_name, u.email
      FROM savings_logs s
      LEFT JOIN user_profiles up ON s.user_id = up.id
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.logged_at DESC LIMIT 500`);
    const totals = await query('SELECT COALESCE(SUM(amount),0) as total, COUNT(*) as count, ROUND(AVG(amount),0) as avg FROM savings_logs');
    res.json({ savings: result.rows, total: parseFloat(totals.rows[0].total), count: parseInt(totals.rows[0].count), avg: parseFloat(totals.rows[0].avg) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/savings/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT s.id, u.email, up.display_name, s.amount, s.logged_at
      FROM savings_logs s
      LEFT JOIN user_profiles up ON s.user_id = up.id
      LEFT JOIN users u ON s.user_id = u.id ORDER BY s.logged_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_savings.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Gamification ──────────────────────────────────────────────────────────────
router.get('/api/gamification', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT g.*, up.display_name, u.email
      FROM gamification_progress g
      LEFT JOIN user_profiles up ON g.user_id = up.id
      LEFT JOIN users u ON g.user_id = u.id
      ORDER BY g.total_xp DESC`);
    res.json({ gamification: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/gamification/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT u.email, up.display_name, g.level, g.current_xp, g.total_xp,
        g.current_streak, g.longest_streak, g.badges, g.last_check_in_date, g.updated_at
      FROM gamification_progress g
      LEFT JOIN user_profiles up ON g.user_id = up.id
      LEFT JOIN users u ON g.user_id = u.id ORDER BY g.total_xp DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_gamification.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Wishlist ──────────────────────────────────────────────────────────────────
router.get('/api/wishlist', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT w.*, up.display_name, u.email
      FROM wishlist_items w
      LEFT JOIN user_profiles up ON w.user_id = up.id
      LEFT JOIN users u ON w.user_id = u.id
      ORDER BY w.created_at DESC`);
    res.json({ wishlist: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/wishlist/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT w.id, u.email, up.display_name, w.item_name, w.target_amount, w.category_icon, w.is_achieved, w.created_at
      FROM wishlist_items w
      LEFT JOIN user_profiles up ON w.user_id = up.id
      LEFT JOIN users u ON w.user_id = u.id ORDER BY w.created_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_wishlist.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── SOS Logs ──────────────────────────────────────────────────────────────────
router.get('/api/sos', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT s.*, up.display_name, u.email
      FROM sos_logs s
      LEFT JOIN user_profiles up ON s.user_id = up.id
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.trigger_time DESC`);
    res.json({ sos_logs: result.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/sos/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT s.id, u.email, up.display_name, s.selected_mode, s.distraction_clicked, s.trigger_time
      FROM sos_logs s
      LEFT JOIN user_profiles up ON s.user_id = up.id
      LEFT JOIN users u ON s.user_id = u.id ORDER BY s.trigger_time DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_sos_logs.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Files ─────────────────────────────────────────────────────────────────────
router.get('/api/files', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT mf.id, mf.file_name, mf.file_size_bytes, mf.mime_type, mf.url, mf.created_at, up.display_name, u.email
      FROM media_files mf
      LEFT JOIN user_profiles up ON mf.user_id = up.id
      LEFT JOIN users u ON mf.user_id = u.id
      ORDER BY mf.created_at DESC`);
    const totals = await query('SELECT COALESCE(SUM(file_size_bytes),0) as total, COUNT(*) as count FROM media_files');
    res.json({ files: result.rows, total_bytes: parseInt(totals.rows[0].total), total_count: parseInt(totals.rows[0].count) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/files/export/csv', requireAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT mf.id, u.email, up.display_name, mf.file_name, mf.file_size_bytes, mf.mime_type, mf.url, mf.created_at
      FROM media_files mf
      LEFT JOIN user_profiles up ON mf.user_id = up.id
      LEFT JOIN users u ON mf.user_id = u.id ORDER BY mf.created_at DESC`);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="tamak_files.csv"');
    res.send(toCSV(result.rows));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/api/files/:id', requireAdmin, async (req, res) => {
  try {
    const result = await query('SELECT file_name FROM media_files WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Not found' });
    const filePath = path.join(__dirname, '../uploads', result.rows[0].file_name);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    await query('DELETE FROM media_files WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── Analytics ─────────────────────────────────────────────────────────────────
router.get('/api/analytics', requireAdmin, async (req, res) => {
  try {
    const [
      checkinsByDay, moodDist, smokeFreeByDay, cravingTrend,
      topSavers, goalsProgress, sosModeDist, genderDist,
      ageDist, planDist, checkinsPerUser, streakLeaderboard
    ] = await Promise.all([
      query(`SELECT DATE(check_in_date) as day, COUNT(*) as count FROM daily_checkins WHERE check_in_date >= NOW() - INTERVAL '30 days' GROUP BY day ORDER BY day`),
      query(`SELECT mood, COUNT(*) as count FROM daily_checkins WHERE mood IS NOT NULL GROUP BY mood ORDER BY count DESC`),
      query(`SELECT DATE(check_in_date) as day, COUNT(*) as smoke_free FROM daily_checkins WHERE smoked_today = false AND check_in_date >= NOW() - INTERVAL '30 days' GROUP BY day ORDER BY day`),
      query(`SELECT DATE(check_in_date) as day, ROUND(AVG(craving_level),1) as avg_craving FROM daily_checkins WHERE craving_level IS NOT NULL AND check_in_date >= NOW() - INTERVAL '30 days' GROUP BY day ORDER BY day`),
      query(`SELECT u.email, up.display_name, COALESCE(SUM(s.amount),0) as total_saved FROM savings_logs s LEFT JOIN user_profiles up ON s.user_id = up.id LEFT JOIN users u ON s.user_id = u.id GROUP BY u.email, up.display_name ORDER BY total_saved DESC LIMIT 10`),
      query(`SELECT is_completed, COUNT(*) as count FROM money_saver_goals GROUP BY is_completed`),
      query(`SELECT selected_mode, COUNT(*) as count FROM sos_logs GROUP BY selected_mode`),
      query(`SELECT gender, COUNT(*) as count FROM user_profiles WHERE gender IS NOT NULL GROUP BY gender`),
      query(`SELECT CASE WHEN age < 18 THEN 'Under 18' WHEN age BETWEEN 18 AND 25 THEN '18-25' WHEN age BETWEEN 26 AND 35 THEN '26-35' WHEN age BETWEEN 36 AND 50 THEN '36-50' ELSE '50+' END as age_group, COUNT(*) as count FROM user_profiles WHERE age IS NOT NULL GROUP BY age_group ORDER BY count DESC`),
      query(`SELECT plan_duration, COUNT(*) as count FROM user_profiles WHERE plan_duration IS NOT NULL GROUP BY plan_duration ORDER BY plan_duration`),
      query(`SELECT u.email, up.display_name, COUNT(c.id) as checkins FROM daily_checkins c LEFT JOIN user_profiles up ON c.user_id = up.id LEFT JOIN users u ON c.user_id = u.id GROUP BY u.email, up.display_name ORDER BY checkins DESC LIMIT 10`),
      query(`SELECT u.email, up.display_name, g.longest_streak, g.current_streak, g.total_xp, g.level FROM gamification_progress g LEFT JOIN user_profiles up ON g.user_id = up.id LEFT JOIN users u ON g.user_id = u.id ORDER BY g.longest_streak DESC LIMIT 10`),
    ]);
    res.json({
      checkins_by_day: checkinsByDay.rows,
      mood_distribution: moodDist.rows,
      smoke_free_by_day: smokeFreeByDay.rows,
      craving_trend: cravingTrend.rows,
      top_savers: topSavers.rows,
      goals_progress: goalsProgress.rows,
      sos_mode_dist: sosModeDist.rows,
      gender_distribution: genderDist.rows,
      age_distribution: ageDist.rows,
      plan_distribution: planDist.rows,
      top_checkin_users: checkinsPerUser.rows,
      streak_leaderboard: streakLeaderboard.rows,
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── DB Stats + Full Export ────────────────────────────────────────────────────
router.get('/api/db-stats', requireAdmin, async (req, res) => {
  try {
    const tables = ['users','user_profiles','daily_checkins','peer_support_messages','money_saver_goals','savings_logs','gamification_progress','user_mission_progress','wishlist_items','sos_logs','media_files'];
    const counts = await Promise.all(tables.map(t => query(`SELECT COUNT(*) as count FROM ${t}`).then(r => ({ table: t, count: parseInt(r.rows[0].count) }))));
    res.json({ tables: counts });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/api/export-all/csv', requireAdmin, async (req, res) => {
  // Export all tables as one big zip-style CSV (multi-section)
  try {
    const tables = {
      users: `SELECT u.id, u.email, u.created_at, CASE WHEN u.google_id IS NOT NULL THEN 'Google' ELSE 'Email' END as auth_type, up.display_name, up.age, up.gender, up.plan_duration, up.quit_date FROM users u LEFT JOIN user_profiles up ON u.id = up.id ORDER BY u.created_at DESC`,
      daily_checkins: `SELECT c.id, u.email, up.display_name, c.check_in_date, c.mood, c.craving_level, c.smoked_today, c.used_tobacco, c.cigarettes_smoked, c.created_at FROM daily_checkins c LEFT JOIN user_profiles up ON c.user_id = up.id LEFT JOIN users u ON c.user_id = u.id ORDER BY c.check_in_date DESC`,
      money_saver_goals: `SELECT g.id, u.email, up.display_name, g.title, g.target_amount, g.current_amount, g.is_completed, g.created_at FROM money_saver_goals g LEFT JOIN user_profiles up ON g.user_id = up.id LEFT JOIN users u ON g.user_id = u.id`,
      savings_logs: `SELECT s.id, u.email, up.display_name, s.amount, s.logged_at FROM savings_logs s LEFT JOIN user_profiles up ON s.user_id = up.id LEFT JOIN users u ON s.user_id = u.id`,
      gamification_progress: `SELECT u.email, up.display_name, g.level, g.total_xp, g.current_streak, g.longest_streak, g.badges FROM gamification_progress g LEFT JOIN user_profiles up ON g.user_id = up.id LEFT JOIN users u ON g.user_id = u.id ORDER BY g.total_xp DESC`,
      sos_logs: `SELECT s.id, u.email, up.display_name, s.selected_mode, s.distraction_clicked, s.trigger_time FROM sos_logs s LEFT JOIN user_profiles up ON s.user_id = up.id LEFT JOIN users u ON s.user_id = u.id`,
      wishlist_items: `SELECT w.id, u.email, up.display_name, w.item_name, w.target_amount, w.is_achieved, w.created_at FROM wishlist_items w LEFT JOIN user_profiles up ON w.user_id = up.id LEFT JOIN users u ON w.user_id = u.id`,
      peer_support_messages: `SELECT p.id, u.email, up.display_name, p.content, p.created_at FROM peer_support_messages p LEFT JOIN user_profiles up ON p.sender_id = up.id LEFT JOIN users u ON p.sender_id = u.id ORDER BY p.created_at DESC`,
      media_files: `SELECT mf.id, u.email, mf.file_name, mf.file_size_bytes, mf.mime_type, mf.url, mf.created_at FROM media_files mf LEFT JOIN users u ON mf.user_id = u.id`,
    };
    let output = '';
    for (const [name, sql] of Object.entries(tables)) {
      const result = await query(sql);
      output += `\n\n##### TABLE: ${name.toUpperCase()} (${result.rowCount} rows) #####\n`;
      output += toCSV(result.rows);
    }
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="tamak_full_export_${new Date().toISOString().slice(0,10)}.csv"`);
    res.send(output);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
