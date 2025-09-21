const express = require('express');
const { body, validationResult, query } = require('express-validator');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const Blog = require('../models/Blog');
const Comment = require('../models/Comment');
const { auth, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure multer for handling form data
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// Get all blogs with pagination, search, and filters
router.get('/', [
  optionalAuth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  query('search').optional().isLength({ max: 100 }).withMessage('Search query too long'),
  query('tags').optional().isLength({ max: 200 }).withMessage('Tags query too long'),
  query('category').optional().isLength({ max: 50 }).withMessage('Category query too long'),
  query('author').optional().isMongoId().withMessage('Invalid author ID')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const { search, tags, category, author, sortBy = 'createdAt', order = 'desc' } = req.query;

    // Build query
    const query = { status: 'published', isDeleted: false };

    if (search) {
      query.$text = { $search: search };
    }

    if (tags) {
      const tagArray = tags.split(',').map(tag => tag.trim().toLowerCase());
      query.tags = { $in: tagArray };
    }

    if (category) {
      query.category = category.toLowerCase();
      console.log('Filtering by category:', category.toLowerCase());
    }

    if (author) {
      query.author = author;
    }

    // Build sort object
    const sort = {};
    sort[sortBy] = order === 'asc' ? 1 : -1;

    const blogs = await Blog.find(query)
      .populate('author', 'name profilePicture bio')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();

    // Get comment counts for each blog
    const blogIds = blogs.map(blog => blog._id);
    const commentCounts = await Comment.aggregate([
      { $match: { blog: { $in: blogIds }, isDeleted: false } },
      { $group: { _id: '$blog', count: { $sum: 1 } } }
    ]);
    
    const commentCountMap = commentCounts.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    // Add user-specific data if authenticated
    const blogsWithUserData = blogs.map(blog => ({
      ...blog,
      isLiked: req.user ? blog.likes.some(like => like.user.toString() === req.user._id.toString()) : false,
      isBookmarked: req.user ? blog.bookmarks.some(bookmark => bookmark.user.toString() === req.user._id.toString()) : false,
      likeCount: blog.likes.length,
      bookmarkCount: blog.bookmarks.length,
      commentCount: commentCountMap[blog._id] || 0
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
    console.error('Get blogs error:', error);
    res.status(500).json({ error: 'Server error while fetching blogs' });
  }
});

// Get user's own blogs
router.get('/my-blogs', [
  auth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Find user's own blogs
    const blogs = await Blog.find({ 
      author: req.user._id, 
      isDeleted: false 
    })
    .populate('author', 'name profilePicture bio')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

    // Get comment counts for each blog
    const blogIds = blogs.map(blog => blog._id);
    const commentCounts = await Comment.aggregate([
      { $match: { blog: { $in: blogIds }, isDeleted: false } },
      { $group: { _id: '$blog', count: { $sum: 1 } } }
    ]);
    
    const commentCountMap = commentCounts.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    // Add user-specific data
    const blogsWithUserData = blogs.map(blog => ({
      ...blog,
      isLiked: blog.likes.some(like => like.user.toString() === req.user._id.toString()),
      isBookmarked: blog.bookmarks.some(bookmark => bookmark.user.toString() === req.user._id.toString()),
      likeCount: blog.likes.length,
      bookmarkCount: blog.bookmarks.length,
      commentCount: commentCountMap[blog._id] || 0
    }));

    const total = await Blog.countDocuments({ 
      author: req.user._id, 
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
    console.error('Get my blogs error:', error);
    res.status(500).json({ error: 'Server error while fetching my blogs' });
  }
});

// Get single blog by ID
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const blog = await Blog.findOne({ 
      _id: req.params.id, 
      status: 'published', 
      isDeleted: false 
    })
    .populate('author', 'name profilePicture bio');

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    // Get comment count for this blog
    const commentCount = await Comment.countDocuments({
      blog: req.params.id,
      isDeleted: false
    });

    // Increment view count
    blog.viewCount += 1;
    await blog.save();

    // Add user-specific data
    const blogData = {
      ...blog.toObject(),
      isLiked: req.user ? blog.isLikedBy(req.user._id) : false,
      isBookmarked: req.user ? blog.isBookmarkedBy(req.user._id) : false,
      likeCount: blog.likes.length,
      bookmarkCount: blog.bookmarks.length,
      commentCount: commentCount
    };

    res.json({ blog: blogData });
  } catch (error) {
    console.error('Get blog error:', error);
    res.status(500).json({ error: 'Server error while fetching blog' });
  }
});

// Create new blog
router.post('/', [
  auth,
  upload.single('featuredImage'), // Handle file upload
], async (req, res) => {
  try {
    // Extract data from FormData
    const { title, content, tags, excerpt, category } = req.body;
    
    // Manual validation
    const errors = [];
    
    if (!title || title.trim().length === 0 || title.trim().length > 100) {
      errors.push({ field: 'title', value: title, msg: 'Title must be between 1 and 100 characters', path: 'title', location: 'body' });
    }
    
    if (!content || content.trim().length === 0 || content.trim().length > 50000) {
      errors.push({ field: 'content', value: content, msg: 'Content must be between 1 and 50000 characters', path: 'content', location: 'body' });
    }
    
    if (!category || category.trim().length === 0) {
      errors.push({ field: 'category', value: category, msg: 'Category is required', path: 'category', location: 'body' });
    }
    
    if (errors.length > 0) {
      return res.status(400).json({ 
        success: false, 
        errors,
        message: 'Validation failed' 
      });
    }

    // Process tags
    let processedTags = [];
    if (tags) {
      if (typeof tags === 'string') {
        processedTags = tags.split(',').map(tag => tag.trim().toLowerCase()).filter(tag => tag.length > 0);
      } else if (Array.isArray(tags)) {
        processedTags = tags.map(tag => tag.toLowerCase());
      }
    }

    const blogData = {
      title: title.trim(),
      content: content.trim(),
      excerpt: excerpt ? excerpt.trim() : '',
      category: category.trim().toLowerCase(),
      author: req.user._id,
      tags: processedTags,
      status: 'published'
    };

    // Handle featured image if uploaded
    if (req.file) {
      try {
        // Upload image to Cloudinary
        const result = await new Promise((resolve, reject) => {
          cloudinary.uploader.upload_stream(
            {
              resource_type: 'image',
              folder: 'blog_images',
              transformation: [
                { width: 800, height: 600, crop: 'limit', quality: 'auto' }
              ]
            },
            (error, result) => {
              if (error) reject(error);
              else resolve(result);
            }
          ).end(req.file.buffer);
        });
        
        blogData.featuredImage = result.secure_url;
      } catch (uploadError) {
        console.error('Image upload error:', uploadError);
        // Continue without image if upload fails
        blogData.featuredImage = null;
      }
    }

    const blog = new Blog(blogData);
    await blog.save();
    await blog.populate('author', 'name profilePicture bio');

    res.status(201).json({
      success: true,
      message: 'Blog created successfully',
      data: {
        ...blog.toObject(),
        isLiked: false,
        isBookmarked: false,
        likeCount: 0,
        bookmarkCount: 0
      }
    });
  } catch (error) {
    console.error('Create blog error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Server error while creating blog',
      message: error.message 
    });
  }
});

