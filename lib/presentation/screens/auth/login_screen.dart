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
import '../../widgets/common/falling_pattern_background.dart';


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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF030303),
        body: Row(
          children: [
            // Left Pane: Premium Animated Branding Showcase (60% width)
            Expanded(
              flex: 6,
              child: FallingPatternBackground(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Logo & Text
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withOpacity(0.2), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.25),
                                  blurRadius: 20,
                                )
                              ],
                            ),
                            child: Center(child: TraceLogo(color: accent, size: 32)),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05))
                           .shimmer(duration: 3.seconds, color: accent.withOpacity(0.15)),
                          const SizedBox(width: 16),
                          Text(
                            'Trace.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      // Welcome Taglines
                      Text(
                        'Refined campus awareness.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.15,
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      Text(
                        'The secure, AI-powered lost and found portal designed explicitly for university ecosystems.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 48),

                      // Feature Highlights
                      _buildDesktopFeatureItem(
                        icon: Icons.map_rounded,
                        title: 'Spatial Campus Blueprints',
                        subtitle: 'Navigate precise block levels and find belongings with interactive indoor GIS maps.',
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 24),
                      _buildDesktopFeatureItem(
                        icon: Icons.center_focus_weak_rounded,
                        title: 'AI Visual Search Scanner',
                        subtitle: 'Upload belonging photos to instantly match items with campus entries using AI.',
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 24),
                      _buildDesktopFeatureItem(
                        icon: Icons.handshake_rounded,
                        title: 'Secure P2P Handovers',
                        subtitle: 'Zero-trust claimant verification and QR-guided physical handovers.',
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.05, end: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Right Pane: Sleek login credential card (40% width)
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFF0C0E17),
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your preferred sign in provider to log into your campus account.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(color: AppColors.jadePrimary),
                            ),
                          )
                        else
                          Column(
                            children: [
                              _SocialButton(
                                label: 'Continue with Google',
                                icon: Icons.g_mobiledata_rounded,
                                onTap: () => _handleLogin(true),
                              ),
                              const SizedBox(height: 16),
                              _SocialButton(
                                label: 'Continue with University CMS',
                                icon: Icons.school_rounded,
                                onTap: () => context.push('/login/cms'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 40),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Existing native mobile login screen
    return Scaffold(
      body: FallingPatternBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
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
        ),
      ),
    );
  }

  Widget _buildDesktopFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.jadePrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.jadePrimary.withOpacity(0.15),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.jadePrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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


