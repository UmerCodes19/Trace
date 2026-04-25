import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/animated_gradient_bg.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authServiceProvider).getCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: FutureBuilder<SimpleUserModel?>(
        future: userAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Not logged in'));
          }
          return _ProfileBody(user: snapshot.data!);
        },
      ),
    );
  }
}

/// ─── Skeleton Loading ────────────────────────────────────────────────────────
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.navyDarkest,
                  AppColors.navyMid,
                ],
              ),
            ),
            child: const SkeletonProfileHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
                      child: const SkeletonBox(height: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SkeletonSettingsSection(itemCount: 3),
              const SizedBox(height: 24),
              const SkeletonSettingsSection(itemCount: 3),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});
  final SimpleUserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        // ─── Header with animated gradient ─────────────────────────
        SliverToBoxAdapter(
          child: AnimatedProfileGradient(
            accent: AppColors.navyDarkest,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 24,
                24,
                32,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlassCard(
                      borderRadius: 40,
                      opacity: 0.15,
                      child: IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Avatar with verification badge & glow ring
                  Stack(
                    children: [
                      // Glow ring
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.navyLight,
                            image: user.photoURL != null &&
                                    user.photoURL!.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      user.photoURL!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user.photoURL == null ||
                                  user.photoURL!.isEmpty
                              ? Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (user.isCMSVerified)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.foundSuccess,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.navyDarkest,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.foundSuccess.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                              .animate(
                                  onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              ),
                        ),
                    ],
                  ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.7, 0.7),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    user.name.isNotEmpty ? user.name : 'Unknown User',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  if (user.email.isNotEmpty)
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 4),
                  if (user.department != null && user.department!.isNotEmpty)
                    Text(
                      user.department!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 12),
                  if (user.isCMSVerified)
                    GlassCard(
                      borderRadius: 20,
                      opacity: 0.15,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.foundSuccess,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CMS Verified Student',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.foundSuccess,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ─── Stats Cards ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                _StatCard(
                  label: 'Lost',
                  value: user.itemsLost,
                  icon: Icons.warning_rounded,
                  color: AppColors.lostAlert,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Found',
                  value: user.itemsFound,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.foundSuccess,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Returned',
                  value: user.itemsReturned,
                  icon: Icons.done_all_rounded,
                  color: AppColors.navyLight,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Karma',
                  value: user.karmaPoints,
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  highlight: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ─── Contact Information ────────────────────────────
              if (user.contactNumber != null &&
                  user.contactNumber!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Contact Information'),
                    _InfoCard(
                      icon: Icons.phone_rounded,
                      label: 'Phone Number',
                      value: user.contactNumber ?? 'Not provided',
                      color: AppColors.navyLight,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // ─── My Activity ──────────────────────────────────
              _SectionTitle('My Activity'),
              _MenuSection(
                items: [
                  _MenuItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'My Posts',
                    subtitle: 'View all your lost & found posts',
                    color: AppColors.navyLight,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'My Chats',
                    subtitle: 'Conversations about your items',
                    color: AppColors.navyMid,
                    onTap: () => context.push('/chats'),
                  ),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Activity History',
                    subtitle: 'Your recent actions',
                    color: AppColors.lostAlert,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Account Settings ─────────────────────────────
              _SectionTitle('Account Settings'),
              _MenuSection(
                items: [
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    subtitle: 'App preferences and notifications',
                    color: accent,
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.qr_code_2_rounded,
                    label: 'My QR Code',
                    subtitle: 'Share your profile code',
                    color: AppColors.foundSuccess,
                    onTap: () => context.push('/profile/qr'),
                  ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    subtitle: 'Sign out of your account',
                    color: const Color(0xFFD32F2F),
                    isDestructive: true,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Logout?'),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── About ────────────────────────────────────────
              _SectionTitle('About'),
              _MenuSection(
                items: [
                  _MenuItem(
                    icon: Icons.info_outlined,
                    label: 'Version',
                    value: 'v1.0.0',
                    color: AppColors.textSecondary(context),
                    onTap: null,
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    subtitle: 'Our privacy commitment',
                    color: AppColors.navyLight,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    subtitle: 'Terms and conditions',
                    color: AppColors.navyMid,
                    onTap: () {},
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card Widget ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        elevation: highlight ? 3 : 1,
        borderGlow: highlight ? color.withOpacity(0.3) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: highlight
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Column(
            children: [
              Icon(icon, color: highlight ? Colors.white : color, size: 24),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: highlight
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary(context),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
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

// ─── Menu Section ─────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      elevation: 1,
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: AppColors.border(context),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? value;
  final Color color;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