// Update blog
router.put('/:id', [
  auth,
  body('title').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Title must be between 1 and 100 characters'),
  body('content').optional().trim().isLength({ min: 1, max: 50000 }).withMessage('Content must be between 1 and 50000 characters'),
  body('tags').optional().isArray({ max: 10 }).withMessage('Maximum 10 tags allowed'),
  body('tags.*').optional().trim().isLength({ min: 1, max: 20 }).withMessage('Each tag must be between 1 and 20 characters'),
  body('excerpt').optional().isLength({ max: 200 }).withMessage('Excerpt cannot exceed 200 characters'),
  body('featuredImage').optional().isURL().withMessage('Featured image must be a valid URL'),
  body('status').optional().isIn(['draft', 'published']).withMessage('Status must be draft or published')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const blog = await Blog.findOne({ _id: req.params.id, isDeleted: false });

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    // Check if user owns the blog
    if (blog.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'You can only edit your own blogs' });
    }

    const { title, content, tags, excerpt, featuredImage, status } = req.body;

    if (title) blog.title = title;
    if (content) blog.content = content;
    if (tags) blog.tags = tags.map(tag => tag.toLowerCase());
    if (excerpt !== undefined) blog.excerpt = excerpt;
    if (featuredImage !== undefined) blog.featuredImage = featuredImage;
    if (status) blog.status = status;

    await blog.save();
    await blog.populate('author', 'name profilePicture bio');

    res.json({
      message: 'Blog updated successfully',
      blog: {
        ...blog.toObject(),
        isLiked: blog.isLikedBy(req.user._id),
        isBookmarked: blog.isBookmarkedBy(req.user._id),
        likeCount: blog.likes.length,
        bookmarkCount: blog.bookmarks.length
      }
    });
  } catch (error) {
    console.error('Update blog error:', error);
    res.status(500).json({ error: 'Server error while updating blog' });
  }
});

