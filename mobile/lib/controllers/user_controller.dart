import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/blog.dart';
import '../models/user_stats.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class UserController extends GetxController {
  late final ApiService _apiService;
  
  // Observable variables
  final Rx<User?> profileUser = Rx<User?>(null);
  final RxList<Blog> userBlogs = <Blog>[].obs;
  final RxList<Blog> bookmarkedBlogs = <Blog>[].obs;
  final Rx<UserStats?> userStats = Rx<UserStats?>(null);
  
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }
  
  // Get user profile by ID
  Future<void> getUserProfile(String userId) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get('${ApiConstants.users}/$userId');
      
      if (response.statusCode == 200) {
        profileUser.value = User.fromJson(response.data);
        await getUserBlogs(userId);
      }
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch user profile';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get user's blogs
  Future<void> getUserBlogs(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userBlogs.replaceAll('{id}', userId),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> blogList = response.data;
        userBlogs.assignAll(blogList.map((json) => Blog.fromJson(json)));
      }
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch user blogs';
    }
  }
  
  // Get bookmarked blogs
  Future<void> getBookmarkedBlogs() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get(ApiConstants.bookmarks);
      
      if (response.statusCode == 200) {
        final List<dynamic> blogList = response.data['blogs'] ?? [];
        bookmarkedBlogs.assignAll(blogList.map((json) => Blog.fromJson(json)));
      }
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch bookmarked blogs';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? avatar,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (avatar != null) data['avatar'] = avatar;
      
      final response = await _apiService.put(
        ApiConstants.profile,
        data: data,
      );
      
      if (response.statusCode == 200) {
        profileUser.value = User.fromJson(response.data);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return false;
    } catch (e) {
      error.value = 'Failed to update profile';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Upload avatar
  Future<String?> uploadAvatar(String imagePath) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.upload(
        ApiConstants.uploadProfilePicture,
        File(imagePath),
        fieldName: 'profilePicture',
      );
      
      if (response.statusCode == 200) {
        final imageUrl = response.data['profilePicture'];
        
        // Update profile with new avatar
        if (profileUser.value != null) {
          profileUser.value = profileUser.value!.copyWith(avatar: imageUrl);
        }
        
        return imageUrl;
      }
      
      return null;
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
      return null;
    } catch (e) {
      error.value = 'Failed to upload avatar';
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Fetch current user profile
  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get(ApiConstants.profile);
      
      if (response.statusCode == 200) {
        profileUser.value = User.fromJson(response.data);
      }
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch user profile';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Fetch bookmarked blogs (alias for getBookmarkedBlogs)
  Future<void> fetchBookmarkedBlogs() async {
    await getBookmarkedBlogs();
  }
  
  // Fetch user stats
  Future<void> fetchUserStats() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.get(ApiConstants.userStats);
      
      if (response.statusCode == 200) {
        userStats.value = UserStats.fromJson(response.data);
      }
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
    } catch (e) {
      error.value = 'Failed to fetch user stats';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Clear error
  void clearError() {
    error.value = '';
  }
  
  // Clear user data
  void clearUserData() {
    profileUser.value = null;
    userBlogs.clear();
    bookmarkedBlogs.clear();
    userStats.value = null;
    isLoading.value = false;
    error.value = '';
  }
}