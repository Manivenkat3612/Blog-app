import 'package:get/get.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

class CommentController extends GetxController {
  late final ApiService _apiService;

  final RxList<Comment> comments = <Comment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPosting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  Future<void> fetchComments(String blogId) async {
    try {
      isLoading.value = true;
      print('Fetching comments for blog: $blogId'); // Debug logging
      final response = await _apiService.getData('/blogs/$blogId/comments');
      print('Comments response: $response'); // Debug logging
      
      if (response['comments'] != null) {
        final commentList = (response['comments'] as List)
            .map((comment) => Comment.fromJson(comment))
            .toList();
        comments.assignAll(commentList); // Use assignAll to force update
        print('Successfully parsed ${commentList.length} comments'); // Debug logging
      } else {
        comments.assignAll([]); // Use assignAll to force update
        print('No comments found in response'); // Debug logging
      }
    } catch (e) {
      print('Fetch comments error: $e'); // Debug logging
      Get.snackbar('Error', 'Failed to fetch comments: $e');
      comments.assignAll([]); // Use assignAll to force update
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment(String blogId, String content, {String? parentId}) async {
    try {
      isPosting.value = true;
      print('Adding comment to blog: $blogId with content: $content'); // Debug logging
      final response = await _apiService.postData('/blogs/$blogId/comments', {
        'content': content,
        if (parentId != null) 'parentComment': parentId,
      });
      print('Add comment response: $response'); // Debug logging
      
      if (response.isNotEmpty) {
        Get.snackbar('Success', 'Comment added successfully');
        // Force refresh comments after adding
        await fetchComments(blogId);
        print('Comments count after refresh: ${comments.length}'); // Debug logging
      }
    } catch (e) {
      print('Add comment error: $e'); // Debug logging
      Get.snackbar('Error', 'Failed to add comment: $e');
    } finally {
      isPosting.value = false;
    }
  }

  Future<void> deleteComment(String commentId, String blogId) async {
    try {
      final response = await _apiService.deleteData('/comments/$commentId');
      
      if (response['success']) {
        // Refresh comments after deleting
        await fetchComments(blogId);
        Get.snackbar('Success', 'Comment deleted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment: $e');
    }
  }

  void clearComments() {
    comments.clear();
  }
}