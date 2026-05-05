import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_settings_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';

class ProfileScreen extends ConsumerWidget {
  final String? viewUid;
  const ProfileScreen({super.key, this.viewUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = viewUid != null 
        ? ref.watch(apiServiceProvider).getUser(viewUid!).then((map) => map != null ? SimpleUserModel.fromMap(map) : null)
        : ref.watch(authServiceProvider).getCurrentUser();
    final isDarkMode = ref.watch(themeProvider);
    final isPublicView = viewUid != null;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.grey[50],
      body: FutureBuilder<SimpleUserModel?>(
        future: userAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Not logged in'));
          }
          return _ProfileBody(user: snapshot.data!, isPublicView: isPublicView);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user, this.isPublicView = false});
  final SimpleUserModel user;
  final bool isPublicView;

  Widget _buildBadgesSection(SimpleUserModel user, bool isDarkMode) {
    final successfulReturns = user.itemsFound;
    final totalInteractions = user.itemsLost + user.itemsFound;

    final showTrustedFinder = successfulReturns >= 3;
    final showCommunityHelper = totalInteractions >= 10;

    if (!showTrustedFinder && !showCommunityHelper) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionTitle('Badges & Achievements', isDarkMode),
        const SizedBox(height: 12),
        Row(
          children: [
            if (showTrustedFinder)
              _buildBadgeCard(
                'Trusted Finder',
                'Successfully returned 3+ items',
                Icons.verified_user_rounded,
                Colors.green,
                isDarkMode,
              ),
            if (showTrustedFinder && showCommunityHelper) const SizedBox(width: 12),
            if (showCommunityHelper)
              _buildBadgeCard(
                'Community Helper',
                'Participated in 10+ reports',
                Icons.groups_rounded,
                Colors.blue,
                isDarkMode,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeCard(String name, String desc, IconData icon, Color color, bool isDarkMode) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.navyDarkest,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final accentInt = ref.watch(accentColorProvider);
    final accent = Color(accentInt);
    final localSettings = ref.read(localSettingsProvider);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, isDarkMode, accent, isPublicView),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildStatsGrid(user, isDarkMode, accent),
                _buildBadgesSection(user, isDarkMode),
                const SizedBox(height: 32),
                _buildSectionTitle('Student Identity', isDarkMode),
                const SizedBox(height: 16),
                _buildStudentCard(user, isDarkMode, accent, localSettings),
                const SizedBox(height: 16),
                _buildIdentityCard(user, isDarkMode, accent, localSettings),
                const SizedBox(height: 32),
                _buildSectionTitle('Contact Details', isDarkMode),
                const SizedBox(height: 16),
                _buildContactCard(user, isDarkMode, accent, localSettings),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDarkMode, Color accent, bool isPublicView) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.white,
      elevation: 0,
      leading: isPublicView ? IconButton(
        icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.navyDarkest),
        onPressed: () => Navigator.pop(context),
      ) : null,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.8),
                    accent.withOpacity(0.4),
                    isDarkMode ? AppColors.navyDarkest : Colors.white,
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile_pic_${user.uid}',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      backgroundColor: AppColors.jadePrimary,
                      child: user.photoURL == null || user.photoURL!.isEmpty
                          ? Text(user.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.navyDarkest,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.qr_code_scanner_rounded, color: isDarkMode ? Colors.white : AppColors.navyDarkest),
          onPressed: () => context.push('/profile/qr'),
          tooltip: 'My QR Code',
        ),
        if (!isPublicView) IconButton(
          icon: Icon(Icons.settings_outlined, color: isDarkMode ? Colors.white : AppColors.navyDarkest),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : AppColors.navyDarkest,
      ),
    );
  }

  Widget _buildStatsGrid(SimpleUserModel user, bool isDarkMode, Color accent) {
    return Row(
      children: [
        _buildStatItem('Lost', user.itemsLost.toString(), accent, isDarkMode),
        const SizedBox(width: 12),
        _buildStatItem('Found', user.itemsFound.toString(), AppColors.foundSuccess, isDarkMode),
        const SizedBox(width: 12),
        _buildStatItem('Karma', user.karmaPoints.toString(), Colors.amber[600]!, isDarkMode),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.navyDarkest,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(SimpleUserModel user, bool isDarkMode, Color accent, LocalSettingsService localSettings) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STUDENT ID',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    Icon(Icons.nfc, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
                const Spacer(),
                Text(
                  user.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.cmsStudentId ?? 'UNVERIFIED',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROGRAM', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(user.department ?? '---', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('REGISTRATION', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(
                          (user.registrationNo?.isNotEmpty == true) ? user.registrationNo! : localSettings.registrationNo ?? '---',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildIdentityCard(SimpleUserModel user, bool isDarkMode, Color accent, LocalSettingsService localSettings) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline_rounded, 
            'Father Name', 
            (user.fatherName?.isNotEmpty == true) ? user.fatherName! : localSettings.fatherName ?? 'Not Provided', 
            isDarkMode
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(
            Icons.calendar_today_outlined, 
            'Intake Semester', 
            (user.intakeSemester?.isNotEmpty == true) ? user.intakeSemester! : localSettings.intakeSemester ?? 'Not Provided', 
            isDarkMode
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(Icons.school_outlined, 'Academic Dept', user.department ?? 'Not Provided', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildContactCard(SimpleUserModel user, bool isDarkMode, Color accent, LocalSettingsService localSettings) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_android_rounded, 'Mobile No.', user.contactNumber ?? 'Not Provided', isDarkMode),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(
            Icons.location_on_outlined, 
            'Current Address', 
            (user.currentAddress?.isNotEmpty == true) ? user.currentAddress! : localSettings.currentAddress ?? 'Not Provided', 
            isDarkMode, 
            isLongText: true
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(
            Icons.home_outlined, 
            'Permanent Address', 
            (user.permanentAddress?.isNotEmpty == true) ? user.permanentAddress! : localSettings.permanentAddress ?? 'Not Provided', 
            isDarkMode, 
            isLongText: true
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode, {bool isLongText = false}) {
    return Row(
      crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: isDarkMode ? Colors.white38 : Colors.black38),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white38 : Colors.black38, letterSpacing: 0.5),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500, 
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: isLongText ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
