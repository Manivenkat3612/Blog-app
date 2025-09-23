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
import '../controllers/auth_controller.dart';
import '../controllers/blog_controller.dart';
import '../controllers/user_controller.dart';

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
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const BlogListScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(BlogController());
        Get.put(UserController());
      }),
    ),
    GetPage(
      name: AppRoutes.blogDetail,
      page: () => const BlogDetailScreen(),
      binding: BindingsBuilder(() {
        Get.put(BlogController());
      }),
    ),
    GetPage(
      name: AppRoutes.createBlog,
      page: () => const CreateBlogScreen(),
      binding: BindingsBuilder(() {
        Get.put(BlogController());
      }),
    ),
    GetPage(
      name: AppRoutes.editBlog,
      page: () => const EditBlogScreen(),
      binding: BindingsBuilder(() {
        Get.put(BlogController());
      }),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.put(UserController());
      }),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(() {
        Get.put(UserController());
      }),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      binding: BindingsBuilder(() {
        Get.put(BlogController());
      }),
    ),
    GetPage(
      name: AppRoutes.userProfile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.put(UserController());
      }),
    ),
  ];
}