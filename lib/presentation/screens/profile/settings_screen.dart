import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../main.dart';
import '../../widgets/common/accent_color_picker.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SimpleUserModel? _user;
  bool _isLoading = true;
  bool _darkMode = false;
  bool _proximityAlerts = true;
  bool _chatNotifications = true;
  String? _selectedDepartment;
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();

      if (user != null && mounted) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _selectedDepartment = user.department;
          _contactController.text = user.contactNumber ?? '';
          
          // These should ideally be in user metadata or a separate settings table in Supabase
          _darkMode = user.isDarkMode;
          _proximityAlerts = user.proximityAlertsEnabled;
          _chatNotifications = user.chatNotificationsEnabled;
        });
        
        ref.read(themeProvider.notifier).state = user.isDarkMode;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserProfile() async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.syncUser({
        ..._user!.toMap(),
        'name': _nameController.text.trim(),
        'department': _selectedDepartment,
        'contactNumber': _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        'isDarkMode': _darkMode,
        'proximityAlertsEnabled': _proximityAlerts,
        'chatNotificationsEnabled': _chatNotifications,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }

      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() => _darkMode = value);
    ref.read(themeProvider.notifier).state = value;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Dark mode enabled 🌙' : 'Light mode enabled ☀️',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary(context),
            size: 18,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveUserProfile,
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                children: [
                  const SkeletonSettingsSection(itemCount: 5),
                  const SizedBox(height: 16),
                  const SkeletonSettingsSection(itemCount: 2),
                  const SizedBox(height: 16),
                  const SkeletonSettingsSection(itemCount: 1),
                ],
              ),
            )
          : _user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    children: [
                      // Profile Section
                      _SettingsSection(
                        title: 'Profile Information',
                        children: [
                          _ProfileField(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            controller: _nameController,
                          ),
                          _ProfileDropdown(
                            icon: Icons.school_outlined,
                            label: 'Department',
                            value: _selectedDepartment,
                            items: const [
                              'Computer Science',
                              'Software Engineering',
                              'Electrical Engineering',
                              'Mechanical Engineering',
                              'Business Administration',
                              'Psychology',
                              'Accounting & Finance',
                              'Media Studies',
                              'Law',
                              'Other',
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedDepartment = v),
                          ),
                          _ProfileField(
                            icon: Icons.phone_outlined,
                            label: 'Contact Number',
                            controller: _contactController,
                          ),
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _user!.email,
                          ),
                          if (_user!.isCMSVerified)
                            _InfoTile(
                              icon: Icons.verified_rounded,
                              label: 'CMS Status',
                              value: 'Verified Student',
                              valueColor: AppColors.foundSuccess,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notifications Section
                      _SettingsSection(
                        title: 'Notifications',
                        children: [
                          _SettingsToggle(
                            icon: Icons.near_me_outlined,
                            label: 'Proximity Alerts',
                            subtitle: 'Notify when near a lost item',
                            value: _proximityAlerts,
                            onChanged: (v) =>
                                setState(() => _proximityAlerts = v),
                          ),
                          _SettingsToggle(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat Notifications',
                            subtitle: 'New messages from claimers',
                            value: _chatNotifications,
                            onChanged: (v) =>
                                setState(() => _chatNotifications = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Appearance Section with Accent Picker
                      _SettingsSection(
                        title: 'Appearance',
                        children: [
                          _SettingsToggle(
                            icon: _darkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            label: 'Dark Mode',
                            subtitle: 'Switch between light and dark theme',
                            value: _darkMode,
                            onChanged: _toggleDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Accent Color Picker
                      const AccentColorPicker(),
                      const SizedBox(height: 16),

                      // Security Section
                      _SettingsSection(
                        title: 'Security',
                        children: [
                          _SettingsTile(
                            icon: Icons.qr_code_scanner_outlined,
                            label: 'My QR Code',
                            subtitle: 'Share your QR code for claiming items',
                            onTap: () => context.push('/profile/qr'),
                          ),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            isDestructive: true,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to logout?',
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
                              if (confirmed == true && mounted) {
                                await ref.read(authServiceProvider).signOut();
                                if (mounted) context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // About Section
                      _SettingsSection(
                        title: 'About',
                        children: [
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            label: 'Version',
                            subtitle: 'Lost & Found v1.0.0',
                            onTap: null,
                          ),
                          _SettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy Policy',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.8,
            ),
          ),
        ),
        GlassCard(
          borderRadius: 18,
          elevation: 1,
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
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
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (value != null && value!.trim().isNotEmpty)
        ? value!.trim()
        : null;
    final safeValue = items.cast<String?>().firstWhere(
          (item) =>
              item != null &&
              normalizedValue != null &&
              item.toLowerCase() == normalizedValue.toLowerCase(),
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: safeValue,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.cardBg(context),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  hint: Text(
                    'Select department',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textHint(context),
                    ),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFD32F2F)
        : AppColors.textPrimary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w500,
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
            if (onTap != null)
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
