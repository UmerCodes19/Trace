import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_settings_service.dart';
import '../../widgets/common/glass_card.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authServiceProvider).getCurrentUser();
    final isDarkMode = ref.watch(themeProvider);
    final accentInt = ref.watch(accentColorProvider);
    final accent = Color(accentInt);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.navyDarkest : Colors.grey[50],
      appBar: AppBar(
        title: Text('Digital Identity QR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : AppColors.navyDarkest,
      ),
      body: FutureBuilder<SimpleUserModel?>(
        future: userAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) return const Center(child: Text('Please log in'));

          // Point to the public profile website
          final qrData = 'https://trace-self.vercel.app/profile/${user.uid}';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scan to View Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.navyDarkest,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share this QR code with others to let them quickly view your digital campus identity.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 32,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 240,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.navyDarkest,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.navyDarkest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.navyDarkest,
                        ),
                      ),
                      Text(
                        user.cmsStudentId ?? 'Student ID Not Linked',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () {
                    // Share logic would go here
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}