import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// ─── Animated Gradient Background ────────────────────────────────────────────
/// A slowly-animating mesh gradient for page backgrounds.
class AnimatedGradientBg extends StatefulWidget {
  const AnimatedGradientBg({
    super.key,
    this.child,
    this.intensity = 1.0,
  });

  final Widget? child;
  final double intensity;

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        final colors = isDark
            ? [
                Color.lerp(
                  const Color(0xFF0A0A14),
                  const Color(0xFF0E0E24),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF0F1028),
                  const Color(0xFF120D20),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF14102A),
                  const Color(0xFF0D1020),
                  t,
                )!,
              ]
            : [
                Color.lerp(
                  const Color(0xFFF5F0EB),
                  const Color(0xFFF0EAE2),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFFF0E8E0),
                  const Color(0xFFF5EDE5),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFFF5EDE5),
                  const Color(0xFFF5F0EB),
                  t,
                )!,
              ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.topCenter,
                t,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.bottomCenter,
                t,
              )!,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ─── Animated Profile Gradient ───────────────────────────────────────────────
/// A darker, richer gradient for profile/header backgrounds with accent tinting.
class AnimatedProfileGradient extends StatefulWidget {
  const AnimatedProfileGradient({
    super.key,
    required this.child,
    this.accent,
  });

  final Widget child;
  final Color? accent;

  @override
  State<AnimatedProfileGradient> createState() =>
      _AnimatedProfileGradientState();
}

class _AnimatedProfileGradientState extends State<AnimatedProfileGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.navyDarkest;
    final accentHSL = HSLColor.fromColor(accent);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        final color1 = accentHSL
            .withLightness((accentHSL.lightness * 0.7).clamp(0.0, 1.0))
            .withHue((accentHSL.hue - 10 * t) % 360)
            .toColor();

        final color2 = accentHSL
            .withLightness((accentHSL.lightness * 0.5).clamp(0.0, 1.0))
            .withHue((accentHSL.hue + 15 * t) % 360)
            .toColor();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.topCenter,
                t,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.bottomCenter,
                t,
              )!,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
