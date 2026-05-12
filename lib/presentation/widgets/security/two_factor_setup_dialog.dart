import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../data/services/auth_service.dart';

class TwoFactorSetupDialog extends ConsumerStatefulWidget {
  const TwoFactorSetupDialog({super.key});

  static Future<dynamic> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TwoFactorSetupDialog(),
    );
  }

  @override
  ConsumerState<TwoFactorSetupDialog> createState() => _TwoFactorSetupDialogState();
}

class _TwoFactorSetupDialogState extends ConsumerState<TwoFactorSetupDialog> {
  late final String _secret;
  late final String _qrUri;
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _secret = TwoFactorService.generateSecret();
    _qrUri = TwoFactorService.generateQrUri(
      email: user?.email ?? 'user@trace.com',
      secret: _secret,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyAndEnable() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter exactly 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Small deterministic UX pause for realism
    await Future.delayed(const Duration(milliseconds: 600));

    final isValid = TwoFactorService.verifyCode(_secret, code);

    if (!isValid) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = 'Invalid code. Please try again.';
        });
        HapticFeedback.vibrate();
      }
      return;
    }

    // Code verified! Update user record persistently.
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final updatedUser = user.copyWith(
          isTwoFactorEnabled: true,
          twoFactorSecret: _secret,
        );
        await ref.read(authServiceProvider).updateUserProfile(user.uid, updatedUser.toMap());
      }
      
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
        });
        HapticFeedback.heavyImpact();
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
       if (mounted) {
         setState(() {
           _isVerifying = false;
           _error = 'Network error saving settings.';
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.pageBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textSecondary(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            if (!_isSuccess) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enhance Security',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Enable Two-Factor Authentication',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.card(context),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              _buildStep(1, 'Scan this QR code in Google Authenticator or standard auth apps.'),
              
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: QrImageView(
                  data: _qrUri,
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
              ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _secret));
                  showAppSnack(context, 'Secret copied to clipboard!');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_outlined, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Can\'t scan? Tap to copy key',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _buildStep(2, 'Enter the 6-digit code to verify.'),
              
              const SizedBox(height: 12),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: AppColors.textPrimary(context),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.3)),
                  errorText: _error,
                  filled: true,
                  fillColor: AppColors.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyAndEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Verify & Enable', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Maybe Later', style: GoogleFonts.inter(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              Text(
                '2FA Secured!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is now protected with Two-Factor Auth.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text('$num', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}
