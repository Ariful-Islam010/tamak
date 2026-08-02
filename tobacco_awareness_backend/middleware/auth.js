/**
 * Middleware that ensures a valid Authorization header is present.
 */
function requireAuth(req, res, next) {
  const authorization = req.headers['authorization'];
  if (!authorization) {
    return res.status(401).json({ detail: 'Missing Authorization Header' });
  }
  req.token = authorization;
  next();
}

module.exports = { requireAuth };
