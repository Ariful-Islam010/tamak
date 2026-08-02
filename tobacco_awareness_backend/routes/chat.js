const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');
const { requireAuth } = require('../middleware/auth');

// GET /api/chat/messages
router.get('/messages', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq(
      'GET',
      '/rest/v1/peer_support_messages?select=id,sender_id,content,image_url,created_at,sender:user_profiles(display_name,photo_url)&order=created_at.asc',
      { token: req.token }
    );
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/chat/messages
router.post('/messages', requireAuth, async (req, res) => {
  try {
    const result = await supabaseReq('POST', '/rest/v1/peer_support_messages', {
      token: req.token,
      jsonData: req.body,
    });
    if (!result.ok) {
      return res.status(result.status).json({ detail: result.text });
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// DELETE /api/chat/messages/:id
router.delete('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    // Attempt deletion using user token first
    const result = await supabaseReq('DELETE', `/rest/v1/peer_support_messages?id=eq.${messageId}`, {
      token: req.token,
    });
    if (result.ok && Array.isArray(result.data) && result.data.length > 0) {
      return res.json({ status: 'success' });
    }

    // Fallback to service role
    const resultSr = await supabaseReq('DELETE', `/rest/v1/peer_support_messages?id=eq.${messageId}`, {
      token: req.token,
      useServiceRole: true,
    });
    if (resultSr.ok) {
      return res.json({ status: 'success' });
    }

    return res.status(resultSr.status || 400).json({ detail: resultSr.text || 'Message deletion failed' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// PUT /api/chat/messages/:id
router.put('/messages/:id', requireAuth, async (req, res) => {
  try {
    const messageId = req.params.id;
    const result = await supabaseReq('PATCH', `/rest/v1/peer_support_messages?id=eq.${messageId}`, {
      token: req.token,
      jsonData: req.body,
    });
    if (result.ok) {
      const data = result.data;
      if (Array.isArray(data) && data.length > 0) {
        return res.json(data);
      }
    }

    // Service role fallback
    const resultSr = await supabaseReq('PATCH', `/rest/v1/peer_support_messages?id=eq.${messageId}`, {
      token: req.token,
      jsonData: req.body,
      useServiceRole: true,
    });
    if (resultSr.ok) {
      return res.json(resultSr.data);
    }

    return res.status(resultSr.status || 400).json({ detail: resultSr.text || 'Message edit failed' });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
