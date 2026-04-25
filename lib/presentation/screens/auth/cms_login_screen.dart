// lib/presentation/screens/auth/cms_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/cms_auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class CmsLoginScreen extends ConsumerStatefulWidget {
  const CmsLoginScreen({super.key});

  @override
  ConsumerState<CmsLoginScreen> createState() => _CmsLoginScreenState();
}

class _CmsLoginScreenState extends ConsumerState<CmsLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enrollmentCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  String _selectedInstitute = '2'; // Karachi Campus default
  String _selectedRole = 'None';   // Student default
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Map<String, String> _institutes = {
    '1': 'Islamabad E-8 Campus',
    '2': 'Karachi Campus',
    '3': 'Lahore Campus',
    '13': 'Bahria University College of Nursing',
  };

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final cmsService = CMSAuthService();
      final session = await cmsService.login(
        enrollment: _enrollmentCtrl.text.trim(),
        password: _passwordCtrl.text,
        instituteId: _selectedInstitute,
        role: _selectedRole,
      );

      if (!mounted) return;

      if (session != null) {
        // Save to cloud
        final api = ref.read(apiServiceProvider);
        final auth = ref.read(authServiceProvider);
        final currentUser = auth.currentUser;
        
        if (currentUser != null) {
          // Update user verification status in cloud
          await api.syncUser({
            ...currentUser.toMap(),
            'isCMSVerified': 1,
            'cmsStudentId': session.enrollment,
          });

          // Save timetable to cloud
          if (session.timetable.isNotEmpty) {
            await api.saveTimetable(
              session.enrollment,
              session.timetable.map((e) => e.toMap()).toList(),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ CMS Verified! Redirecting...')),
          );
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Login failed. Check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CMS Login',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.beigeWarm,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'CMS Portal Login',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your Bahria CMS credentials to verify your student status.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 32),

                // Enrollment
                TextFormField(
                  controller: _enrollmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Number',
                    hintText: 'e.g., 02-131232-108',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enrollment number required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'CMS Portal Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Institute
                DropdownButtonFormField<String>(
                  initialValue: _selectedInstitute,

                  decoration: const InputDecoration(
                    labelText: 'Campus / Institute',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _institutes.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedInstitute = v!),
                ),
                const SizedBox(height: 16),

                // Role
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'None', child: Text('Student')),
                    DropdownMenuItem(value: 'Parents', child: Text('Parent')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify & Continue'),
                ),

                const SizedBox(height: 24),

                // Info note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lostAlertBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.lostAlert),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your credentials are encrypted and only used to verify student status. We never store your password.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.lostAlert,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}