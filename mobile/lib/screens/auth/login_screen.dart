import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_routes.dart';

/// Completely redesigned login screen (glassmorphism + split panel)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _authController.login(_emailController.text.trim(), _passwordController.text);
    if (success) {
      Fluttertoast.showToast(msg: 'Welcome back!');
    } else if (_authController.error.value.isNotEmpty) {
      Fluttertoast.showToast(msg: _authController.error.value);
    }
  }

  Future<void> _googleSignIn() async {
    final success = await _authController.signInWithGoogle();
    if (success) {
      Fluttertoast.showToast(msg: 'Signed in with Google');
    } else if (_authController.error.value.isNotEmpty) {
      Fluttertoast.showToast(msg: _authController.error.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(top: -120, left: -80, child: _blurCircle(220, const Color(0xFF6366F1).withValues(alpha: .28))),
          Positioned(bottom: -140, right: -100, child: _blurCircle(300, const Color(0xFFEC4899).withValues(alpha: .25))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 430;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      color: Colors.white.withValues(alpha: .07),
                                      border: Border.all(color: Colors.white.withValues(alpha: .12)),
                                    ),
                                    child: isWide
                                        ? Row(
                                            children: [
                                              Expanded(child: _sidePanel()),
                                              Container(width: 1, color: Colors.white.withValues(alpha: .08)),
                                              Expanded(child: _formArea()),
                                            ],
                                          )
                                        : _formArea(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: .35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign in', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Access your creative workspace', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 40),
            _label('Email'),
            const SizedBox(height: 8),
            _frostedField(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                decoration: _inputDecoration('name@example.com', Icons.alternate_email_rounded),
                validator: (value) => EmailValidator.validate(value ?? '') ? null : 'Enter a valid email',
              ),
            ),
            const SizedBox(height: 20),
            _label('Password'),
            const SizedBox(height: 8),
            _frostedField(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v != null && v.length >= 6) ? null : 'Min 6 characters',
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot password?', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 8),
            _primaryButton('Sign In', _login),
            const SizedBox(height: 18),
            _socialButton(icon: Icons.g_mobiledata, label: 'Continue with Google', onTap: _googleSignIn),
            const SizedBox(height: 28),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text('New here? ', style: TextStyle(color: Colors.white70)),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.register),
                    child: const Text('Create an account', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sidePanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .15),
            Colors.white.withValues(alpha: .03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 30,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blog Studio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: .5)),
                SizedBox(height: 12),
                Text('Write. Share. Inspire.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replaced external asset (which was not in pubspec) with a safe placeholder icon for stability/tests
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0x336366F1), Color(0x338B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, size: 90, color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.0),
                    child: Text(
                      'Craft thoughtful stories with a distraction-free editor and reach an engaged community.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _footer() => Opacity(
        opacity: .75,
        child: Text(
          '© ${DateTime.now().year} Blog Studio • Crafted for creators',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );

  Widget _blurCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          letterSpacing: .5,
          fontWeight: FontWeight.w600,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        border: InputBorder.none,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      );

  Widget _frostedField({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .20)),
            ),
            child: child,
          ),
        ),
      );

  Widget _primaryButton(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: .4),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
            ),
          ),
        ),
      );

  Widget _socialButton({required IconData icon, required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: .10),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}