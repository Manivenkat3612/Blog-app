const express = require('express');
const { query } = require('express-validator');
const User = require('../models/User');
const Blog = require('../models/Blog');
const { auth, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get user profile by ID
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).populate('blogCount');

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = {
      id: user._id,
      name: user.name,
      email: req.user && req.user._id.toString() === user._id.toString() ? user.email : undefined,
      bio: user.bio,
      profilePicture: user.profilePicture,
      blogCount: user.blogCount,
      createdAt: user.createdAt
    };

    res.json({ user: profile });
  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({ error: 'Server error while fetching user profile' });
  }
});

// Get user's blogs
router.get('/:id/blogs', [
  optionalAuth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  query('status').optional().isIn(['draft', 'published']).withMessage('Invalid status')
], async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const { status = 'published' } = req.query;

    // Build query
    const query = { 
      author: req.params.id, 
      isDeleted: false 
    };

    // If viewing own profile, can see drafts
    if (req.user && req.user._id.toString() === req.params.id) {
      if (status) {
        query.status = status;
      }
    } else {
      query.status = 'published';
    }

    const blogs = await Blog.find(query)
      .populate('author', 'name profilePicture bio')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Add user-specific data if authenticated
    const blogsWithUserData = blogs.map(blog => ({
      ...blog,
      isLiked: req.user ? blog.likes.some(like => like.user.toString() === req.user._id.toString()) : false,
      isBookmarked: req.user ? blog.bookmarks.some(bookmark => bookmark.user.toString() === req.user._id.toString()) : false,
      likeCount: blog.likes.length,
      bookmarkCount: blog.bookmarks.length
    }));

    const total = await Blog.countDocuments(query);

    res.json({
      blogs: blogsWithUserData,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Get user blogs error:', error);
    res.status(500).json({ error: 'Server error while fetching user blogs' });
  }
});

// Get current user's bookmarked blogs
router.get('/me/bookmarks', [
  auth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50')
], async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const blogs = await Blog.find({
      'bookmarks.user': req.user._id,
      status: 'published',
      isDeleted: false
    })
    .populate('author', 'name profilePicture bio')
    .sort({ 'bookmarks.createdAt': -1 })
    .skip(skip)
    .limit(limit)
    .lean();

    // Get comment counts for each blog
    const Comment = require('../models/Comment');
    const blogIds = blogs.map(blog => blog._id);
    const commentCounts = await Comment.aggregate([
      { $match: { blog: { $in: blogIds }, isDeleted: false } },
      { $group: { _id: '$blog', count: { $sum: 1 } } }
    ]);
    
    const commentCountMap = commentCounts.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    const blogsWithUserData = blogs.map(blog => ({
      ...blog,
      isLiked: blog.likes.some(like => like.user.toString() === req.user._id.toString()),
      isBookmarked: true,
      likeCount: blog.likes.length,
      bookmarkCount: blog.bookmarks.length,
      commentCount: commentCountMap[blog._id] || 0
    }));

    const total = await Blog.countDocuments({
      'bookmarks.user': req.user._id,
      status: 'published',
      isDeleted: false
    });

    res.json({
      blogs: blogsWithUserData,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Get bookmarks error:', error);
    res.status(500).json({ error: 'Server error while fetching bookmarks' });
  }
});

// Search users
router.get('/search', [
  query('q').trim().isLength({ min: 1, max: 100 }).withMessage('Search query must be between 1 and 100 characters'),
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50')
], async (req, res) => {
  try {
    const { q } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } }
      ]
    })
    .select('name bio profilePicture createdAt')
    .populate('blogCount')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

    const total = await User.countDocuments({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } }
      ]
    });

    res.json({
      users,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({ error: 'Server error while searching users' });
  }
});

// Get user stats
router.get('/me/stats', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    // Get user's blog stats
    const blogStats = await Blog.aggregate([
      { $match: { author: userId, isDeleted: false } },
      {
        $group: {
          _id: null,
          totalBlogs: { $sum: 1 },
          publishedBlogs: { 
            $sum: { $cond: [{ $eq: ['$status', 'published'] }, 1, 0] }
          },
          draftBlogs: { 
            $sum: { $cond: [{ $eq: ['$status', 'draft'] }, 1, 0] }
          },
          totalLikes: { $sum: { $size: '$likes' } },
          totalComments: { $sum: '$commentCount' }
        }
      }
    ]);

    // Get bookmarks count - count blogs that user has bookmarked
    const bookmarksCount = await Blog.countDocuments({
      'bookmarks.user': userId,
      status: 'published',
      isDeleted: false
    });

    // Get recent activity (last 30 days)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const recentActivity = await Blog.countDocuments({
      author: userId,
      createdAt: { $gte: thirtyDaysAgo },
      isDeleted: false
    });

    const stats = blogStats[0] || {
      totalBlogs: 0,
      publishedBlogs: 0,
      draftBlogs: 0,
      totalLikes: 0,
      totalComments: 0
    };

    res.json({
      totalBlogs: stats.totalBlogs,
      publishedBlogs: stats.publishedBlogs,
      draftBlogs: stats.draftBlogs,
      totalLikes: stats.totalLikes,
      totalComments: stats.totalComments,
      bookmarksCount,
      recentActivity,
      joinedDate: req.user.createdAt
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({ error: 'Server error while fetching user stats' });
  }
});

module.exports = router;