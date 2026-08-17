const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { uploadFile } = require('../services/storage');
const { requireAuth } = require('../middleware/auth');
const { query } = require('../services/db');
const config = require('../config');
const crypto = require('crypto');

// Calculate current total size of uploaded files via database
async function getUploadsDirSize() {
  try {
    const res = await query('SELECT COALESCE(SUM(file_size_bytes), 0) AS total FROM media_files');
    return parseInt(res.rows[0].total, 10);
  } catch (err) {
    return 0;
  }
}

// Multer — 10MB per file limit, memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
});

// POST /api/upload — upload an image
router.post('/', requireAuth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ detail: 'No file uploaded' });

    const fileExt = req.file.originalname.split('.').pop().toLowerCase();
    const allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    if (!allowedExts.includes(fileExt) && !req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({ detail: 'Only image files are allowed.' });
    }

    // Check total storage limit
    const currentSize = await getUploadsDirSize();
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

    // Record in database
    const userId = req.user.sub || req.user.id;
    await query(
      `INSERT INTO media_files (user_id, file_name, file_size_bytes, mime_type, url)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, randomName, req.file.size, mimetype, secure_url]
    );

    return res.json({ secure_url });
  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ detail: error.message || 'Image upload failed' });
  }
});

// GET /api/upload/files — list all uploaded files (with user info)
router.get('/files', requireAuth, async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const result = await query(
      `SELECT
         m.id,
         m.file_name,
         m.file_size_bytes,
         m.mime_type,
         m.url,
         m.created_at,
         u.display_name AS uploader
       FROM media_files m
       LEFT JOIN user_profiles u ON u.id = m.user_id
       ORDER BY m.created_at DESC
       LIMIT $1 OFFSET $2`,
      [parseInt(limit), offset]
    );

    const countResult = await query('SELECT COUNT(*) FROM media_files');
    const total = parseInt(countResult.rows[0].count);
    const totalStorageBytes = await getUploadsDirSize();

    return res.json({
      files: result.rows,
      pagination: { page: parseInt(page), limit: parseInt(limit), total },
      storage: {
        used_bytes: totalStorageBytes,
        used_mb: (totalStorageBytes / 1024 / 1024).toFixed(2),
        max_bytes: config.MAX_UPLOAD_STORAGE_BYTES,
        max_mb: Math.round(config.MAX_UPLOAD_STORAGE_BYTES / 1024 / 1024),
      },
    });
  } catch (error) {
    console.error('List files error:', error);
    return res.status(500).json({ detail: error.message });
  }
});

// DELETE /api/upload/files/:id — delete a file
router.delete('/files/:id', requireAuth, async (req, res) => {
  try {
    const userId = req.user.sub || req.user.id;
    const result = await query(
      'SELECT * FROM media_files WHERE id = $1 AND user_id = $2',
      [req.params.id, userId]
    );
    if (!result.rows.length) return res.status(404).json({ detail: 'File not found' });

    const file = result.rows[0];
    // Delete from filesystem
    const filePath = path.join(__dirname, '..', 'uploads', file.file_name);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    // Delete from DB
    await query('DELETE FROM media_files WHERE id = $1', [req.params.id]);
    return res.json({ message: 'File deleted' });
  } catch (error) {
    console.error('Delete file error:', error);
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;
