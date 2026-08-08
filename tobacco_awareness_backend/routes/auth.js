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
    await query('INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING', [user.id]);
    await query('INSERT INTO gamification_progress (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING', [user.id]);

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

    await query('INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING', [user.id]);
    await query('INSERT INTO gamification_progress (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING', [user.id]);

    const token = generateToken(user);
    return res.json({ user: { id: user.id, email: user.email }, access_token: token });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

const { OAuth2Client } = require('google-auth-library');
const googleClient = new OAuth2Client('82683276860-44b2sfnhnk66pq72blrlc4mesj841bu1.apps.googleusercontent.com');

// POST /api/auth/signin-google
router.post('/signin-google', async (req, res) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return res.status(400).json({ detail: 'Missing idToken' });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: '82683276860-44b2sfnhnk66pq72blrlc4mesj841bu1.apps.googleusercontent.com',
    });
    
    const payload = ticket.getPayload();
    const email = payload.email;
    const google_id = payload.sub; // Google's unique ID for the user

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
      if (!user.google_id) {
        await query('UPDATE users SET google_id = $1 WHERE id = $2', [google_id, user.id]);
      }
    }

    await query('INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING', [user.id]);
    await query('INSERT INTO gamification_progress (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING', [user.id]);

    const token = generateToken(user);
    return res.json({ user: { id: user.id, email: user.email }, access_token: token });
  } catch (error) {
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
