import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/trace_logo.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  double _screenOpacity = 1.0;
  String _loadingMessage = 'Initializing Trace';

  late AnimationController _pulseController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _runStartupFlow();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _runStartupFlow() async {
    // 1. Initial Beat
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // 2. Start Reveal
    _logoController.forward();
    setState(() => _loadingMessage = 'Connecting to campus network');

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    
    final authService = ref.read(authServiceProvider);
    final userFuture = authService.getCurrentUser();
    
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final user = await userFuture;
    const storage = FlutterSecureStorage();
    final hasSeenOnboarding = await storage.read(key: 'has_seen_onboarding');

    // 4. Smooth Exit
    setState(() => _screenOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (devForceOnboarding || hasSeenOnboarding != 'true') {
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
        duration: const Duration(milliseconds: 500),
        child: Stack(
          children: [
            // ── Enhanced Fluid Background ───────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FluidBackgroundPainter(
                      animation: _pulseController.value,
                      isDark: isDark,
                      accentColor: AppColors.jadePrimary,
                    ),
                  );
                },
              ),
            ),

            // ── Main Content ────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Real App Logo Image with Premium Reveal
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * _logoController.value),
                        child: Container(
                          width: 180, height: 180,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.jadePrimary.withOpacity(isDark ? 0.2 : 0.1),
                                blurRadius: 60 * _logoController.value,
                                spreadRadius: 10 * _logoController.value,
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: _logoController.value,
                            child: Image.asset(
                              'assets/images/app_logo_transparent.png',
                              fit: BoxFit.contain,
                              // Apply a slight tint if needed, but keeping it original for "real" look
                            ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 2.seconds,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // TRACE Title
                  Text(
                    'TRACE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: isDark ? Colors.white : AppColors.deepJade,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 800.ms)
                      .slideY(begin: 0.1, end: 0, delay: 600.ms),

                  const SizedBox(height: 4),

                  // Simple, Emotional Tagline
                  Text(
                    'Never Really Lost',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.jadePrimary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 800.ms),

                  const SizedBox(height: 80),

                  // Minimal Status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _loadingMessage.toUpperCase(),
                      key: ValueKey<String>(_loadingMessage),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary(context).withOpacity(0.4),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FluidBackgroundPainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final Color accentColor;

  _FluidBackgroundPainter({
    required this.animation,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Blob 1
    paint.color = accentColor.withOpacity(isDark ? 0.08 : 0.05);
    canvas.drawCircle(
      Offset(
        center.dx + sin(animation * pi * 2) * 50,
        center.dy + cos(animation * pi * 2) * 30,
      ),
      size.width * 0.6,
      paint,
    );

    // Blob 2
    paint.color = accentColor.withOpacity(isDark ? 0.06 : 0.03);
    canvas.drawCircle(
      Offset(
        center.dx - cos(animation * pi * 2) * 40,
        center.dy - sin(animation * pi * 2) * 60,
      ),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FluidBackgroundPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
