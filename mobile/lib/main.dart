import 'package:flutter/material.dart';
import 'dart:ui' show PlatformDispatcher; // for global error hook
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants/app_theme.dart';
import 'constants/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/blog_controller.dart';
import 'controllers/user_controller.dart';
import 'services/api_service.dart';
import 'controllers/comment_controller.dart';
import 'firebase_options.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error hooks – logs and prevents silent failures
  FlutterError.onError = (details) {
    logDebug('FlutterError: \\n${details.exceptionAsString()}\\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logDebug('Platform error: $error\\n$stack');
    return true; // handled
  };
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logDebug('Firebase initialized successfully');
  } catch (e) {
    logDebug('Failed to initialize Firebase: $e');
    // Continue without Firebase - the app can still work without it
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Blog Platform',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      // Add localizations for Flutter Quill
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
  initialRoute: AppRoutes.splash,
  getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        // Guard against duplicate registration by checking isRegistered
        if(!Get.isRegistered<ApiService>()) {
          try { Get.put(ApiService(), permanent: true); } catch (e) { logDebug('Error initializing ApiService: $e'); }
        }
        if(!Get.isRegistered<AuthController>()) {
          try { Get.put(AuthController(), permanent: true); } catch (e) { logDebug('Error initializing AuthController: $e'); }
        }
        if(!Get.isRegistered<BlogController>()) {
          try { Get.put(BlogController(), permanent: true); } catch (e) { logDebug('Error initializing BlogController: $e'); }
        }
        if(!Get.isRegistered<UserController>()) {
          try { Get.put(UserController(), permanent: true); } catch (e) { logDebug('Error initializing UserController: $e'); }
        }
        // Lazy comment controller (created when first needed)
        if(!Get.isRegistered<CommentController>()) {
          Get.lazyPut<CommentController>(() => CommentController(), fenix: true);
        }
      }),
    );
  }
}
