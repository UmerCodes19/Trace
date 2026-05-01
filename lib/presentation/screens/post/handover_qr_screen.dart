import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class HandoverQrScreen extends StatelessWidget {
  const HandoverQrScreen({
    super.key,
    required this.claimId,
    required this.itemTitle,
    required this.claimerName,
  });

  final String claimId;
  final String itemTitle;
  final String claimerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: const Text('Handover Handshake'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show this to $claimerName',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'They need to scan this to finalize the recovery of "$itemTitle"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: QrImageView(
                  data: 'trace_handshake:$claimId',
                  version: QrVersions.auto,
                  size: 240.0,
                  foregroundColor: AppColors.deepJade,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Do not close this screen until the other person has scanned it and their app shows a success message.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
