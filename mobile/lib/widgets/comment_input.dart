import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/comment_controller.dart';
import '../constants/app_theme.dart';
import 'glass_ui.dart';

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
    return Glass.surface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14,12,14,10),
      tint: Colors.white,
      opacity: .30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyToName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  'Replying to ${widget.replyToName}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white60,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: _controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: Colors.white54, fontSize:13),
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.parentId != null) ...[
                TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
              ],
              Obx(
                () => ElevatedButton(
                  onPressed: _commentController.isPosting.value
                      ? null
                      : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal:16, vertical:10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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