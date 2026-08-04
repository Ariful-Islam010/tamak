require('dotenv').config();

module.exports = {
  DATABASE_URL: process.env.DATABASE_URL || '',
  MINIO_ENDPOINT: process.env.MINIO_ENDPOINT || '',
  MINIO_ACCESS_KEY: process.env.MINIO_ACCESS_KEY || '',
  MINIO_SECRET_KEY: process.env.MINIO_SECRET_KEY || '',
  MINIO_BUCKET_NAME: process.env.MINIO_BUCKET_NAME || 'tamak',
  JWT_SECRET: process.env.JWT_SECRET || 'fallback_secret_for_development',
  PORT: process.env.PORT || 8000,
  APP_ENV: process.env.APP_ENV || 'production',
};
