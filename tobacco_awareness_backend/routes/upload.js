const express = require('express');
const router = express.Router();
const multer = require('multer');
const { uploadFile } = require('../services/storage');
const { requireAuth } = require('../middleware/auth');
const crypto = require('crypto');

// Configure Multer
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype && file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed.'));
    }
  },
});

// POST /api/upload
router.post('/', requireAuth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ detail: 'No file uploaded' });
    }

    const fileExt = req.file.originalname.split('.').pop();
    const randomName = crypto.randomBytes(16).toString('hex') + '.' + fileExt;

    const secure_url = await uploadFile(req.file.buffer, randomName, req.file.mimetype);
    return res.json({ secure_url });
  } catch (error) {
    console.error('Storage upload error:', error);
    return res.status(500).json({ detail: error.message || 'Image upload failed' });
  }
});

module.exports = router;
