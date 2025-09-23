// Register Screen (Glassmorphism) - CLEAN FINAL VERSION
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _authController.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    if (ok) {
      Fluttertoast.showToast(msg: 'Account created!');
  Get.offAllNamed(AppRoutes.login);
    } else if (_authController.error.value.isNotEmpty) {
      Fluttertoast.showToast(msg: _authController.error.value);
    }
  }

  Future<void> _googleSignIn() async {
    final ok = await _authController.signInWithGoogle();
    if (ok) {
      Fluttertoast.showToast(msg: 'Welcome!');
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
          Positioned(top: -130, left: -70, child: _blurCircle(250, const Color(0xFF6366F1).withValues(alpha: .30))),
            Positioned(bottom: -170, right: -90, child: _blurCircle(340, const Color(0xFFEC4899).withValues(alpha: .28))),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final wide = c.maxWidth > 500;
                        final viewInsets = MediaQuery.of(context).viewInsets;
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: viewInsets.bottom + 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 28),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36),
                                      // Increase opacity for readability with black text
                                      color: Colors.white.withValues(alpha: .78),
                                      border: Border.all(color: Colors.white.withValues(alpha: .40)),
                                    ),
                                    child: wide
                                        ? Row(
                                            children: [
                                              Expanded(child: _sidePanel()),
                                              Container(width: 1, color: Colors.black.withValues(alpha: .08)),
                                              Expanded(child: _formArea()),
                                            ],
                                          )
                                        : _formArea(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _footer(),
                            ],
                          ),
                        );
                      },
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

  Widget _formArea() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 34),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.brush_rounded, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5, color: Colors.black)),
                        SizedBox(height: 6),
                        Text('Start shaping ideas into stories', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 34),
              _label('Full Name'),
              const SizedBox(height: 8),
              _frostedField(
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                  decoration: _input('Jane Doe', Icons.person_outline_rounded),
                  validator: (v) => (v != null && v.trim().length >= 2) ? null : 'Enter a valid name',
                ),
              ),
              const SizedBox(height: 20),
              _label('Email'),
              const SizedBox(height: 8),
              _frostedField(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                  decoration: _input('name@email.com', Icons.alternate_email_rounded),
                  validator: (v) => EmailValidator.validate(v ?? '') ? null : 'Invalid email',
                ),
              ),
              const SizedBox(height: 20),
              _label('Password'),
              const SizedBox(height: 8),
              _frostedField(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                  decoration: _input('••••••••', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.black54),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v != null && v.length >= 6) ? null : 'Min 6 characters',
                ),
              ),
              const SizedBox(height: 20),
              _label('Confirm Password'),
              const SizedBox(height: 8),
              _frostedField(
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                  decoration: _input('Repeat password', Icons.verified_user_outlined).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.black54),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v != null && v == _passwordController.text) ? null : 'Passwords do not match',
                ),
              ),
              const SizedBox(height: 30),
              Obx(() => _primaryButton(
                    _authController.isLoading.value ? 'Creating...' : 'Create Account',
                    _authController.isLoading.value ? null : _register,
                  )),
              const SizedBox(height: 18),
              _socialButton(icon: Icons.g_mobiledata, label: 'Continue with Google', onTap: _googleSignIn),
              const SizedBox(height: 26),
              Center(
                child: Wrap(
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.login),
                      child: const Text('Sign in', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sidePanel() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: .05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 30,
              left: 26,
              right: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text('Your creative journey starts here', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0x336366F1), Color(0x338B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, size: 96, color: Colors.black54),
                    ),
                    const SizedBox(height: 26),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        'Collaborate, draft, and publish with a focused toolset built for modern storytellers.',
                        style: TextStyle(color: Colors.black54, height: 1.4),
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

  Widget _footer() => Opacity(
        opacity: .75,
        child: Text(
          '© ${DateTime.now().year} Blog Studio • Create boldly',
          style: const TextStyle(color: Colors.black45, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _label(String text) => Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13, letterSpacing: .5, fontWeight: FontWeight.w600));

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        border: InputBorder.none,
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      );

  Widget _frostedField({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: .15)),
            ),
            child: child,
          ),
        ),
      );

  Widget _primaryButton(String label, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? .55 : 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: .4), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .4)),
          ),
        ),
      );

  Widget _socialButton({required IconData icon, required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: .10),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 30),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
