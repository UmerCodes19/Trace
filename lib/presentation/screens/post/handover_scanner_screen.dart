import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/services/api_service.dart';

class HandoverScannerScreen extends ConsumerStatefulWidget {
  const HandoverScannerScreen({super.key});

  @override
  ConsumerState<HandoverScannerScreen> createState() => _HandoverScannerScreenState();
}

class _HandoverScannerScreenState extends ConsumerState<HandoverScannerScreen> {
  bool _isVerifying = false;
  bool _hasFound = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasFound || _isVerifying) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('trace_handshake:')) {
        setState(() {
          _hasFound = true;
          _isVerifying = true;
        });
        
        final claimId = code.split(':')[1];
        await _verifyHandshake(claimId);
        break;
      }
    }
  }

  Future<void> _verifyHandshake(String claimId) async {
    final api = ref.read(apiServiceProvider);
    try {
      final result = await api.verifyHandshake(claimId);
      
      if (mounted) {
        AppHaptics.success();
        _showSuccessDialog(result['message'] ?? 'Recovery successful!');
      }
    } catch (e) {
      debugPrint('Handshake verification failed: $e');
      if (mounted) {
        showAppSnack(context, 'Verification failed: $e', isError: true);
        setState(() {
          _hasFound = false;
          _isVerifying = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 100, color: AppColors.foundSuccess),
            const SizedBox(height: 16),
            Text(
              '🎉 Item Recovered!',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jadePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Handover QR'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Scanner Overlay UI
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Point your camera at the QR code on the finder\'s phone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          if (_isVerifying)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.jadePrimary),
                    SizedBox(height: 20),
                    Text('Verifying Handshake...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