// Delete blog
router.delete('/:id', auth, async (req, res) => {
  try {
    const blog = await Blog.findOne({ _id: req.params.id, isDeleted: false });

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    // Check if user owns the blog
    if (blog.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'You can only delete your own blogs' });
    }

    blog.isDeleted = true;
    await blog.save();

    res.json({ message: 'Blog deleted successfully' });
  } catch (error) {
    console.error('Delete blog error:', error);
    res.status(500).json({ error: 'Server error while deleting blog' });
  }
});

// Like/Unlike blog
router.post('/:id/like', auth, async (req, res) => {
  try {
    const blog = await Blog.findOne({ _id: req.params.id, status: 'published', isDeleted: false });

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    const userId = req.user._id;
    const isLiked = blog.isLikedBy(userId);

    if (isLiked) {
      blog.likes = blog.likes.filter(like => like.user.toString() !== userId.toString());
    } else {
      blog.likes.push({ user: userId });
    }

    await blog.save();

    res.json({
      message: isLiked ? 'Blog unliked' : 'Blog liked',
      isLiked: !isLiked,
      likeCount: blog.likes.length
    });
  } catch (error) {
    console.error('Like blog error:', error);
    res.status(500).json({ error: 'Server error while liking blog' });
  }
});

// Bookmark/Unbookmark blog
router.post('/:id/bookmark', auth, async (req, res) => {
  try {
    const blog = await Blog.findOne({ _id: req.params.id, status: 'published', isDeleted: false });

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    const userId = req.user._id;
    const isBookmarked = blog.isBookmarkedBy(userId);

    if (isBookmarked) {
      blog.bookmarks = blog.bookmarks.filter(bookmark => bookmark.user.toString() !== userId.toString());
    } else {
      blog.bookmarks.push({ user: userId });
    }

    await blog.save();

    res.json({
      message: isBookmarked ? 'Blog unbookmarked' : 'Blog bookmarked',
      isBookmarked: !isBookmarked,
      bookmarkCount: blog.bookmarks.length
    });
  } catch (error) {
    console.error('Bookmark blog error:', error);
    res.status(500).json({ error: 'Server error while bookmarking blog' });
  }
});

// Get blog comments
router.get('/:id/comments', [
  optionalAuth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const comments = await Comment.find({
      blog: req.params.id,
      parentComment: null, // Only top-level comments
      isDeleted: false
    })
    .populate('author', 'name profilePicture')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

    // Fetch replies for each comment
    const commentsWithReplies = await Promise.all(
      comments.map(async (comment) => {
        const replies = await Comment.find({
          blog: req.params.id,
          parentComment: comment._id,
          isDeleted: false
        })
        .populate('author', 'name profilePicture')
        .sort({ createdAt: 1 })
        .lean();

        return {
          ...comment,
          replies: replies || []
        };
      })
    );

    const total = await Comment.countDocuments({
      blog: req.params.id,
      parentComment: null,
      isDeleted: false
    });

    res.json({
      comments: commentsWithReplies,
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
    console.error('Get comments error:', error);
    res.status(500).json({ error: 'Server error while fetching comments' });
  }
});

// Add comment to blog
router.post('/:id/comments', [
  auth,
  body('content').trim().isLength({ min: 1, max: 1000 }).withMessage('Comment must be between 1 and 1000 characters'),
  body('parentComment').optional().isMongoId().withMessage('Invalid parent comment ID')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const blog = await Blog.findOne({ _id: req.params.id, status: 'published', isDeleted: false });

    if (!blog) {
      return res.status(404).json({ error: 'Blog not found' });
    }

    const { content, parentComment } = req.body;

    // If it's a reply, check if parent comment exists
    if (parentComment) {
      const parent = await Comment.findOne({ _id: parentComment, blog: req.params.id, isDeleted: false });
      if (!parent) {
        return res.status(404).json({ error: 'Parent comment not found' });
      }
    }

    const comment = new Comment({
      content,
      author: req.user._id,
      blog: req.params.id,
      parentComment: parentComment || null
    });

    await comment.save();
    await comment.populate('author', 'name profilePicture');

    res.status(201).json({
      message: 'Comment added successfully',
      comment
    });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ error: 'Server error while adding comment' });
  }
});

module.exports = router;