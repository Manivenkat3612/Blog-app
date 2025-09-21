// Migration script to add categories to existing blogs
const mongoose = require('mongoose');
const Blog = require('./models/Blog');

async function addCategoriesToExistingBlogs() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('Connected to MongoDB');

    // Find blogs without category field
    const blogsWithoutCategory = await Blog.find({ category: { $exists: false } });
    
    console.log(`Found ${blogsWithoutCategory.length} blogs without categories`);

    // Update each blog with a default category
    for (const blog of blogsWithoutCategory) {
      // Assign default category based on tags or use 'general'
      let category = 'general';
      
      if (blog.tags && blog.tags.length > 0) {
        const firstTag = blog.tags[0].toLowerCase();
        
        // Map common tags to categories
        const tagCategoryMap = {
          'technology': 'technology',
          'tech': 'technology',
          'lifestyle': 'lifestyle',
          'business': 'business',
          'health': 'health',
          'travel': 'travel',
          'food': 'lifestyle',
          'fashion': 'lifestyle',
          'sports': 'lifestyle',
          'education': 'business',
          'finance': 'business'
        };
        
        category = tagCategoryMap[firstTag] || 'general';
      }

      await Blog.findByIdAndUpdate(blog._id, { category });
      console.log(`Updated blog "${blog.title}" with category "${category}"`);
    }

    console.log('Migration completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  require('dotenv').config();
  addCategoriesToExistingBlogs();
}

module.exports = addCategoriesToExistingBlogs;