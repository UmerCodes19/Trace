// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/pressable_scale.dart';

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
      context.go('/home');
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.jadePrimary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: Stack(
        children: [
          // Minimalist Grid Pattern Background with Jade Tint
          if (!isDark) Positioned.fill(child: CustomPaint(painter: _GridPainter(accent.withOpacity(0.05)))),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100),
                          _buildHeader(context, accent),
                          const Spacer(),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 32),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 32),
        Text(
          'Trace.',
          style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: -2),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'The campus lost & found network, refined.',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context), height: 1.5),
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
          label: 'Continue with GitHub',
          icon: Icons.code_rounded,
          onTap: () => _handleLogin(false),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border(context))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context)))),
            Expanded(child: Divider(color: AppColors.border(context))),
          ],
        ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.push('/login/cms'),
          child: Text('University CMS Login', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: accent)),
        ).animate().fadeIn(delay: 900.ms),
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

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const spacing = 30.0;
    for (var i = 0.0; i < size.width; i += spacing) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (var i = 0.0; i < size.height; i += spacing) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
