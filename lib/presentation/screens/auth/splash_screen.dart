import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/trace_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  double _screenOpacity = 1.0;
  String _loadingMessage = 'Initializing Trace';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _runStartupFlow();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runStartupFlow() async {
    // Cinematic delay for startup micro animations
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _loadingMessage = 'Syncing secure session');

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loadingMessage = 'Discovering nearby matches');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Check first time use
    const storage = FlutterSecureStorage();
    final hasSeenOnboarding = await storage.read(key: 'has_seen_onboarding');
    
    if (!mounted) return;

    // Check auth
    final authService = ref.read(authServiceProvider);
    final user = await authService.getCurrentUser();

    if (!mounted) return;

    // Smooth exit phase: Fade out entire screen
    setState(() => _screenOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (hasSeenOnboarding != 'true') {
      context.go('/onboarding');
    } else if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.ghost,
      body: AnimatedOpacity(
        opacity: _screenOpacity,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        child: Stack(
          children: [
            // Ambient motion background layers (Barely noticeable slow drift)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Positioned(
                  top: -60 + (12 * _pulseController.value),
                  right: -40 + (15 * _pulseController.value),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jadePrimary.withOpacity(isDark ? 0.06 : 0.035),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Positioned(
                  bottom: -80 + (15 * (1 - _pulseController.value)),
                  left: -60 + (12 * (1 - _pulseController.value)),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jadePrimary.withOpacity(isDark ? 0.04 : 0.025),
                    ),
                  ),
                );
              },
            ),

            // Main Centered Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with micro glow bloom
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.035) : Colors.black.withOpacity(0.015),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.035),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.jadePrimary.withOpacity(isDark ? 0.28 : 0.12),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: TraceLogo(
                        size: 45,
                        color: AppColors.jadePrimary,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 1000.ms, curve: Curves.easeOutExpo)
                      .scale(begin: const Offset(0.88, 0.88), duration: 1000.ms, curve: Curves.easeOutExpo),

                  const SizedBox(height: 26),

                  // Ultra-premium crisp typography
                  Text(
                    'TRACE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5.5,
                      color: isDark ? Colors.white : AppColors.deepJade,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 800.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.15, delay: 250.ms, duration: 800.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 8),

                  Text(
                    'LOST & FOUND COMPANION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                      color: AppColors.textSecondary(context).withOpacity(0.65),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 800.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 56),

                  // Minimal animated message state
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _loadingMessage,
                      key: ValueKey<String>(_loadingMessage),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context).withOpacity(0.7),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 750.ms, duration: 500.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 14),

                  // Micro dots wave pulse animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.jadePrimary.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.4, 1.4),
                      duration: 600.ms,
                      delay: (i * 180).ms,
                      curve: Curves.easeInOutCubic,
                    ).fadeIn(duration: 250.ms).then().fadeOut(duration: 250.ms)),
                  )
                      .animate()
                      .fadeIn(delay: 850.ms, duration: 500.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
