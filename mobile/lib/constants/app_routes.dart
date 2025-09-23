import 'package:get/get.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/blog/blog_list_screen.dart';
import '../screens/blog/blog_detail_screen.dart';
import '../screens/blog/create_blog_screen.dart';
import '../screens/blog/edit_blog_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/search/search_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String blogDetail = '/blog-detail';
  static const String createBlog = '/create-blog';
  static const String editBlog = '/edit-blog';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String search = '/search';
  static const String userProfile = '/user-profile';
}

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(name: AppRoutes.home, page: () => const BlogListScreen()),
    GetPage(name: AppRoutes.blogDetail, page: () => const BlogDetailScreen()),
    GetPage(name: AppRoutes.createBlog, page: () => const CreateBlogScreen()),
    GetPage(name: AppRoutes.editBlog, page: () => const EditBlogScreen()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: AppRoutes.search, page: () => const SearchScreen()),
    GetPage(name: AppRoutes.userProfile, page: () => const ProfileScreen()),
  ];
}