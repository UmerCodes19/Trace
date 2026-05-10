import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class WelcomeCinematic extends StatelessWidget {
  final VoidCallback onStartTour;
  final VoidCallback onDismiss;

  const WelcomeCinematic({
    super.key,
    required this.onStartTour,
    required this.onDismiss,
  });

  static void show(BuildContext context, {required VoidCallback onStartTour, required VoidCallback onDismiss}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Welcome",
      pageBuilder: (ctx, a1, a2) => WelcomeCinematic(
        onStartTour: () {
          Navigator.pop(ctx);
          onStartTour();
        },
        onDismiss: () {
          Navigator.pop(ctx);
          onDismiss();
        },
      ),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15 * anim1.value,
            sigmaY: 15 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Official Transparent Logo Header
              Image.asset(
                'assets/images/app_logo_transparent.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ).animate().scale(delay: 200.ms, curve: Curves.elasticOut, duration: 800.ms).shimmer(delay: 1000.ms),
              const SizedBox(height: 24),
              Text(
                'Welcome to Trace',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -1,
                  color: AppColors.textPrimary(context),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                'The intelligent campus hub for uniting lost belongings and restoring order to daily life.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary(context),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStartTour,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Take the Quick Tour',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
