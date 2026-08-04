const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { uploadFile } = require('../services/storage');
const { requireAuth } = require('../middleware/auth');
const config = require('../config');
const crypto = require('crypto');

// Calculate current total size of uploads directory
function getUploadsDirSize() {
  const uploadsDir = path.join(__dirname, '..', 'uploads');
  if (!fs.existsSync(uploadsDir)) return 0;
  return fs.readdirSync(uploadsDir).reduce((total, file) => {
    try {
      return total + fs.statSync(path.join(uploadsDir, file)).size;
    } catch { return total; }
  }, 0);
}

// Configure Multer — 10MB per file limit
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB per file
});

// POST /api/upload
router.post('/', requireAuth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ detail: 'No file uploaded' });
    }

    const fileExt = req.file.originalname.split('.').pop().toLowerCase();
    const allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];

    if (!allowedExts.includes(fileExt) && !req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({ detail: 'Only image files are allowed.' });
    }

    // Check total storage limit
    const currentSize = getUploadsDirSize();
    const maxBytes = config.MAX_UPLOAD_STORAGE_BYTES;
    if (currentSize + req.file.size > maxBytes) {
      const maxMB = Math.round(maxBytes / 1024 / 1024);
      return res.status(507).json({ detail: `Storage limit reached (max ${maxMB} MB).` });
    }

    const randomName = crypto.randomBytes(16).toString('hex') + '.' + fileExt;

    let mimetype = req.file.mimetype;
    if (!mimetype.startsWith('image/')) {
      mimetype = `image/${fileExt === 'jpg' ? 'jpeg' : fileExt}`;
    }

    const secure_url = await uploadFile(req.file.buffer, randomName, mimetype);
    return res.json({ secure_url });
  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ detail: error.message || 'Image upload failed' });
  }
});

module.exports = router;
