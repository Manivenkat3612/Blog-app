import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_theme.dart';
import '../../models/blog.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/comment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/comment_widget.dart';
import '../../widgets/comment_input.dart';
import '../../widgets/loading_widget.dart';

class BlogDetailScreen extends StatefulWidget {
  const BlogDetailScreen({super.key});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogController blogController = Get.find<BlogController>();
  late final CommentController commentController;
  final AuthController authController = Get.find<AuthController>();
  
  late String blogId;
  String? replyToCommentId;
  String? replyToName;

  @override
  void initState() {
    super.initState();
    blogId = Get.arguments as String;
    
    // Initialize CommentController properly
    if (Get.isRegistered<CommentController>()) {
      commentController = Get.find<CommentController>();
    } else {
      commentController = Get.put(CommentController());
    }
    
    _loadBlogDetails();
    commentController.fetchComments(blogId);
  }

  @override
  void dispose() {
    // Only clear comments, don't dispose the controller
    if (Get.isRegistered<CommentController>()) {
      try {
        final controller = Get.find<CommentController>();
        controller.clearComments();
      } catch (e) {
        print('Error clearing comments: $e');
      }
    }
    super.dispose();
  }

  void _loadBlogDetails() {
    // Find blog from controller's list and set it to selectedBlog
    final foundBlog = blogController.blogs.firstWhereOrNull(
      (b) => b.id == blogId,
    );
    if (foundBlog != null) {
      blogController.selectedBlog.value = foundBlog;
    }
  }

  Future<void> _toggleLike() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    await blogController.likeBlog(currentBlog.id);
    // The controller now properly updates the selectedBlog observable
  }

  Future<void> _toggleBookmark() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    await blogController.bookmarkBlog(currentBlog.id);
    // The controller now properly updates the selectedBlog observable
  }

  void _sharePost() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    // In a real app, you would implement proper sharing
    Get.snackbar('Share', 'Sharing functionality would be implemented here');
  }

  void _cancelReply() {
    setState(() {
      replyToCommentId = null;
      replyToName = null;
    });
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      replyToCommentId = commentId;
      replyToName = authorName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentBlog = blogController.selectedBlog.value;
      if (currentBlog == null) {
        return const Scaffold(
          body: LoadingWidget(),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Custom App Bar with blog image
            _buildAppBar(currentBlog),
            
            // Blog content and comments
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBlogContent(currentBlog),
                    _buildActionButtons(currentBlog),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
            
            // Comment input
            if (authController.isLoggedIn.value)
              CommentInput(
                blogId: blogId,
                parentId: replyToCommentId,
                replyToName: replyToName,
                onCancel: replyToCommentId != null ? _cancelReply : null,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAppBar(Blog currentBlog) {
    return Container(
      height: 300,
      child: Stack(
        children: [
          // Featured image
          if (currentBlog.featuredImage != null)
            Container(
              height: 250,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: currentBlog.featuredImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.grey200,
                  child: const LoadingWidget(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.grey200,
                  child: const Icon(Icons.image, size: 50),
                ),
              ),
            )
          else
            Container(
              height: 250,
              width: double.infinity,
              color: AppColors.primary,
            ),
          
          // Gradient overlay
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Back button and menu
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
                IconButton(
                  onPressed: _sharePost,
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Blog title at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                currentBlog.title,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogContent(Blog currentBlog) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info and date
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: currentBlog.author.avatar != null
                    ? CachedNetworkImageProvider(currentBlog.author.avatar!)
                    : null,
                child: currentBlog.author.avatar == null
                    ? Text(
                        currentBlog.author.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBlog.author.name,
                      style: AppTextStyles.h3,
                    ),
                    Text(
                      _formatDate(currentBlog.createdAt),
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tags
          if (currentBlog.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: currentBlog.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: AppTextStyles.caption,
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              )).toList(),
            ),
          
          if (currentBlog.tags.isNotEmpty) const SizedBox(height: 16),
          
          // Content
          Text(
            currentBlog.content,
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Blog currentBlog) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Like button
          Obx(() {
            final activeBlog = blogController.selectedBlog.value ?? currentBlog;
            return TextButton.icon(
              onPressed: _toggleLike,
              icon: Icon(
                activeBlog.isLiked ? Icons.favorite : Icons.favorite_border,
                color: activeBlog.isLiked ? Colors.red : AppColors.textSecondary,
              ),
              label: Text(
                '${activeBlog.likesCount}',
                style: AppTextStyles.body2,
              ),
            );
          }),
          
          // Comment count
          TextButton.icon(
            onPressed: null,
            icon: const Icon(
              Icons.comment_outlined,
              color: AppColors.textSecondary,
            ),
            label: Obx(() => Text(
              '${commentController.comments.length}',
              style: AppTextStyles.body2,
            )),
          ),
          
          const Spacer(),
          
          // Bookmark button
          Obx(() {
            final activeBlog = blogController.selectedBlog.value ?? currentBlog;
            return IconButton(
              onPressed: _toggleBookmark,
              icon: Icon(
                activeBlog.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: activeBlog.isBookmarked ? AppColors.primary : AppColors.textSecondary,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          Obx(() {
            if (commentController.isLoading.value) {
              return const LoadingWidget();
            }
            
            if (commentController.comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No comments yet',
                      style: AppTextStyles.body2,
                    ),
                    if (!authController.isLoggedIn.value) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Login to add a comment',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              );
            }
            
            return Column(
              children: commentController.comments.map((comment) => 
                CommentWidget(
                  comment: comment,
                  onReply: () => _startReply(comment.id, comment.author.name),
                  onDelete: () => _showDeleteDialog(comment.id),
                ),
              ).toList(),
            );
          }),
        ],
      ),
    );
  }

  void _showDeleteDialog(String commentId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              commentController.deleteComment(commentId, blogId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}