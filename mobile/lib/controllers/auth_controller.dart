import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../constants/app_routes.dart';
import 'user_controller.dart';
import 'blog_controller.dart';
import '../utils/logger.dart';

class AuthController extends GetxController {
  late final ApiService _apiService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '102213355298-j9aspooct2khjgo65tj7vs0bkdphgooi.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '102213355298-j9aspooct2khjgo65tj7vs0bkdphgooi.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  
  // Observable variables
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
    checkAuthStatus();
  }
  
  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null && token.isNotEmpty) {
        try {
          if (!Jwt.isExpired(token)) {
            await getCurrentUser();
            isLoggedIn.value = true;
            return;
          }
        } catch (e) {
          logDebug('JWT validation error: $e');
        }
      }
      
      // If no valid token, logout
      await logout();
    } catch (e) {
  logDebug('Error checking auth status: $e');
      await logout();
    }
  }
  
  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
  logDebug('Login response data: $data');
        
        if (data != null && data['token'] != null) {
          await _saveTokens(data['token'].toString(), data['refreshToken']?.toString());
          
          if (data['user'] != null) {
            currentUser.value = User.fromJson(data['user']);
          }
          
          isLoggedIn.value = true;
          
          // Navigate to home after successful login
          Get.offAllNamed(AppRoutes.home);
          return true;
        } else {
          error.value = 'Invalid response from server';
          return false;
        }
      }
      
      return false;
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
  logDebug('Login DioException: ${e.response?.data}');
      return false;
    } catch (e) {
      error.value = 'An unexpected error occurred: $e';
  logDebug('Login error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Register with email and password
  Future<bool> register(String email, String password, String name) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
  logDebug('Register response data: $data');
        
        if (data != null && data['token'] != null) {
          await _saveTokens(data['token'].toString(), data['refreshToken']?.toString());
          
          if (data['user'] != null) {
            currentUser.value = User.fromJson(data['user']);
          }
          
          isLoggedIn.value = true;
          
          // Navigate to home after successful registration
              Get.offAllNamed(AppRoutes.home);
          return true;
        } else {
          error.value = 'Invalid response from server';
          return false;
        }
      }
      
      return false;
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
  logDebug('Registration DioException: ${e.response?.data}');
      return false;
    } catch (e) {
      error.value = 'An unexpected error occurred: $e';
  logDebug('Registration error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        error.value = 'Failed to get Google ID token';
        return false;
      }
      
      final response = await _apiService.post(
        ApiConstants.googleAuth,
        data: {
          'idToken': googleAuth.idToken,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
  logDebug('Google auth response data: $data');
        
        if (data != null && data['token'] != null) {
          await _saveTokens(data['token'].toString(), data['refreshToken']?.toString());
          
          if (data['user'] != null) {
            currentUser.value = User.fromJson(data['user']);
          }
          
          isLoggedIn.value = true;
          
          // Navigate to home after successful Google sign-in
          Get.offAllNamed(AppRoutes.home);
          return true;
        } else {
          error.value = 'Invalid response from server';
          return false;
        }
      }
      
      return false;
    } on DioException catch (e) {
      error.value = _apiService.getErrorMessage(e);
  logDebug('Google SignIn DioException: ${e.response?.data}');
      return false;
    } catch (e) {
      error.value = 'Google sign in failed: $e';
  logDebug('Google SignIn error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get current user data
  Future<void> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      
      if (response.statusCode == 200) {
        currentUser.value = User.fromJson(response.data);
      }
    } catch (e) {
  logDebug('Error getting current user: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      // Call logout API
      await _apiService.post(ApiConstants.logout);
    } catch (e) {
  logDebug('Error calling logout API: $e');
    } finally {
      // Clear local data
      await _clearAuthData();
      currentUser.value = null;
      isLoggedIn.value = false;
      
      // Clear user controller data safely
      try {
        final userController = Get.find<UserController>();
        userController.clearUserData();
      } catch (e) {
  logDebug('UserController not found: $e');
      }
      
      // Clear blog controller data safely
      try {
        final blogController = Get.find<BlogController>();
        blogController.clearData();
      } catch (e) {
  logDebug('BlogController not found: $e');
      }
      
      // Sign out from Google safely
      try {
        await _googleSignIn.signOut();
      } catch (e) {
  logDebug('Error signing out from Google: $e');
      }
      
      // Navigate to login
  Get.offAllNamed(AppRoutes.login);
    }
  }
  
  // Save tokens to shared preferences
  Future<void> _saveTokens(String? token, String? refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
      }
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
    } catch (e) {
  logDebug('Error saving tokens: $e');
    }
  }
  
  // Clear authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }
  
  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.put(
        ApiConstants.profile,
        data: profileData,
      );
      
      if (response.statusCode == 200) {
        currentUser.value = User.fromJson(response.data);
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
  
  // Clear error
  void clearError() {
    error.value = '';
  }
}