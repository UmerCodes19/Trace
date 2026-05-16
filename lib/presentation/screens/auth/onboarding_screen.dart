// lib/presentation/screens/auth/onboarding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../widgets/common/pressable_scale.dart';

/// DEVELOPER TESTING MODE
/// Set this to [true] to force the onboarding screen to appear on EVERY hot restart/reload!
const bool devForceOnboarding = false;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  double _progressValue = 0.0;
  late final AnimationController _animController;

  final List<_OnboardingData> _slides = [
    _OnboardingData(
      number: '01',
      title: 'Spatial Location\nMapping',
      body: 'Pinpoint precise coordinates of found items inside custom layout plans. Navigate floor blueprints and rooms effortlessly.',
      accentColor: AppColors.jadePrimary,
      mockup: const _SpatialMapMockup(),
    ),
    _OnboardingData(
      number: '02',
      title: 'Smart Image\nSignature matching',
      body: 'Utilize vision matching networks to instantly compare visual signatures. Snap a picture to find overlapping assets in seconds.',
      accentColor: Colors.cyanAccent,
      mockup: const _VisualScannerMockup(),
    ),
    _OnboardingData(
      number: '03',
      title: 'Verified Trusted\nCommunity',
      body: 'Rest easy knowing every transaction is authenticated through secure credentials. Build reliability scores and gain Karma.',
      accentColor: Colors.amberAccent,
      mockup: const _SecurityMockup(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _progressValue = 0.0);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _progressValue += 0.01;
        if (_progressValue >= 1.0) {
          _nextSlide();
        }
      });
    });
  }

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _timer?.cancel();
      _animController.forward(from: 0.0);
      setState(() {
        _currentIndex++;
      });
      _startTimer();
    } else {
      _finishOnboarding();
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      _timer?.cancel();
      _animController.forward(from: 0.0);
      setState(() {
        _currentIndex--;
      });
      _startTimer();
    }
  }

  Future<void> _finishOnboarding() async {
    const storage = FlutterSecureStorage();
    if (!devForceOnboarding) {
      await storage.write(key: 'has_seen_onboarding', value: 'true');
    }
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = AppColors.pageBg(context);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Stories-style Horizontal Progress Indicators at the very top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: List.generate(_slides.length, (i) {
                  double value = 0.0;
                  if (i < _currentIndex) {
                    value = 1.0;
                  } else if (i == _currentIndex) {
                    value = _progressValue;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(slide.accentColor),
                          minHeight: 3.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Top Header: Navigation control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _prevSlide,
                      style: TextButton.styleFrom(foregroundColor: subColor),
                      child: Text('Back', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox.shrink(),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(foregroundColor: subColor),
                    child: Text('Skip', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 2. Main Interactive Visualization Card Zone (Middle)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInBack,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentIndex),
                      child: slide.mockup,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Immersive Left-Aligned Modern Typography & Numbers (Bottom)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Large modern outline number
                    Text(
                      slide.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1.5
                          ..color = slide.accentColor.withOpacity(0.4),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 8),

                    // Slide Title
                    Text(
                      slide.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 12),

                    // Slide Description
                    Text(
                      slide.body,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: subColor,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
                    const SizedBox(height: 16),
                  ],
                ),
                ),
              ),
            ),

            // 4. Floating Action Controls (Footer)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Tracker text indicator
                  Text(
                    '${_currentIndex + 1} of ${_slides.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: subColor.withOpacity(0.6),
                    ),
                  ),

                  // Circular interactive navigation action
                  PressableScale(
                    onTap: _nextSlide,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [slide.accentColor, slide.accentColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: slide.accentColor.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// HIGH-FIDELITY ISOMETRIC PREVIEW MOCKUPS (NO CHEAP EMOJIS)
// ==========================================================

class _SpatialMapMockup extends StatelessWidget {
  const _SpatialMapMockup();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.card(context);
    final borderCol = AppColors.border(context);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.4)
        ..rotateY(-0.3)
        ..rotateZ(0.1),
      alignment: Alignment.center,
      child: Container(
        width: 250,
        height: 180,
        decoration: BoxDecoration(
          color: cardBg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderCol, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(-10, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Isometric blueprint lines
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: GridPaper(
                  color: AppColors.jadePrimary,
                  divisions: 1,
                  subdivisions: 1,
                  interval: 35.0,
                ),
              ),
            ),
            // Floating floor layout shape
            Positioned(
              top: 35, left: 35, right: 35, bottom: 35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.jadePrimary.withOpacity(0.2), width: 2),
                  color: AppColors.jadePrimary.withOpacity(0.04),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing target node
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.jadePrimary.withOpacity(0.15),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.8, 1.8),
                          duration: 1200.ms,
                          curve: Curves.easeOut,
                        ).fadeOut(duration: 1200.ms),
                    // Inner indicator
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.jadePrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualScannerMockup extends StatefulWidget {
  const _VisualScannerMockup();

  @override
  State<_VisualScannerMockup> createState() => _VisualScannerMockupState();
}

class _VisualScannerMockupState extends State<_VisualScannerMockup> with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.card(context);
    final borderCol = AppColors.border(context);

    return Container(
      width: 260,
      height: 190,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Simulated camera targeting corners
          Positioned(
            top: 15, left: 15, right: 15, bottom: 15,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vector Tag mock
                  Positioned(
                    top: 25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        'Electronics Detected [98.4%]',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  Icon(
                    Icons.center_focus_strong_rounded,
                    size: 32,
                    color: isDark ? Colors.white24 : Colors.black.withOpacity(0.24),
                  ),
                ],
              ),
            ),
          ),
          // Vertical sliding neon laser scanner line
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) {
              final topOffset = 20.0 + (_scanController.value * 145.0);
              return Positioned(
                top: topOffset,
                left: 20,
                right: 20,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecurityMockup extends StatelessWidget {
  const _SecurityMockup();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.card(context);
    final borderCol = AppColors.border(context);

    return Container(
      width: 260,
      height: 170,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.jadePrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '100% SECURE ACCOUNT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: borderCol, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Contribution Score',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.jadePrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+150 Karma',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.jadePrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.number,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.mockup,
  });

  final String number;
  final String title;
  final String body;
  final Color accentColor;
  final Widget mockup;
}
