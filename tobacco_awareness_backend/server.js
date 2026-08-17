const express = require('express');
const cors = require('cors');
const http = require('http');
const path = require('path');
const fs = require('fs');
const { Server } = require('socket.io');
const config = require('./config');

const authRouter = require('./routes/auth');
const profileRouter = require('./routes/profile');
const checkinsRouter = require('./routes/checkins');
const savingsRouter = require('./routes/savings');
const goalsRouter = require('./routes/goals');
const gamificationRouter = require('./routes/gamification');
const chatRouter = require('./routes/chat');
const uploadRouter = require('./routes/upload');
const aiRouter = require('./routes/ai');
const adminRouter = require('./admin');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', credentials: true }
});

// Pass io to all routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

io.on('connection', (socket) => {
  console.log('⚡ User connected to WebSocket:', socket.id);
  socket.on('disconnect', () => {
    console.log('⚡ User disconnected:', socket.id);
  });
});
// Core Middleware
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Tobacco Awareness Node.js / Express.js Backend is running 🚀' });
});

const rateLimit = require('express-rate-limit');

// Rate Limiters
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  message: { detail: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 login/signup attempts per 15 minutes
  message: { detail: 'Too many authentication attempts, please try again after 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const aiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // 30 AI generations per 15 minutes
  message: { detail: 'AI request limit reached. Please wait a few minutes before trying again.' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', globalLimiter);
app.use('/api/auth', authLimiter, authRouter);
app.use('/api/ai', aiLimiter, aiRouter);
app.use('/api/profile', profileRouter);
app.use('/api/checkins', checkinsRouter);
app.use('/api/savings', savingsRouter);
app.use('/api/goals', goalsRouter);
app.use('/api/gamification', gamificationRouter);
app.use('/api/chat', chatRouter);
// Serve uploaded images as static files
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
app.use('/uploads', express.static(uploadsDir));

app.use('/api/upload', uploadRouter);
app.use('/api/ai', aiRouter);

// Admin Dashboard & API Router
app.use('/admin', adminRouter);

server.listen(3000, '0.0.0.0', () => {
  console.log(`🚀 Express.js & Socket.io backend listening on port 3000`);
});

module.exports = server;
