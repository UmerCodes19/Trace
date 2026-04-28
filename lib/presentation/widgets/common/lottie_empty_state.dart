import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import 'pressable_scale.dart';

/// ─── Lottie Empty State Widget ───────────────────────────────────────────────
/// A premium empty state featuring a Lottie animation, gradient title, 
/// body text, and optional CTA button. Falls back to an icon if Lottie fails.
class LottieEmptyStateWidget extends StatelessWidget {
  const LottieEmptyStateWidget({
    super.key,
    required this.lottieAsset,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.animationHeight = 200,
  });

  final String lottieAsset;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double animationHeight;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation with Error Fallback
            Container(
              height: animationHeight,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Lottie.asset(
                lottieAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.08),
                      border: Border.all(
                        color: accent.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      fallbackIcon,
                      size: 50,
                      color: AppColors.textSecondary(context),
                    ),
                  );
                },
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: accent.withOpacity(0.1)),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary(context),
                height: 1.6,
              ),
            ),

            // CTA button
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              PressableScale(
                onTap: onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .shimmer(duration: 2.seconds, color: Colors.white24)
               .scale(duration: 1.seconds, end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
            ],
          ],
        ),
      ),
    );
  }
}
