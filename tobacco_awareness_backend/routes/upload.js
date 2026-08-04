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
});

// POST /api/upload
router.post('/', requireAuth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ detail: 'No file uploaded' });
    }

    const fileExt = req.file.originalname.split('.').pop().toLowerCase();
    const allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    
    // Validate inside the controller after parsing
    if (!allowedExts.includes(fileExt) && !req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({ detail: 'Only image files are allowed.' });
    }

    const randomName = crypto.randomBytes(16).toString('hex') + '.' + fileExt;

    // If mimetype is missing or application/octet-stream, guess from extension
    let mimetype = req.file.mimetype;
    if (!mimetype.startsWith('image/')) {
      mimetype = `image/${fileExt === 'jpg' ? 'jpeg' : fileExt}`;
    }

    const secure_url = await uploadFile(req.file.buffer, randomName, mimetype);
    return res.json({ secure_url });
  } catch (error) {
    console.error('Storage upload error:', error);
    return res.status(500).json({ detail: error.message || 'Image upload failed' });
  }
});

module.exports = router;
