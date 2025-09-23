import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_routes.dart';
import '../../widgets/glass_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController pulse;
  late AnimationController rotate;

  @override
  void initState(){
    super.initState();
    pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    rotate = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _route();
  }

  Future<void> _route() async {
    final auth = Get.find<AuthController>();
    await Future.delayed(const Duration(milliseconds: 2400));
    if(auth.isLoggedIn.value){
  Get.offAllNamed(AppRoutes.home);
    } else {
  Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose(){
    pulse.dispose();
    rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      safe: false,
      child: Stack(
        children:[
          _blurOrb(const Offset(-80,-60), 260, const Color(0xFF6366F1).withValues(alpha: .35)),
          _blurOrb(const Offset(220,520), 300, const Color(0xFFEC4899).withValues(alpha: .30)),
          _blurOrb(const Offset(-120,480), 260, const Color(0xFF14B8A6).withValues(alpha: .25)),
          Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              AnimatedBuilder(
                animation: pulse,
                builder: (_, __){
                  final scale = 0.92 + pulse.value * 0.16;
                  return Transform.scale(
                    scale: scale,
                    child: _logo(),
                  );
                },
              ),
              const SizedBox(height: 26),
              const Text('Nebula Blog', style: TextStyle(color: Colors.white,fontSize:30,fontWeight: FontWeight.w800,letterSpacing: .5)),
              const SizedBox(height: 10),
              Text('Craft • Share • Inspire', style: TextStyle(color: Colors.white.withValues(alpha: .72),fontSize:14,fontWeight: FontWeight.w500, letterSpacing: .3)),
              const SizedBox(height: 60),
              _progressBar(),
            ],
          ))
        ],
      ),
    );
  }

  Widget _logo(){
    return AnimatedBuilder(
      animation: rotate,
      builder: (_, child){
        return Transform.rotate(
          angle: rotate.value * 2 * pi,
          child: child,
        );
      },
      child: Glass.surface(
        padding: EdgeInsets.zero,
        radius: 90,
        blur: 24,
        opacity: .20,
        child: SizedBox(
          width: 140, height: 140,
          child: Stack(
            fit: StackFit.expand,
            children:[
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors:[Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                ),
              ),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .10),
                        border: Border.all(color: Colors.white.withValues(alpha: .25)),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.edit_note_rounded, size: 64, color: Colors.white),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar(){
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __){
              return Container(
                height: 8,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  border: Border.all(color: Colors.white.withValues(alpha: .30)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: FractionallySizedBox(
                  widthFactor: pulse.value * .7 + .2,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors:[Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _blurOrb(Offset offset, double size, Color color){
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}