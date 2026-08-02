const express = require('express');
const router = express.Router();
const { supabaseReq } = require('../services/supabase');

// POST /api/auth/signup
router.post('/signup', async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await supabaseReq('POST', '/auth/v1/signup', {
      jsonData: { email, password },
    });
    if (!result.ok) {
      return res.status(result.status).json(result.data);
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/auth/signin
router.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await supabaseReq('POST', '/auth/v1/token?grant_type=password', {
      jsonData: { email, password },
    });
    if (!result.ok) {
      return res.status(result.status).json(result.data);
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/auth/signin-google
router.post('/signin-google', async (req, res) => {
  try {
    const { idToken, accessToken } = req.body;
    const body = { provider: 'google', id_token: idToken };
    if (accessToken) {
      body.access_token = accessToken;
    }
    const result = await supabaseReq('POST', '/auth/v1/token?grant_type=id_token', {
      jsonData: body,
    });
    if (!result.ok) {
      return res.status(result.status).json(result.data);
    }
    return res.json(result.data);
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
