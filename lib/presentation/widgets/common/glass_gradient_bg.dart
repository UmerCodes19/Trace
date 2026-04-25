import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class GlassGradientBg extends StatelessWidget {
  const GlassGradientBg({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final secondaryAccent = HSLColor.fromColor(accent)
        .withHue((HSLColor.fromColor(accent).hue + 60) % 360)
        .toColor();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Color
        Container(
          color: isDark ? const Color(0xFF0A0F1A) : const Color(0xFFF4F7FA),
        ),

        // Animated Orbs
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -150,
                left: -100,
                child: _buildOrb(accent, 450)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .move(
                      duration: const Duration(seconds: 12),
                      curve: Curves.easeInOutSine,
                      begin: const Offset(0, 0),
                      end: const Offset(150, 200),
                    ),
              ),
              Positioned(
                bottom: -200,
                right: -100,
                child: _buildOrb(secondaryAccent, 550)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .move(
                      duration: const Duration(seconds: 15),
                      curve: Curves.easeInOutSine,
                      begin: const Offset(0, 0),
                      end: const Offset(-200, -150),
                    ),
              ),
              Positioned(
                top: 300,
                left: -150,
                child: _buildOrb(AppColors.lostAlert, 350)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .move(
                      duration: const Duration(seconds: 18),
                      curve: Curves.easeInOutSine,
                      begin: const Offset(0, 0),
                      end: const Offset(250, -100),
                    ),
              ),
            ],
          ),
        ),

        // Heavy Blur for Glass Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Subtle tint overlay
        Positioned.fill(
          child: Container(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
          ),
        ),

        // Content
        child,
      ],
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.45),
      ),
    );
  }
}
