const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { OAuth2Client } = require('google-auth-library');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure multer for memory storage
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d'
  });
};

// Register user
router.post('/register', [
  body('name').trim().isLength({ min: 2, max: 50 }).withMessage('Name must be between 2 and 50 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Please enter a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    // Create new user
    const user = new User({ name, email, password });
    await user.save();

    const token = generateToken(user._id);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
});

// Login user
router.post('/login', [
  body('email').isEmail().normalizeEmail().withMessage('Please enter a valid email'),
  body('password').exists().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // Find user and include password field
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    const token = generateToken(user._id);

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// Google OAuth login (supports multiple allowed client IDs)
router.post('/google', async (req, res) => {
  const { idToken } = req.body || {};
  if(!idToken){
    return res.status(400).json({ error: 'Missing idToken' });
  }

  // Support env var with comma separated list of client IDs
  const rawAud = process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || '';
  const allowedAudiences = rawAud.split(',').map(s=>s.trim()).filter(Boolean);
  if(allowedAudiences.length === 0){
    return res.status(500).json({ error: 'Server Google client ID not configured' });
  }
  try {
    let ticket;
    let lastErr;
    // Try each audience until one validates
    for(const aud of allowedAudiences){
      try {
        ticket = await googleClient.verifyIdToken({ idToken, audience: aud });
        break;
      } catch(verErr){
        lastErr = verErr;
      }
    }
    if(!ticket){
      console.error('Google auth verification failed for all audiences:', allowedAudiences, lastErr?.message || lastErr);
      return res.status(400).json({ error: 'Invalid Google token (audience mismatch)', details: lastErr?.message });
    }

    const payload = ticket.getPayload();
    if(!payload){
      return res.status(400).json({ error: 'Unable to decode Google token payload' });
    }

    const { sub: googleId, name, email, picture } = payload;
    if(!email){
      return res.status(400).json({ error: 'Google token missing email' });
    }

    // Find existing user or create new one
    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (user) {
      if (!user.googleId) {
        user.googleId = googleId;
        await user.save();
      }
    } else {
      user = new User({
        name: name || email.split('@')[0],
        email,
        googleId,
        profilePicture: picture,
        isEmailVerified: true
      });
      await user.save();
    }

    const token = generateToken(user._id);
    return res.json({
      message: 'Google authentication successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Google auth error (unexpected):', error);
    return res.status(400).json({ error: 'Google authentication failed', details: error.message });
  }
});

// Get current user
router.get('/me', auth, async (req, res) => {
  res.json({
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      bio: req.user.bio,
      profilePicture: req.user.profilePicture,
      role: req.user.role,
      createdAt: req.user.createdAt
    }
  });
});

// Simple logout endpoint (stateless JWT) - kept for client symmetry
// Since JWT is stateless we simply respond success; client clears tokens locally
router.post('/logout', auth, async (req, res) => {
  try {
    return res.json({ message: 'Logged out successfully' });
  } catch (e) {
    console.error('Logout error:', e);
    return res.status(500).json({ error: 'Logout failed' });
  }
});

// Upload profile picture
router.post('/upload-profile-picture', [auth, upload.single('profilePicture')], async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    // Upload to Cloudinary
    const uploadResult = await new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream(
        {
          resource_type: 'image',
          folder: 'blog_platform/profile_pictures',
          transformation: [
            { width: 300, height: 300, crop: 'fill' },
            { quality: 'auto' }
          ]
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      ).end(req.file.buffer);
    });

    // Update user profile picture
    const user = req.user;
    user.profilePicture = uploadResult.secure_url;
    await user.save();

    res.json({
      message: 'Profile picture uploaded successfully',
      profilePicture: uploadResult.secure_url
    });
  } catch (error) {
    console.error('Profile picture upload error:', error);
    res.status(500).json({ error: 'Failed to upload profile picture' });
  }
});

// Update user profile
router.put('/profile', [
  auth,
  body('name').optional().trim().isLength({ min: 2, max: 50 }).withMessage('Name must be between 2 and 50 characters'),
  body('bio').optional().isLength({ max: 500 }).withMessage('Bio cannot exceed 500 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, bio, profilePicture } = req.body;
    const user = req.user;

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (profilePicture) user.profilePicture = profilePicture;

    await user.save();

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ error: 'Server error during profile update' });
  }
});

module.exports = router;