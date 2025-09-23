import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/user_controller.dart';
import '../../widgets/blog_card.dart';
import '../../widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final BlogController _blogController = Get.find<BlogController>();
  final UserController _userController = Get.find<UserController>();
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Handle initial tab from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['initialTab'] != null) {
        _tabController.animateTo(args['initialTab']);
      }
    });
    
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await _userController.fetchUserProfile();
    await _blogController.fetchMyBlogs();
    await _userController.fetchBookmarkedBlogs();
    await _userController.fetchUserStats();
  }

  // Show image picker for profile picture
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final imageUrl = await _userController.uploadAvatar(image.path);
        if (imageUrl != null) {
          Get.snackbar(
            'Success',
            'Profile picture updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
          // Reload user profile to show updated picture
          await _userController.fetchUserProfile();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile picture: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final user = _authController.currentUser.value;
        if (user == null) {
          return const Center(
            child: Text('Please login to view profile'),
          );
        }

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile Picture
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  backgroundImage: user.avatar != null
                                      ? CachedNetworkImageProvider(user.avatar!)
                                      : null,
                                  child: user.avatar == null
                                      ? Text(
                                          user.name.substring(0, 2).toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImagePicker,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Name and Email
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Bio
                            if (user.bio != null && user.bio!.isNotEmpty)
                              Text(
                                user.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Get.toNamed(AppRoutes.editProfile);
                          break;
                        case 'logout':
                          _showLogoutDialog();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Edit Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 12),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'My Blogs (${_blogController.myBlogs.length})'),
                      Tab(text: 'Bookmarks (${_userController.bookmarkedBlogs.length})'),
                      const Tab(text: 'Stats'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyBlogsTab(),
              _buildBookmarksTab(),
              _buildStatsTab(),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.createBlog);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyBlogsTab() {
    return Obx(() {
      if (_blogController.isLoading.value) {
        return const LoadingWidget(message: 'Loading your blogs...');
      }

      final myBlogs = _blogController.myBlogs;
      if (myBlogs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No blogs yet',
                style: AppTextStyles.h3,
              ),
              SizedBox(height: 8),
              Text(
                'Start writing your first blog post!',
                style: AppTextStyles.body2,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _blogController.fetchMyBlogs(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: myBlogs.length,
          itemBuilder: (context, index) {
            final blog = myBlogs[index];
            return BlogCard(
              blog: blog,
              onTap: () {
                Get.toNamed(AppRoutes.blogDetail, arguments: blog);
              },
              onLike: () => _blogController.likeBlog(blog.id),
              onBookmark: () => _blogController.bookmarkBlog(blog.id),
            );
          },
        ),
      );
    });
  }

  Widget _buildBookmarksTab() {
    return Obx(() {
      if (_userController.isLoading.value) {
        return const LoadingWidget(message: 'Loading bookmarked blogs...');
      }

      final bookmarkedBlogs = _userController.bookmarkedBlogs;
      if (bookmarkedBlogs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No bookmarks yet',
                style: AppTextStyles.h3,
              ),
              SizedBox(height: 8),
              Text(
                'Bookmark interesting blogs to read later!',
                style: AppTextStyles.body2,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _userController.fetchBookmarkedBlogs(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: bookmarkedBlogs.length,
          itemBuilder: (context, index) {
            final blog = bookmarkedBlogs[index];
            return BlogCard(
              blog: blog,
              onTap: () {
                Get.toNamed(AppRoutes.blogDetail, arguments: blog);
              },
              onLike: () => _blogController.likeBlog(blog.id),
              onBookmark: () => _blogController.bookmarkBlog(blog.id),
            );
          },
        ),
      );
    });
  }

  Widget _buildStatsTab() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final stats = _userController.userStats.value;
      if (user == null) return const SizedBox.shrink();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Blogs',
                    '${stats?.totalBlogs ?? _blogController.myBlogs.length}',
                    Icons.article,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Published',
                    '${stats?.publishedBlogs ?? 0}',
                    Icons.publish,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Likes',
                    '${stats?.totalLikes ?? 0}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bookmarks',
                    '${stats?.bookmarksCount ?? _userController.bookmarkedBlogs.length}',
                    Icons.bookmark,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Comments',
                    '${stats?.totalComments ?? 0}',
                    Icons.comment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Account Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Member Since', _formatDate(stats?.joinedDate ?? user.createdAt)),
                    _buildInfoRow('Recent Activity', '${stats?.recentActivity ?? 0} blogs this month'),
                    _buildInfoRow('Account Type', 'Free'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2),
          Text(value, style: AppTextStyles.body1),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            onPressed: () {
              Get.back();
              _authController.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}