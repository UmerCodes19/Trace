import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/glass_gradient_bg.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInGoogle() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();

      if (!mounted) return;

      if (result != null) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed. Try CMS login.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdminLogin() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: Text('Admin Portal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Admin Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text == 'admin@lostfound.com' && passCtrl.text == 'admin123') {
                Navigator.pop(context);
                final api = ref.read(apiServiceProvider);
                final auth = ref.read(authServiceProvider);
                
                // Create/Update admin user in cloud
                await api.syncUser({
                  'uid': 'admin_001',
                  'name': 'System Admin',
                  'email': 'admin@lostfound.com',
                  'isAdmin': 1,
                  'isCMSVerified': 1,
                });
                
                // Set as current user in auth service (mock)
                await auth.setMockUser('admin_001');
                
                if (context.mounted) {
                  context.go('/home');
                }
              } else {
                showAppSnack(context, 'Invalid Admin Credentials', isError: true);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GlassGradientBg(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Welcome Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME TO',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                        letterSpacing: 4,
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
                    
                    const SizedBox(height: 12),
                    
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          isDark ? Colors.white : Colors.black87,
                          accent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'LOST &\nFOUND',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1.1,
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 200.ms, duration: 800.ms)
                      .slideX(begin: -0.1)
                      .shimmer(delay: 1000.ms, duration: 2000.ms, color: Colors.white30),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Text(
                        'Your official campus platform for recovering lost items securely.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Glassmorphic Action Card
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.03),
                      border: Border(
                        top: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SocialButton(
                          onTap: () => context.push('/login/cms'),
                          isLoading: false,
                          iconData: Icons.school_outlined,
                          label: 'Sign in with CMS ID',
                          isPrimary: true,
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                        const SizedBox(height: 16),

                        _SocialButton(
                          onTap: _isLoading ? null : _signInGoogle,
                          isLoading: _isLoading,
                          iconData: Icons.g_mobiledata_rounded,
                          label: 'Continue with Google',
                          isPrimary: false,
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                        const SizedBox(height: 32),

                        Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textHint(context),
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 900.ms),

                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _showAdminLogin,
                          child: Text(
                            'ADMIN PORTAL',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent.withOpacity(0.7),
                              letterSpacing: 2,
                            ),
                          ),
                        ).animate().fadeIn(delay: 1100.ms),
                      ],
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    required this.iconData,
    required this.label,
    required this.isPrimary,
  });

  final VoidCallback? onTap;
  final bool isLoading;
  final IconData iconData;
  final String label;
  final bool isPrimary;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onTap == null || widget.isLoading;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.isPrimary ? 0 : 12,
              sigmaY: widget.isPrimary ? 0 : 12,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.border(context)
                    : widget.isPrimary
                        ? null
                        : (isDark
                            ? AppColors.darkCard.withOpacity(0.5)
                            : Colors.white.withOpacity(0.7)),
                gradient: widget.isPrimary && !isDisabled
                    ? LinearGradient(
                        colors: [
                          accent,
                          HSLColor.fromColor(accent)
                              .withHue(
                                (HSLColor.fromColor(accent).hue + 25) % 360,
                              )
                              .toColor(),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDisabled
                      ? AppColors.border(context)
                      : widget.isPrimary
                          ? Colors.transparent
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.7)),
                  width: 0.8,
                ),
                boxShadow: widget.isPrimary && !isDisabled
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: widget.isPrimary
                              ? Colors.white
                              : accent,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.iconData,
                          color: isDisabled
                              ? AppColors.textHint(context)
                              : widget.isPrimary
                                  ? Colors.white
                                  : AppColors.textPrimary(context),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.textHint(context)
                                : widget.isPrimary
                                    ? Colors.white
                                    : AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
