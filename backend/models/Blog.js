const mongoose = require('mongoose');

const blogSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Blog title is required'],
    trim: true,
    maxLength: [100, 'Title cannot exceed 100 characters']
  },
  content: {
    type: String,
    required: [true, 'Blog content is required'],
    maxLength: [50000, 'Content cannot exceed 50000 characters']
  },
  excerpt: {
    type: String,
    maxLength: [200, 'Excerpt cannot exceed 200 characters']
  },
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true,
    maxLength: [20, 'Tag cannot exceed 20 characters']
  }],
  category: {
    type: String,
    required: [true, 'Blog category is required'],
    trim: true,
    lowercase: true,
    maxLength: [30, 'Category cannot exceed 30 characters']
  },
  featuredImage: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['draft', 'published'],
    default: 'published'
  },
  likes: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  bookmarks: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  viewCount: {
    type: Number,
    default: 0
  },
  readTime: {
    type: Number, // in minutes
    default: 1
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for like count
blogSchema.virtual('likeCount').get(function() {
  return this.likes.length;
});

// Virtual for bookmark count
blogSchema.virtual('bookmarkCount').get(function() {
  return this.bookmarks.length;
});

// Virtual for comment count
blogSchema.virtual('commentCount', {
  ref: 'Comment',
  localField: '_id',
  foreignField: 'blog',
  count: true
});

// Calculate read time based on content length
blogSchema.pre('save', function(next) {
  if (this.isModified('content')) {
    const wordsPerMinute = 200;
    const words = this.content.split(/\s+/).length;
    this.readTime = Math.max(1, Math.ceil(words / wordsPerMinute));
    
    // Generate excerpt if not provided
    if (!this.excerpt) {
      const plainText = this.content.replace(/<[^>]*>/g, ''); // Remove HTML tags
      this.excerpt = plainText.substring(0, 150) + (plainText.length > 150 ? '...' : '');
    }
  }
  next();
});

// Indexes for better query performance
blogSchema.index({ author: 1, createdAt: -1 });
blogSchema.index({ tags: 1 });
blogSchema.index({ title: 'text', content: 'text', tags: 'text' });
blogSchema.index({ status: 1, isDeleted: 1, createdAt: -1 });

// Helper method to check if user liked the blog
blogSchema.methods.isLikedBy = function(userId) {
  return this.likes.some(like => like.user.toString() === userId.toString());
};

// Helper method to check if user bookmarked the blog
blogSchema.methods.isBookmarkedBy = function(userId) {
  return this.bookmarks.some(bookmark => bookmark.user.toString() === userId.toString());
};

module.exports = mongoose.model('Blog', blogSchema);