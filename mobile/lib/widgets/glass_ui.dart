import 'dart:ui';
import 'package:flutter/material.dart';

/// Shared glassmorphism utilities for the modern redesign.
class Glass {
  static Widget surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double radius = 28,
    Color? tint,
    double blur = 18,
    double opacity = .10,
    BorderSide? border,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: (tint ?? Colors.white).withValues(alpha: opacity),
              border: Border.fromBorderSide(border ?? BorderSide(color: Colors.white.withValues(alpha: .18))),
            ),
            child: child,
        ),
      ),
    );
  }

  static Widget frostedField({required Widget child, double radius = 18}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: .20)),
            ),
            child: child,
          ),
        ),
      );

  static InputDecoration inputDec(String hint, IconData? icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        border: InputBorder.none,
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      );

  static Widget gradientButton({
    required String label,
    required VoidCallback? onTap,
    double height = 54,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
    bool loading = false,
  }) => Opacity(
        opacity: onTap == null ? .55 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: .40), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .4)),
          ),
        ),
      );

  static BoxDecoration gradientBackground() => const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget blurCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class GlassScaffold extends StatelessWidget {
  final Widget child;
  final List<Widget> foreground;
  final bool safe;
  const GlassScaffold({super.key, required this.child, this.foreground = const [], this.safe = true});
  @override
  Widget build(BuildContext context) {
    final body = Stack(children: [
      Positioned.fill(child: Container(decoration: Glass.gradientBackground())),
  Positioned(top: -140, left: -90, child: Glass.blurCircle(260, const Color(0xFF6366F1).withValues(alpha: .28))),
  Positioned(bottom: -200, right: -120, child: Glass.blurCircle(360, const Color(0xFFEC4899).withValues(alpha: .25))),
      if (safe) SafeArea(child: child) else child,
      ...foreground,
    ]);
    return Scaffold(body: body);
  }
}