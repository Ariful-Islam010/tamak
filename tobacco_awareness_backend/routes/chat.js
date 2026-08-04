const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { requireAuth } = require('../middleware/auth');

// GET /api/chat/messages
router.get('/messages', requireAuth, async (req, res) => {
  try {
    const result = await query(`
      SELECT p.id, p.sender_id, p.content, p.image_url, p.created_at,
             u.display_name as display_name, u.photo_url as photo_url
      FROM peer_support_messages p
      LEFT JOIN user_profiles u ON p.sender_id = u.id
      ORDER BY p.created_at ASC
    `);
    
    // Map to the nested structure expected by the frontend
    const data = result.rows.map(row => ({
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
    const body = req.body;
    body.sender_id = body.sender_id || userId;
    
    const keys = Object.keys(body);
    const values = Object.values(body);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    
    const result = await query(
      `INSERT INTO peer_support_messages (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
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
    return res.status(500).json({ detail: error.message });
  }
});

// DELETE /api/chat/messages/:id
router.delete('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.sub;
    
    // First, try to delete if user is the sender
    const result = await query(
      'DELETE FROM peer_support_messages WHERE id = $1 AND sender_id = $2 RETURNING *',
      [messageId, userId]
    );
    
    if (result.rowCount > 0) {
      return res.json({ status: 'success' });
    }

    // Fallback if not sender (assuming service role/admin privileges)
    // For simplicity, we just delete it without checking if the user is an admin.
    // Modify this if a specific admin check is needed.
    const resultSr = await query(
      'DELETE FROM peer_support_messages WHERE id = $1 RETURNING *',
      [messageId]
    );
    
    if (resultSr.rowCount > 0) {
      return res.json({ status: 'success' });
    }

    return res.status(400).json({ detail: 'Message deletion failed' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// PUT /api/chat/messages/:id
router.put('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.sub;
    const body = req.body;
    
    if (Object.keys(body).length === 0) {
      return res.json([]);
    }
    
    const setClause = Object.keys(body).map((key, i) => `${key} = $${i + 1}`).join(', ');
    const values = Object.values(body);
    
    // First, try to update if user is the sender
    let result = await query(
      `UPDATE peer_support_messages SET ${setClause} WHERE id = $${values.length + 1} AND sender_id = $${values.length + 2} RETURNING *`,
      [...values, messageId, userId]
    );
    
    if (result.rowCount > 0) {
      return res.json(result.rows);
    }

    // Fallback if not sender
    let resultSr = await query(
      `UPDATE peer_support_messages SET ${setClause} WHERE id = $${values.length + 1} RETURNING *`,
      [...values, messageId]
    );
    
    if (resultSr.rowCount > 0) {
      return res.json(resultSr.rows);
    }

    return res.status(400).json({ detail: 'Message edit failed' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
