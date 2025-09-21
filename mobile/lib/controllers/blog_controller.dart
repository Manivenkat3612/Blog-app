import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../models/blog.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import 'user_controller.dart';

class BlogController extends GetxController {
  late final ApiService _apiService;
  
  // Observable variables
  final RxList<Blog> blogs = <Blog>[].obs;
  final RxList<Blog> myBlogs = <Blog>[].obs;
  final RxList<Blog> searchResults = <Blog>[].obs;
  final RxList<Comment> comments = <Comment>[].obs;
  final Rx<Blog?> selectedBlog = Rx<Blog?>(null);
  
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;
  
  final RxInt currentPage = 1.obs;
  final RxBool hasMorePages = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    try {
      _apiService = Get.find<ApiService>();
      print('ApiService found successfully');
      fetchBlogs();
    } catch (e) {
      print('Error initializing BlogController: $e');
      error.value = 'Failed to initialize API service: $e';
    }
  }
  
  // Fetch blogs with pagination
  Future<void> fetchBlogs({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMorePages.value = true;
        blogs.clear();
      }
      
      if (refresh) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      
      error.value = '';
      
      print('Fetching blogs from: ${ApiConstants.blogs}');
      print('API Base URL: ${ApiConstants.baseUrl}');
      
      final response = await _apiService.get(
        ApiConstants.blogs,
        queryParameters: {
          'page': currentPage.value,
          'limit': 10,
          if (selectedCategory.value.isNotEmpty)
            'category': selectedCategory.value,
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> blogList = data['blogs'];
        final List<Blog> newBlogs = blogList.map((json) => Blog.fromJson(json)).toList();
        
        if (refresh) {
          blogs.assignAll(newBlogs);
        } else {
          blogs.addAll(newBlogs);
        }
        
        hasMorePages.value = data['hasMore'] ?? false;
        currentPage.value++;
      }
    } on dio.DioException catch (e) {
      print('DioException: ${e.message}');
      print('DioException type: ${e.type}');
      print('DioException response: ${e.response}');
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      print('General error: $e');
      error.value = 'Failed to fetch blogs: $e';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  
  // Search blogs
  Future<void> searchBlogs(String query) async {
    try {
      isSearching.value = true;
      searchQuery.value = query;
      error.value = '';
      
      if (query.isEmpty) {
        searchResults.clear();
        return;
      }
      
      final response = await _apiService.get(
        ApiConstants.searchBlogs,
        queryParameters: {
          'q': query,
          'limit': 20,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> blogList = response.data;
        searchResults.assignAll(blogList.map((json) => Blog.fromJson(json)));
      }
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Search failed';
    } finally {
      isSearching.value = false;
    }
  }
  
  // Get blog by ID
  Future<void> getBlogById(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get('${ApiConstants.blogs}/$id');
      
      if (response.statusCode == 200) {
        selectedBlog.value = Blog.fromJson(response.data);
        await fetchComments(id);
      }
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch blog details';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Fetch my blogs
  Future<void> fetchMyBlogs() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get(ApiConstants.myBlogs);
      
      if (response.statusCode == 200) {
        final List<dynamic> blogList = response.data['blogs'] ?? [];
        myBlogs.assignAll(blogList.map((json) => Blog.fromJson(json)));
      }
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch your blogs';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Create new blog
  Future<bool> createBlog(Map<String, dynamic> blogData) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.post(
        ApiConstants.blogs,
        data: blogData,
      );
      
      if (response.statusCode == 201) {
        final newBlog = Blog.fromJson(response.data);
        blogs.insert(0, newBlog);
        myBlogs.insert(0, newBlog);
        return true;
      }
      
      return false;
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to create blog';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update blog
  Future<bool> updateBlog(String id, Map<String, dynamic> blogData) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.put(
        '${ApiConstants.blogs}/$id',
        data: blogData,
      );
      
      if (response.statusCode == 200) {
        final updatedBlog = Blog.fromJson(response.data);
        
        // Update in blogs list
        final index = blogs.indexWhere((blog) => blog.id == id);
        if (index != -1) {
          blogs[index] = updatedBlog;
        }
        
        // Update in myBlogs list
        final myIndex = myBlogs.indexWhere((blog) => blog.id == id);
        if (myIndex != -1) {
          myBlogs[myIndex] = updatedBlog;
        }
        
        // Update selected blog
        if (selectedBlog.value?.id == id) {
          selectedBlog.value = updatedBlog;
        }
        
        return true;
      }
      
      return false;
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to update blog';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Delete blog
  Future<bool> deleteBlog(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.delete('${ApiConstants.blogs}/$id');
      
      if (response.statusCode == 200) {
        blogs.removeWhere((blog) => blog.id == id);
        myBlogs.removeWhere((blog) => blog.id == id);
        
        if (selectedBlog.value?.id == id) {
          selectedBlog.value = null;
        }
        
        return true;
      }
      
      return false;
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to delete blog';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Like blog
  Future<void> likeBlog(String id) async {
    try {
      print('Liking blog: $id'); // Debug logging
      final response = await _apiService.post(
        ApiConstants.likeBlog.replaceAll('{id}', id),
      );
      
      print('Like response status: ${response.statusCode}'); // Debug logging
      print('Like response data: ${response.data}'); // Debug logging
      
      if (response.statusCode == 200) {
        // Update the blog's like status in all lists
        _updateBlogLikeStatus(id, response.data);
        final message = response.data['message'] ?? 'Blog interaction updated';
        Get.snackbar('Success', message);
      } else {
        print('Like failed with status: ${response.statusCode}'); // Debug logging
        Get.snackbar('Error', 'Failed to like blog: HTTP ${response.statusCode}');
      }
    } on dio.DioException catch (e) {
      print('Like blog DioException: ${e.response?.statusCode} - ${e.response?.data}'); // Debug logging
      final errorMessage = _apiService.getErrorMessage(e);
      error.value = errorMessage;
      Get.snackbar('Error', 'Failed to like blog: $errorMessage');
    } catch (e) {
      print('Like blog general error: $e'); // Debug logging
      error.value = 'Failed to like blog';
      Get.snackbar('Error', 'Failed to like blog: $e');
    }
  }
  
  // Bookmark blog
  Future<void> bookmarkBlog(String id) async {
    try {
      print('Bookmarking blog: $id'); // Debug logging
      final response = await _apiService.post(
        ApiConstants.bookmarkBlog.replaceAll('{id}', id),
      );
      
      print('Bookmark response status: ${response.statusCode}'); // Debug logging
      print('Bookmark response data: ${response.data}'); // Debug logging
      
      if (response.statusCode == 200) {
        // Update the blog's bookmark status in all lists
        _updateBlogBookmarkStatus(id, response.data);
        
        // Refresh user's bookmarked blogs list
        final userController = Get.find<UserController>();
        userController.fetchBookmarkedBlogs();
        
        final message = response.data['message'] ?? 'Blog interaction updated';
        Get.snackbar('Success', message);
      } else {
        print('Bookmark failed with status: ${response.statusCode}'); // Debug logging
        Get.snackbar('Error', 'Failed to bookmark blog: HTTP ${response.statusCode}');
      }
    } on dio.DioException catch (e) {
      print('Bookmark blog DioException: ${e.response?.statusCode} - ${e.response?.data}'); // Debug logging
      final errorMessage = _apiService.getErrorMessage(e);
      error.value = errorMessage;
      Get.snackbar('Error', 'Failed to bookmark blog: $errorMessage');
    } catch (e) {
      print('Bookmark blog general error: $e'); // Debug logging
      error.value = 'Failed to bookmark blog';
      Get.snackbar('Error', 'Failed to bookmark blog: $e');
    }
  }
  
  // Fetch comments
  Future<void> fetchComments(String blogId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.comments.replaceAll('{blogId}', blogId),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> commentList = response.data;
        comments.assignAll(commentList.map((json) => Comment.fromJson(json)));
      }
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch comments';
    }
  }
  
  // Add comment
  Future<bool> addComment(String blogId, String content, {String? parentId}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.comments.replaceAll('{blogId}', blogId),
        data: {
          'content': content,
          if (parentId != null) 'parentId': parentId,
        },
      );
      
      if (response.statusCode == 201) {
        final newComment = Comment.fromJson(response.data);
        
        if (parentId == null) {
          comments.insert(0, newComment);
        } else {
          // Add as reply to parent comment
          final parentIndex = comments.indexWhere((c) => c.id == parentId);
          if (parentIndex != -1) {
            final parentComment = comments[parentIndex];
            final updatedReplies = [...parentComment.replies, newComment];
            comments[parentIndex] = parentComment.copyWith(replies: updatedReplies);
          }
        }
        
        // Update comment count in blog
        if (selectedBlog.value != null) {
          selectedBlog.value = selectedBlog.value!.copyWith(
            commentsCount: selectedBlog.value!.commentsCount + 1,
          );
        }
        
        return true;
      }
      
      return false;
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to add comment';
      return false;
    }
  }
  
  // Delete comment
  Future<bool> deleteComment(String blogId, String commentId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.comments.replaceAll('{blogId}', blogId)}/$commentId',
      );
      
      if (response.statusCode == 200) {
        comments.removeWhere((comment) => comment.id == commentId);
        
        // Update comment count in blog
        if (selectedBlog.value != null) {
          selectedBlog.value = selectedBlog.value!.copyWith(
            commentsCount: selectedBlog.value!.commentsCount - 1,
          );
        }
        
        return true;
      }
      
      return false;
    } on dio.DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to delete comment';
      return false;
    }
  }
  
  // Helper method to update blog like status in all lists
  void _updateBlogLikeStatus(String id, Map<String, dynamic> responseData) {
    final isLiked = responseData['isLiked'] ?? false;
    final likeCount = responseData['likeCount'] ?? 0;
    
    // Update in blogs list
    final index = blogs.indexWhere((blog) => blog.id == id);
    if (index != -1) {
      blogs[index] = blogs[index].copyWith(
        isLiked: isLiked,
        likesCount: likeCount,
      );
    }
    
    // Update in myBlogs list
    final myIndex = myBlogs.indexWhere((blog) => blog.id == id);
    if (myIndex != -1) {
      myBlogs[myIndex] = myBlogs[myIndex].copyWith(
        isLiked: isLiked,
        likesCount: likeCount,
      );
    }
    
    // Update selected blog
    if (selectedBlog.value?.id == id) {
      selectedBlog.value = selectedBlog.value!.copyWith(
        isLiked: isLiked,
        likesCount: likeCount,
      );
    }
    
    // Update in search results
    final searchIndex = searchResults.indexWhere((blog) => blog.id == id);
    if (searchIndex != -1) {
      searchResults[searchIndex] = searchResults[searchIndex].copyWith(
        isLiked: isLiked,
        likesCount: likeCount,
      );
    }
  }
  
  // Helper method to update blog bookmark status in all lists
  void _updateBlogBookmarkStatus(String id, Map<String, dynamic> responseData) {
    final isBookmarked = responseData['isBookmarked'] ?? false;
    
    // Update in blogs list
    final index = blogs.indexWhere((blog) => blog.id == id);
    if (index != -1) {
      blogs[index] = blogs[index].copyWith(
        isBookmarked: isBookmarked,
      );
    }
    
    // Update in myBlogs list
    final myIndex = myBlogs.indexWhere((blog) => blog.id == id);
    if (myIndex != -1) {
      myBlogs[myIndex] = myBlogs[myIndex].copyWith(
        isBookmarked: isBookmarked,
      );
    }
    
    // Update selected blog
    if (selectedBlog.value?.id == id) {
      selectedBlog.value = selectedBlog.value!.copyWith(
        isBookmarked: isBookmarked,
      );
    }
    
    // Update in search results
    final searchIndex = searchResults.indexWhere((blog) => blog.id == id);
    if (searchIndex != -1) {
      searchResults[searchIndex] = searchResults[searchIndex].copyWith(
        isBookmarked: isBookmarked,
      );
    }
  }

  // Create a new blog
  Future<void> createNewBlog({
    required String title,
    required String content,
    String? excerpt,
    required String category,
    required List<String> tags,
    dynamic featuredImage, // File or null
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Prepare form data
      dio.FormData formData = dio.FormData.fromMap({
        'title': title,
        'content': content,
        'excerpt': excerpt ?? '',
        'category': category,
        'tags': tags.join(','),
      });
      
      // Add featured image if provided
      if (featuredImage != null) {
        String fileName = featuredImage.path.split('/').last;
        formData.files.add(MapEntry(
          'featuredImage',
          await dio.MultipartFile.fromFile(
            featuredImage.path,
            filename: fileName,
          ),
        ));
      }
      
      final response = await _apiService.postData(
        ApiConstants.createBlog,
        formData,
        isFormData: true,
      );
      
      print('Blog creation response: $response'); // Debug log
      
      if (response['success'] == true && response['data'] != null) {
        final newBlog = Blog.fromJson(response['data']);
        blogs.insert(0, newBlog);
        myBlogs.insert(0, newBlog);
      } else if (response['errors'] != null) {
        // Handle validation errors
        final errors = response['errors'] as List;
        final errorMessages = errors.map((e) => e['msg']).join(', ');
        throw Exception(errorMessages);
      } else {
        throw Exception('Failed to create blog: ${response['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Set category filter
  void setCategory(String category) {
    selectedCategory.value = category;
    fetchBlogs(refresh: true);
  }
  
  // Clear error
  void clearError() {
    error.value = '';
  }
  
  // Clear all data
  void clearData() {
    blogs.clear();
    myBlogs.clear();
    searchResults.clear();
    comments.clear();
    selectedBlog.value = null;
    selectedCategory.value = '';
    searchQuery.value = '';
    currentPage.value = 1;
    hasMorePages.value = true;
    error.value = '';
    isLoading.value = false;
    isLoadingMore.value = false;
    isSearching.value = false;
  }
}
