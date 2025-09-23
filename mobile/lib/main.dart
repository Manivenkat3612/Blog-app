import 'package:flutter/material.dart';
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
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        // Initialize ApiService first
        Get.put(ApiService());
        Get.put(AuthController());
        Get.put(BlogController());
        Get.put(UserController());
      }),
    );
  }
}
