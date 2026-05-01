import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/glass_gradient_bg.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Cinematic delay for splash
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Check first time use
    const storage = FlutterSecureStorage();
    final hasSeenOnboarding = await storage.read(key: 'has_seen_onboarding');
    
    if (!mounted) return;

    if (hasSeenOnboarding != 'true') {
      context.go('/onboarding');
      return;
    }

    // Check auth
    final authService = ref.read(authServiceProvider);
    final user = await authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GlassGradientBg(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Elegant glowing logo container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyLight.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.layers_outlined,
                  size: 34,
                  color: AppColors.navyLight,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.9, 0.9), duration: 1200.ms, curve: Curves.easeOutQuint),
            
            const SizedBox(height: 32),

            // Minimalist Typography
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LOST',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '&',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: AppColors.navyLight,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'FOUND',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 1000.ms, curve: Curves.easeOut)
                .slideY(begin: 0.2, delay: 400.ms, duration: 1000.ms, curve: Curves.easeOut),
          ],
        ),
      ),
      ),
    );
  }
}
