import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/local_settings_service.dart';
import '../../widgets/common/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SimpleUserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final accentInt = ref.watch(accentColorProvider);
    final accent = Color(accentInt);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDarkMode),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Appearance', isDarkMode),
                  const SizedBox(height: 12),
                  _buildThemeToggle(isDarkMode, accent),
                  const SizedBox(height: 12),
                  _buildAccentPicker(accent),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Account & Security', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Change your name and contact info',
                    onTap: () => context.push('/profile/edit'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.shield_outlined,
                    title: 'CMS Verification',
                    subtitle: _user?.isCMSVerified == true ? 'Verified' : 'Not Verified',
                    trailing: _user?.isCMSVerified == true 
                        ? const Icon(Icons.check_circle, color: AppColors.foundSuccess, size: 20)
                        : null,
                    onTap: () => context.push('/login/cms'),
                    isDarkMode: isDarkMode,
                  ),

                  _buildSettingTile(
                    icon: Icons.qr_code_rounded,
                    title: 'My Profile QR',
                    subtitle: 'Share your digital student ID',
                    onTap: () => context.push('/profile/qr'),
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('QR Profile Privacy', isDarkMode),
                  const SizedBox(height: 12),
                  _buildPrivacyToggle(
                    icon: Icons.family_restroom_rounded,
                    title: 'Show Father Name',
                    key: 'showFatherName',
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyToggle(
                    icon: Icons.phone_android_rounded,
                    title: 'Show Contact Number',
                    key: 'showContactNumber',
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyToggle(
                    icon: Icons.badge_rounded,
                    title: 'Show Registration No',
                    key: 'showRegistrationNo',
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyToggle(
                    icon: Icons.home_rounded,
                    title: 'Show Address',
                    key: 'showAddress',
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyToggle(
                    icon: Icons.school_rounded,
                    title: 'Show Department',
                    key: 'showDepartment',
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Privacy & Storage', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy Mode',
                    subtitle: 'Hide your contact details from public',
                    value: false, // Placeholder for now
                    onChanged: (val) {},
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear Cache',
                    subtitle: 'Free up local image storage',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared!')),
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Notifications', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push Notifications',
                    subtitle: 'Alerts for found items and messages',
                    value: ref.watch(localSettingsProvider).notificationsEnabled,
                    onChanged: (val) {
                      ref.read(localSettingsProvider).setNotificationsEnabled(val);
                      setState(() {});
                    },
                    isDarkMode: isDarkMode,
                    accent: accent,
                  ),

                  const SizedBox(height: 48),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.navyDarkest,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
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

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: isDarkMode ? Colors.white38 : Colors.black38,
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildThemeToggle(bool isDarkMode, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDarkMode ? Colors.amber[300] : Colors.orange[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black),
                ),
                Text(
                  'Enjoy a deeper, eye-friendly UI',
                  style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDarkMode,
            activeColor: accent,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ref.read(localSettingsProvider).setDarkMode(val);
              ref.read(themeProvider.notifier).state = val;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccentPicker(Color currentAccent) {
    final isDarkMode = ref.watch(themeProvider);
    final accents = [
      0xFF10B981, // Jade
      0xFF6366F1, // Indigo
      0xFFEC4899, // Pink
      0xFFF59E0B, // Amber
      0xFF0EA5E9, // Sky
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: accents.map((colorInt) {
              final isSelected = currentAccent.value == colorInt;
              return GestureDetector(
                onTap: () {
                  ref.read(localSettingsProvider).setAccentColor(colorInt);
                  ref.read(accentColorProvider.notifier).state = colorInt;
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(colorInt),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Color(colorInt).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    Widget? trailing,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDarkMode ? Colors.white38 : Colors.black26),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
    required Color accent,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required IconData icon,
    required String title,
    required String key,
    required bool isDarkMode,
    required Color accent,
  }) {
    final bool value = _user?.privacySettings?[key] ?? true;

    return _buildSwitchTile(
      icon: icon,
      title: title,
      subtitle: 'Visible on public QR profile',
      value: value,
      onChanged: (val) async {
        if (_user == null) return;
        
        final newSettings = Map<String, dynamic>.from(_user!.privacySettings ?? {});
        newSettings[key] = val;
        
        final updatedUser = _user!.copyWith(privacySettings: newSettings);
        
        setState(() {
          _user = updatedUser;
        });

        try {
          await ref.read(authServiceProvider).updateUserProfile(
            _user!.uid, 
            updatedUser.toMap()
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save setting: $e')),
            );
          }
        }
      },
      isDarkMode: isDarkMode,
      accent: accent,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(authServiceProvider).signOut();
          ref.invalidate(postsProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
          ref.invalidate(myClaimsProvider);
          if (mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
