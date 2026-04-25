import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authServiceProvider).getCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary(context), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('My QR Code',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<SimpleUserModel?>(
        future: userAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonQrCode();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return _QrBody(user: user);
        },
      ),
    );
  }
}

class _QrBody extends StatefulWidget {
  const _QrBody({required this.user});
  final SimpleUserModel user;

  @override
  State<_QrBody> createState() => _QrBodyState();
}

class _QrBodyState extends State<_QrBody> {
  late Set<String> _visible;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _visible = {'name', 'email'}.toSet();
  }

  String get _qrData {
    final map = <String, String>{};
    if (_visible.contains('name') && widget.user.name.isNotEmpty) {
      map['name'] = widget.user.name;
    }
    if (_visible.contains('email') && widget.user.email.isNotEmpty) {
      map['email'] = widget.user.email;
    }
    if (_visible.contains('contact') &&
        widget.user.contactNumber != null) {
      map['contact'] = widget.user.contactNumber!;
    }
    if (_visible.contains('department') && widget.user.department != null) {
      map['department'] = widget.user.department!;
    }
    return jsonEncode(map);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Warning banner
          GlassCard(
            borderRadius: 14,
            borderGlow: AppColors.lostAlert.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.lostAlert, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only share this QR code when claiming an item. Keep it private otherwise.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.lostAlert,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // QR card
          GlassCard(
            elevation: 3,
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: isDark ? AppColors.navyDarkest : accent,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: isDark ? AppColors.navyDarkest : accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  if (widget.user.isCMSVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppColors.foundSuccess, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Bahria University · CMS Verified',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.foundSuccess,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Visible Information',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldToggle(
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            isEnabled: _visible.contains('name'),
            onToggle: () => _toggle('name'),
          ),
          _FieldToggle(
            label: 'Email Address',
            icon: Icons.email_outlined,
            isEnabled: _visible.contains('email'),
            onToggle: () => _toggle('email'),
          ),
          _FieldToggle(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            isEnabled: _visible.contains('contact'),
            onToggle: () => _toggle('contact'),
          ),
          _FieldToggle(
            label: 'Department',
            icon: Icons.school_outlined,
            isEnabled: _visible.contains('department'),
            onToggle: () => _toggle('department'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share QR Code'),
              onPressed: _shareQrCode,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Lost & Found QR Code for ${widget.user.name}',
      );
    } catch (e) {
      debugPrint('Error sharing QR: $e');
    }
  }

  void _toggle(String field) {
    setState(() {
      if (_visible.contains(field)) {
        _visible.remove(field);
      } else {
        _visible.add(field);
      }
    });
  }
}

class _FieldToggle extends StatelessWidget {
  const _FieldToggle({
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
  });
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 14,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary(context))),
              ),
              Switch(
                value: isEnabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}