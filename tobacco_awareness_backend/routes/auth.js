const express = require('express');
const router = express.Router();
const { query } = require('../services/db');
const { hashPassword, verifyPassword, generateToken } = require('../services/auth');

// POST /api/auth/signup
router.post('/signup', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Check if user already exists
    const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rowCount > 0) {
      return res.status(400).json({ detail: 'User already exists' });
    }

    const hashedPassword = await hashPassword(password);
    const result = await query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email',
      [email, hashedPassword]
    );

    const user = result.rows[0];
    const token = generateToken(user);

    return res.json({ user, access_token: token });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/auth/signin
router.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const result = await query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rowCount === 0) {
      return res.status(400).json({ detail: 'Invalid credentials' });
    }

    const user = result.rows[0];
    const isValid = await verifyPassword(password, user.password_hash);
    if (!isValid) {
      return res.status(400).json({ detail: 'Invalid credentials' });
    }

    const token = generateToken(user);
    return res.json({ user: { id: user.id, email: user.email }, access_token: token });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/auth/signin-google
router.post('/signin-google', async (req, res) => {
  try {
    const { email, google_id } = req.body;
    
    let result = await query('SELECT * FROM users WHERE email = $1', [email]);
    let user;

    if (result.rowCount === 0) {
      // Create user if not exists
      const insertResult = await query(
        'INSERT INTO users (email, google_id) VALUES ($1, $2) RETURNING id, email',
        [email, google_id]
      );
      user = insertResult.rows[0];
    } else {
      user = result.rows[0];
      // Optionally update google_id if it was not set
    }

    const token = generateToken(user);
    return res.json({ user: { id: user.id, email: user.email }, access_token: token });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
