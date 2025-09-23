import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment.dart';
import '../controllers/auth_controller.dart';
import '../constants/app_theme.dart';
import 'glass_ui.dart';

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
        left: depth * 16.0,
        bottom: 12.0,
      ),
      child: Glass.surface(
        padding: const EdgeInsets.fromLTRB(14,12,14,12),
        radius: 22,
        opacity: depth==0? .35 : .28,
        tint: Colors.white,
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
                        (comment.author.name.isNotEmpty
                                ? comment.author.name[0]
                                : '?')
                            .toUpperCase(),
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
          const SizedBox(height: 6),
          
          // Comment content
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          
          const SizedBox(height: 10),
          
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
                    foregroundColor: Colors.white70,
                    textStyle: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
          
          // Replies
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...comment.replies.map((reply) => CommentWidget(
              comment: reply,
              depth: depth + 1,
              onReply: depth < 1 ? () => onReply?.call() : null,
              onDelete: isCurrentUserComment ? onDelete : null,
            )),
          ],
          ],
        ),
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