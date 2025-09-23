import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/comment_controller.dart';
import '../constants/app_theme.dart';

class CommentInput extends StatefulWidget {
  final String blogId;
  final String? parentId;
  final String? replyToName;
  final VoidCallback? onCancel;

  const CommentInput({
    super.key,
    required this.blogId,
    this.parentId,
    this.replyToName,
    this.onCancel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final CommentController _commentController = Get.find<CommentController>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      Get.snackbar('Error', 'Please enter a comment');
      return;
    }

    await _commentController.addComment(
      widget.blogId,
      content,
      parentId: widget.parentId,
    );

    _controller.clear();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyToName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Replying to ${widget.replyToName}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.parentId != null 
                  ? 'Write a reply...' 
                  : 'Write a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: AppColors.primary,
                ),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.parentId != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 8),
              Obx(
                () => ElevatedButton(
                  onPressed: _commentController.isPosting.value
                      ? null
                      : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: _commentController.isPosting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.parentId != null ? 'Reply' : 'Comment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}