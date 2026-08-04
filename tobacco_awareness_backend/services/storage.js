const fs = require('fs');
const path = require('path');
const config = require('../config');

const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');

// Ensure uploads directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

async function uploadFile(fileBuffer, fileName, mimetype) {
  const filePath = path.join(UPLOAD_DIR, fileName);
  fs.writeFileSync(filePath, fileBuffer);

  // Return public URL — served by Express static middleware at /uploads
  const base = (config.PUBLIC_URL || '').replace(/\/$/, '');
  return `${base}/uploads/${fileName}`;
}

async function deleteFile(fileName) {
  const filePath = path.join(UPLOAD_DIR, fileName);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
}

module.exports = {
  uploadFile,
  deleteFile,
};
