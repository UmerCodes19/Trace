import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// ─── Glassmorphic Card ───────────────────────────────────────────────────────
/// A frosted-glass container with backdrop blur, translucent fill, and subtle
/// border. Automatically adapts to light/dark mode.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blur = 16,
    this.opacity,
    this.borderGlow,
    this.elevation = 0,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double? opacity;
  final Color? borderGlow;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillOpacity = opacity ??
        (isDark ? 0.35 : 0.65);
    final fillColor = isDark
        ? AppColors.darkCard.withOpacity(fillOpacity)
        : Colors.white.withOpacity(fillOpacity);

    final borderColor = borderGlow ??
        (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.8));

    return Container(
      decoration: elevation > 0
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : AppColors.navyDarkest.withOpacity(0.06),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 2),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ─── Gradient Glass Card ─────────────────────────────────────────────────────
/// A glassmorphic card with a subtle gradient overlay.
class GradientGlassCard extends StatelessWidget {
  const GradientGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.gradientColors,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ??
        (isDark
            ? [
                AppColors.darkCard.withOpacity(0.5),
                AppColors.darkElevated.withOpacity(0.3),
              ]
            : [
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.4),
              ]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.7),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
