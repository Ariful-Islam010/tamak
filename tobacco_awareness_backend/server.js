const express = require('express');
const cors = require('cors');
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

const app = express();

// Middleware
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Tobacco Awareness Node.js / Express.js Backend is running 🚀' });
});

// API Routers
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/checkins', checkinsRouter);
app.use('/api/savings', savingsRouter);
app.use('/api/goals', goalsRouter);
app.use('/api/gamification', gamificationRouter);
app.use('/api/chat', chatRouter);
app.use('/api/upload', uploadRouter);
app.use('/api/ai', aiRouter);

const PORT = config.PORT;

app.listen(PORT, () => {
  console.log(`🚀 Express.js & Next.js backend server listening on port ${PORT}`);
});

module.exports = app;
