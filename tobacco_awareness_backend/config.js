require('dotenv').config();
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

let jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) {
  const secretPath = path.join(__dirname, '.jwt_secret');
  if (fs.existsSync(secretPath)) {
    jwtSecret = fs.readFileSync(secretPath, 'utf8').trim();
  } else {
    jwtSecret = crypto.randomBytes(32).toString('hex');
    try {
      fs.writeFileSync(secretPath, jwtSecret, 'utf8');
    } catch (e) {
      console.warn('Could not write persistent .jwt_secret file:', e.message);
    }
  }
}

module.exports = {
  DATABASE_URL: process.env.DATABASE_URL || '',
  JWT_SECRET: jwtSecret,
  PORT: process.env.PORT || 8000,
  APP_ENV: process.env.APP_ENV || 'production',
  GROQ_API_KEY: process.env.GROQ_API_KEY || '',
  // Public URL of this backend — used to build upload URLs
  PUBLIC_URL: process.env.PUBLIC_URL || 'http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io',
  // Max upload storage in bytes (20 GB default)
  MAX_UPLOAD_STORAGE_BYTES: parseInt(process.env.MAX_UPLOAD_STORAGE_BYTES || '') || 20 * 1024 * 1024 * 1024,
};
