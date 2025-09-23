// LEGACY SCREEN: This "ModernLoginScreen" is deprecated and superseded by the new glass
// design implemented in `login_screen.dart`. It remains temporarily only to avoid
// route breakages if something still references it. Remove after confirming no routes
// or deep links point here.
import 'package:flutter/material.dart';
class ModernLoginScreen extends StatelessWidget {
  const ModernLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => throw UnsupportedError('ModernLoginScreen removed. Use LoginScreen instead.');
}