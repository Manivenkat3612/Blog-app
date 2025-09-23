const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth');
const blogRoutes = require('./routes/blogs');
const userRoutes = require('./routes/users');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// MongoDB connection with retry + state tracking
let mongoConnected = false;
const MAX_RETRIES = 5;
let attempts = 0;

async function connectMongo(){
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/blog_platform';
  try {
    await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });
    // Optional one‑time reset if explicitly requested (DO NOT use in production)
    if(process.env.DB_RESET_ON_START === 'true'){
      try {
        console.warn('[DB_RESET_ON_START] Dropping database to start fresh...');
        await mongoose.connection.dropDatabase();
        console.warn('[DB_RESET_ON_START] Database dropped successfully.');
      } catch(dropErr){
        console.error('[DB_RESET_ON_START] Failed to drop database:', dropErr.message);
      }
    }
    mongoConnected = true;
    console.log('MongoDB connected successfully');
  } catch (err){
    attempts += 1;
    mongoConnected = false;
    console.error(`MongoDB connection error (attempt ${attempts}/${MAX_RETRIES}):`, err.message);
    if(attempts < MAX_RETRIES){
      const backoff = Math.min(30000, 2000 * attempts);
      console.log(`Retrying MongoDB connection in ${backoff/1000}s...`);
      setTimeout(connectMongo, backoff);
    } else {
      console.log('Max MongoDB connection attempts reached. Running API in degraded mode (DB dependent routes will fail).');
    }
  }
}
connectMongo();

// Middleware to short‑circuit DB dependent routes when disconnected (avoid 10s buffering timeouts)
app.use((req,res,next)=>{
  if(!mongoConnected){
    // Allow only health and root paths so readiness probes still work
    if(req.path.startsWith('/api/health')) return next();
    return res.status(503).json({ error: 'Database unavailable', detail: 'MongoDB not connected', retry: true });
  }
  return next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/blogs', blogRoutes);
app.use('/api/users', userRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    message: 'Blog Platform API is running',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`API Health: http://localhost:${PORT}/api/health`);
});

module.exports = app;