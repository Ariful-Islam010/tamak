const { verifyToken } = require('../services/auth');
const { query } = require('../services/db');

/**
 * Middleware that ensures a valid Authorization header is present, verifies the token,
 * and checks that the user account still exists in PostgreSQL database.
 */
async function requireAuth(req, res, next) {
  const authorization = req.headers['authorization'];
  if (!authorization) {
    return res.status(401).json({ detail: 'Missing Authorization Header' });
  }

  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : authorization;
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ detail: 'Invalid or Expired Token' });
  }

  try {
    const userCheck = await query('SELECT id FROM users WHERE id = $1', [decoded.sub]);
    if (userCheck.rowCount === 0) {
      return res.status(401).json({ detail: 'User account no longer exists. Please sign in again.' });
    }

    // Fallback integrity checks
    await query('INSERT INTO user_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING', [decoded.sub]);
    await query('INSERT INTO gamification_progress (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING', [decoded.sub]);
  } catch (err) {
    console.error('Error in requireAuth middleware:', err);
    return res.status(500).json({ detail: 'Database error checking auth user' });
  }

  req.user = decoded; // Will contain sub (id) and email
  next();
}

module.exports = { requireAuth };

