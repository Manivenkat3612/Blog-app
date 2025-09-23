import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_routes.dart';
import '../../widgets/blog_card.dart';
import '../../widgets/loading_widget.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final BlogController _blogController = Get.put(BlogController());
  final AuthController _authController = Get.find<AuthController>();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _blogController.fetchBlogs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppRoutes.search),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'my_blogs',
                child: Row(
                  children: [
                    Icon(Icons.article),
                    SizedBox(width: 8),
                    Text('My Blogs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmark),
                    SizedBox(width: 8),
                    Text('Bookmarks'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          
          // Blog List
          Expanded(
            child: Obx(() {
              if (_blogController.isLoading.value && _blogController.blogs.isEmpty) {
                return const LoadingWidget();
              }

              if (_blogController.error.value.isNotEmpty && _blogController.blogs.isEmpty) {
                return _buildErrorWidget();
              }

              if (_blogController.blogs.isEmpty) {
                return _buildEmptyWidget();
              }

              return SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: true,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blogController.blogs.length,
                  itemBuilder: (context, index) {
                    final blog = _blogController.blogs[index];
                    return BlogCard(
                      blog: blog,
                      onTap: () => Get.toNamed(
                        AppRoutes.blogDetail,
                        arguments: blog.id,
                      ),
                      onLike: () => _blogController.likeBlog(blog.id),
                      onBookmark: () => _blogController.bookmarkBlog(blog.id),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.createBlog),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', ''),
          _buildCategoryChip('Technology', 'technology'),
          _buildCategoryChip('Lifestyle', 'lifestyle'),
          _buildCategoryChip('Business', 'business'),
          _buildCategoryChip('Health', 'health'),
          _buildCategoryChip('Travel', 'travel'),
          _buildCategoryChip('General', 'general'),
        ],
      )),
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    final isSelected = _blogController.selectedCategory.value == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _blogController.setCategory(category),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _blogController.error.value,
            style: AppTextStyles.body1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _blogController.clearError();
              _blogController.fetchBlogs(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No blogs found',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to write a blog!',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.createBlog),
            child: const Text('Write Blog'),
          ),
        ],
      ),
    );
  }

  void _onRefresh() async {
    await _blogController.fetchBlogs(refresh: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (_blogController.hasMorePages.value) {
      await _blogController.fetchBlogs();
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        Get.toNamed(AppRoutes.profile);
        break;
      case 'my_blogs':
        // Navigate to profile screen and show My Blogs tab
        Get.toNamed(AppRoutes.profile, arguments: {'initialTab': 0});
        break;
      case 'bookmarks':
        // Navigate to profile screen and show Bookmarks tab
        Get.toNamed(AppRoutes.profile, arguments: {'initialTab': 1});
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _authController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}