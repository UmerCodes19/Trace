// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/pressable_scale.dart';
import '../../widgets/common/trace_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin(bool isGoogle) async {
    setState(() => _isLoading = true);
    final auth = ref.read(authServiceProvider);
    final success = isGoogle ? (await auth.signInWithGoogle() != null) : await auth.signInWithGithub();
    
    if (success && mounted) {
      ref.invalidate(postsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      context.go('/home');
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.jadePrimary;

    return Scaffold(
      body: FallingPatternBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        _buildHeader(context, accent),
                        const Spacer(),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.jadePrimary),
                          )
                        else
                          _buildAuthButtons(context, accent),
                        const SizedBox(height: 40),
                        _buildFooter(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Glowing Trace Logo
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Center(child: TraceLogo(color: accent, size: 55)),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05), curve: Curves.easeInOut)
         .shimmer(duration: 3.seconds, color: accent.withOpacity(0.1)),
         
        const SizedBox(height: 40),
        
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.textPrimary(context), accent.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Trace.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 56, 
              fontWeight: FontWeight.w900, 
              color: Colors.white, 
              letterSpacing: -3,
              height: 1,
            ),
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 12),
        
        Text(
          'Refined campus awareness.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w500, 
            color: AppColors.textSecondary(context).withOpacity(0.8),
            letterSpacing: 0.2,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context, Color accent) {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          onTap: () => _handleLogin(true),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        _SocialButton(
          label: 'Continue with University CMS',
          icon: Icons.school_rounded,
          onTap: () => context.push('/login/cms'),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Text(
        'By continuing, you agree to our Terms of Service.',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary(context)),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
          ],
        ),
      ),
    );
  }
}

class FallingPatternBackground extends StatefulWidget {
  const FallingPatternBackground({super.key, required this.child, this.color, this.backgroundColor});
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<FallingPatternBackground> createState() => _FallingPatternBackgroundState();
}

class _FallingPatternBackgroundState extends State<FallingPatternBackground> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _progress = (DateTime.now().millisecondsSinceEpoch % 22000) / 22000.0;
        });
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = AppColors.pageBg(context);
    final defaultPatternColor = AppColors.jadePrimary.withOpacity(isDark ? 0.20 : 0.12);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _FallingPatternPainter(
              progress: _progress,
              patternColor: widget.color ?? defaultPatternColor,
              bgColor: widget.backgroundColor ?? defaultBg,
              isDark: isDark,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  Colors.transparent,
                  (widget.backgroundColor ?? defaultBg).withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _FallingPatternPainter extends CustomPainter {
  _FallingPatternPainter({
    required this.progress,
    required this.patternColor,
    required this.bgColor,
    required this.isDark,
  });

  final double progress;
  final Color patternColor;
  final Color bgColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid background
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw dot-matrix grid overlay (resembling the React pattern density)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    
    const double gridSize = 18.0;
    for (double gx = 0; gx < size.width; gx += gridSize) {
      for (double gy = 0; gy < size.height; gy += gridSize) {
        canvas.drawCircle(Offset(gx, gy), 1.0, gridPaint);
      }
    }

    // 3. Draw drifting vertical neon columns
    final dotPaint = Paint()
      ..color = patternColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    const columns = 14;
    final columnWidth = size.width / columns;

    for (int col = 0; col < columns; col++) {
      final double seed = (col * 31.415) % 1.0;
      final double speed = 0.4 + (seed * 0.5);
      final double currentY = (progress * size.height * speed + (seed * size.height)) % size.height;

      final double x = col * columnWidth + (columnWidth / 2);
      final double streakHeight = 80.0 + (seed * 120.0);
      final double startY = currentY - streakHeight;
      
      if (startY < 0) {
        _drawStreak(canvas, x, size.height + startY, streakHeight, dotPaint);
      }
      _drawStreak(canvas, x, startY, streakHeight, dotPaint);
    }
  }

  void _drawStreak(Canvas canvas, double x, double startY, double height, Paint dotPaint) {
    final double endY = startY + height;
    final rect = Rect.fromLTRB(x - 3, startY, x + 3, endY);
    
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, patternColor, Colors.transparent],
    ).createShader(rect);

    final Paint fadePaint = Paint()
      ..shader = shader
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, startY), Offset(x, endY), fadePaint);
    
    // Glowing neon head matching the pattern center
    canvas.drawCircle(Offset(x, startY + height * 0.5), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FallingPatternPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.patternColor != patternColor ||
        oldDelegate.bgColor != bgColor;
  }
}
