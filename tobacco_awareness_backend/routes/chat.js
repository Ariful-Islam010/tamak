const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/chat/messages
router.get('/messages', requireAuth, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 100);
    const offset = parseInt(req.query.offset || '0', 10);

    const result = await query(`
      SELECT p.id, p.sender_id, p.content, p.image_url, p.created_at,
             u.display_name as display_name, u.photo_url as photo_url
      FROM peer_support_messages p
      LEFT JOIN user_profiles u ON p.sender_id = u.id
      ORDER BY p.created_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

    // Reverse rows to return chronological ascending order for UI display
    const rowsAsc = result.rows.reverse();
    
    // Map to the nested structure expected by the frontend
    const data = rowsAsc.map(row => ({
      id: row.id,
      sender_id: row.sender_id,
      content: row.content,
      image_url: row.image_url,
      created_at: row.created_at,
      sender: {
        display_name: row.display_name,
        photo_url: row.photo_url
      }
    }));
    
    return res.json(data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/chat/messages
router.post('/messages', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub;
    const content = req.body.content != null ? String(req.body.content).trim() : '';
    const imageUrl = req.body.image_url || null;

    if (!content && !imageUrl) {
      return res.status(400).json({ detail: 'Message content or image is required' });
    }

    // Ensure user_profiles row exists to avoid foreign key violation
    await query(
      'INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING',
      [userId]
    );

    const result = await query(
      'INSERT INTO peer_support_messages (sender_id, content, image_url) VALUES ($1, $2, $3) RETURNING *',
      [userId, content, imageUrl]
    );

    const completeMessageResult = await query(`
      SELECT p.id, p.sender_id, p.content, p.image_url, p.created_at,
             u.display_name as display_name, u.photo_url as photo_url
      FROM peer_support_messages p
      LEFT JOIN user_profiles u ON p.sender_id = u.id
      WHERE p.id = $1
    `, [result.rows[0].id]);

    const row = completeMessageResult.rows[0];
    const newMessage = {
      id: row.id,
      sender_id: row.sender_id,
      content: row.content,
      image_url: row.image_url,
      created_at: row.created_at,
      sender: {
        display_name: row.display_name,
        photo_url: row.photo_url
      }
    };

    if (req.io) {
      req.io.emit('new_message', newMessage);
    }

    return res.json([newMessage]);
  } catch (error) {
    console.error('Error posting chat message:', error);
    return res.status(500).json({ detail: error.message });
  }
});

// GET /api/chat/user-profile/:id
router.get('/user-profile/:id', requireAuth, async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const profileResult = await query(
      `SELECT up.id, up.display_name, up.photo_url, up.created_at,
              gp.current_streak, gp.badges
       FROM user_profiles up
       LEFT JOIN gamification_progress gp ON up.id = gp.user_id
       WHERE up.id = $1`,
      [targetUserId]
    );

    if (profileResult.rowCount === 0) {
      return res.status(404).json({ detail: 'User profile not found' });
    }

    const row = profileResult.rows[0];
    return res.json({
      id: row.id,
      display_name: row.display_name || 'Anonymous User',
      photo_url: row.photo_url || null,
      current_streak: row.current_streak || 0,
      badges: row.badges || []
    });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/chat/report
router.post('/report', requireAuth, async (req, res) => {
  try {
    const reporterId = req.user.sub;
    const { reported_user_id, message_id, reason } = req.body;

    if (!reason) {
      return res.status(400).json({ detail: 'Reason is required' });
    }

    const result = await query(
      `INSERT INTO user_reports (reporter_id, reported_user_id, message_id, reason)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [reporterId, reported_user_id || null, message_id || null, reason]
    );

    return res.json({ status: 'success', report: result.rows[0] });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// DELETE /api/chat/messages/:id (User can only delete their own message)
router.delete('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.sub;
    
    const result = await query(
      'DELETE FROM peer_support_messages WHERE id = $1 AND sender_id = $2 RETURNING *',
      [messageId, userId]
    );
    
    if (result.rowCount > 0) {
      if (req.io) {
        req.io.emit('delete_message', { id: messageId });
      }
      return res.json({ status: 'success' });
    }

    return res.status(403).json({ detail: 'Message deletion failed or unauthorized' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// PUT /api/chat/messages/:id (User can only edit their own message)
router.put('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.sub;
    const { content } = req.body;
    
    if (!content || typeof content !== 'string') {
      return res.status(400).json({ detail: 'Content string is required' });
    }
    
    const result = await query(
      'UPDATE peer_support_messages SET content = $1 WHERE id = $2 AND sender_id = $3 RETURNING *',
      [content.trim(), messageId, userId]
    );
    
    if (result.rowCount > 0) {
      return res.json(result.rows[0]);
    }

    return res.status(403).json({ detail: 'Message edit failed or unauthorized' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
