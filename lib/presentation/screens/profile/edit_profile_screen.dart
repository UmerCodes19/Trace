import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_settings_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _departmentController;
  late TextEditingController _fatherNameController;
  late TextEditingController _regNoController;
  
  SimpleUserModel? _user;
  bool _isLoading = true;
  File? _pickedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 75);
      if (picked != null && mounted) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to pick image', isError: true);
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(ref.read(accentColorProvider));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface(context) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Profile Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            _buildSheetItem(
              icon: Icons.camera_alt_rounded, 
              label: 'Take a Photo', 
              color: accent,
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }
            ),
            _buildSheetItem(
              icon: Icons.photo_library_rounded, 
              label: 'Choose from Gallery', 
              color: Colors.blue,
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }
            ),
            _buildSheetItem(
              icon: Icons.face_retouching_natural_rounded, 
              label: 'Avatar Builder', 
              color: Colors.purpleAccent,
              onTap: () { Navigator.pop(ctx); context.push('/profile/avatar-builder'); }
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    final localSettings = ref.read(localSettingsProvider);
    
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _nameController = TextEditingController(text: cleanCMSUsername(user.name));
        _contactController = TextEditingController(text: user.contactNumber ?? '');
        _departmentController = TextEditingController(text: user.department ?? '');
        
        // Use local settings if model fields are empty
        _fatherNameController = TextEditingController(
          text: (user.fatherName?.isNotEmpty == true) ? user.fatherName : localSettings.fatherName ?? ''
        );
        _regNoController = TextEditingController(
          text: (user.registrationNo?.isNotEmpty == true) ? user.registrationNo : localSettings.registrationNo ?? ''
        );
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _departmentController.dispose();
    _fatherNameController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isLoading = true);
    
    try {
      String? newPhotoUrl;
      // TASK: If a custom local image was selected, upload it to Storage first
      if (_pickedImage != null) {
        newPhotoUrl = await ref.read(storageServiceProvider).uploadAvatar(_pickedImage!, _user!.uid);
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        department: _departmentController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        registrationNo: _regNoController.text.trim(),
        photoURL: newPhotoUrl ?? _user!.photoURL, // Persist the new photo if uploaded
      );

      // Save to local settings too
      final localSettings = ref.read(localSettingsProvider);
      await localSettings.setFatherName(_fatherNameController.text.trim());
      await localSettings.setRegistrationNo(_regNoController.text.trim());

      await ref.read(authServiceProvider).updateUserProfile(_user!.uid, updatedUser.toMap());
      
      if (mounted) {
        showAppSnack(context, 'Profile updated successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Failed to save profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final accentInt = ref.watch(accentColorProvider);
    final accent = Color(accentInt);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.grey[50],
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.white,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : AppColors.navyDarkest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.file(_pickedImage!, fit: BoxFit.cover),
                            )
                          : UserAvatar(photoURL: _user?.photoURL, radius: 50),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDarkMode ? AppColors.navyDarkest : Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Basic Information', isDarkMode),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                isDarkMode: isDarkMode,
                accent: accent,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isDarkMode: isDarkMode,
                accent: accent,
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('CMS Identity', isDarkMode),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fatherNameController,
                label: 'Father Name',
                icon: Icons.family_restroom_outlined,
                isDarkMode: isDarkMode,
                accent: accent,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _regNoController,
                label: 'Registration Number',
                icon: Icons.badge_outlined,
                isDarkMode: isDarkMode,
                accent: accent,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _departmentController,
                label: 'Department',
                icon: Icons.school_outlined,
                isDarkMode: isDarkMode,
                accent: accent,
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDarkMode = false,
    required Color accent,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          icon: Icon(icon, color: accent.withOpacity(0.7)),
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
          border: InputTypeBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
      ),
    );
  }
}

class InputTypeBorder {
  static const none = InputBorder.none;
}
