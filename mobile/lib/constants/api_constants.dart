class ApiConstants {
  // Base URL - Update this with your ngrok URL when running mobile demo
  // For local testing: http://localhost:3000/api
  // For ngrok: https://your-ngrok-url.ngrok.io/api
  // For same network: http://192.168.0.128:3000/api (your computer's IP)
  // Current ngrok URL: https://724c36e03118.ngrok-free.app/api (offline - using local IP)
  static const String baseUrl = 'http://192.168.0.128:3000/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String uploadProfilePicture = '/auth/upload-profile-picture';
  
  // Blog endpoints
  static const String blogs = '/blogs';
  static const String createBlog = '/blogs';
  static const String searchBlogs = '/blogs/search';
  static const String myBlogs = '/blogs/my-blogs';
  static const String likeBlog = '/blogs/{id}/like';
  static const String bookmarkBlog = '/blogs/{id}/bookmark';
  
  // User endpoints
  static const String users = '/users';
  static const String profile = '/auth/me';
  static const String userBlogs = '/users/{id}/blogs';
  static const String bookmarks = '/users/me/bookmarks';
  static const String userStats = '/users/me/stats';
  
  // Comment endpoints
  static const String comments = '/blogs/{blogId}/comments';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}