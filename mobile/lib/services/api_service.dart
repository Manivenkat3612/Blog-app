import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio();
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        print('API Log: $obj');
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh on 401
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final response = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }
  
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        await prefs.setString('auth_token', data['token']);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Generic request methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // GET request with data extraction
  Future<Map<String, dynamic>> getData(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(getErrorMessage(e));
      }
      rethrow;
    }
  }
  
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  // File upload
  Future<Response<T>> upload<T>(
    String path,
    File file, {
    Map<String, dynamic>? data,
    String fieldName = 'file',
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
      if (data != null) ...data,
    });
    
    return await _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }
  
  // POST request with form data support
  Future<Map<String, dynamic>> postData(
    String path, 
    dynamic data, {
    bool isFormData = false,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        onSendProgress: onSendProgress,
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(getErrorMessage(e));
      }
      rethrow;
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> deleteData(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(getErrorMessage(e));
      }
      rethrow;
    }
  }
  
  // Error handling
  String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        
        // Try to get error message from different response formats
        String? message;
        if (responseData is Map<String, dynamic>) {
          message = responseData['error'] ?? 
                   responseData['message'] ?? 
                   (responseData['errors'] is List ? 
                     (responseData['errors'] as List).join(', ') : null);
        }
        
        if (statusCode == 400) {
          return message ?? 'Bad request. Please check your input.';
        } else if (statusCode == 401) {
          return message ?? 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return message ?? 'An error occurred. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}