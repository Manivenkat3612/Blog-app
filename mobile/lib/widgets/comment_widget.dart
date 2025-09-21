import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment.dart';
import '../controllers/auth_controller.dart';
import '../constants/app_theme.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final int depth;

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReply,
    this.onDelete,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isCurrentUserComment = authController.currentUser.value?.id == comment.author.id;

    return Container(
      margin: EdgeInsets.only(
        left: depth * 20.0,
        bottom: 8.0,
      ),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: depth > 0 ? AppColors.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.author.avatar != null
                    ? CachedNetworkImageProvider(comment.author.avatar!)
                    : null,
                child: comment.author.avatar == null
                    ? Text(
                        comment.author.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (isCurrentUserComment && onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Comment content
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium,
          ),
          
          const SizedBox(height: 8),
          
          // Actions
          Row(
            children: [
              if (depth < 2 && onReply != null)
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(
                    Icons.reply,
                    size: 16,
                  ),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
          
          // Replies
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map((reply) => CommentWidget(
              comment: reply,
              depth: depth + 1,
              onReply: depth < 1 ? () => onReply?.call() : null,
              onDelete: isCurrentUserComment ? onDelete : null,
            )),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}