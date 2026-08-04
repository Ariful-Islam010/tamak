require('dotenv').config();

module.exports = {
  DATABASE_URL: process.env.DATABASE_URL || '',
  JWT_SECRET: process.env.JWT_SECRET || 'fallback_secret_for_development',
  PORT: process.env.PORT || 8000,
  APP_ENV: process.env.APP_ENV || 'production',
  GROQ_API_KEY: process.env.GROQ_API_KEY || '',
  // Public URL of this backend — used to build upload URLs
  PUBLIC_URL: process.env.PUBLIC_URL || 'http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io',
  // Max upload storage in bytes (500 MB default)
  MAX_UPLOAD_STORAGE_BYTES: parseInt(process.env.MAX_UPLOAD_STORAGE_BYTES || '') || 500 * 1024 * 1024,
};
