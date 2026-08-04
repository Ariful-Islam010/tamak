const { verifyToken } = require('../services/auth');

/**
 * Middleware that ensures a valid Authorization header is present and verifies the token.
 */
function requireAuth(req, res, next) {
  const authorization = req.headers['authorization'];
  if (!authorization) {
    return res.status(401).json({ detail: 'Missing Authorization Header' });
  }

  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : authorization;
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ detail: 'Invalid or Expired Token' });
  }

  req.user = decoded; // Will contain sub (id) and email
  next();
}

module.exports = { requireAuth };
