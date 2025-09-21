// Quick script to update specific blogs with better categories
const mongoose = require('mongoose');
const Blog = require('./models/Blog');

async function updateBlogCategories() {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('Connected to MongoDB');

    // Update specific blogs with better categories
    const updates = [
      { title: 'facebook', category: 'technology' },
      { title: 'entrepreneur', category: 'business' },
      { title: 'hello', category: 'travel' } // This one has travel tag
    ];

    for (const update of updates) {
      const result = await Blog.findOneAndUpdate(
        { title: update.title },
        { category: update.category },
        { new: true }
      );
      
      if (result) {
        console.log(`Updated "${update.title}" to category "${update.category}"`);
      }
    }

    console.log('Category updates completed');
    process.exit(0);
  } catch (error) {
    console.error('Update failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  require('dotenv').config();
  updateBlogCategories();
}