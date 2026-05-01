import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class ClaimRequestScreen extends ConsumerStatefulWidget {
  const ClaimRequestScreen({super.key, required this.post});
  final SimplePostModel post;

  @override
  ConsumerState<ClaimRequestScreen> createState() => _ClaimRequestScreenState();
}

class _ClaimRequestScreenState extends ConsumerState<ClaimRequestScreen> {
  final _proofCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _proofCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (_proofCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Please provide proof of ownership', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      
      // Phase 2: Submit claim request to backend
      await api.requestClaim(
        postId: widget.post.id,
        proofText: _proofCtrl.text.trim(),
      );

      ref.invalidate(myClaimsProvider);
      AppHaptics.success();
      final screenContext = context;
      if (mounted) {
        showDialog(
          context: screenContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('✨ Request Submitted'),
            content: const Text(
                'Your claim request has been sent to the finder. They will review your proof and approve it if it matches.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // close dialog
                  if (screenContext.mounted) {
                    screenContext.pop(); // return to detail
                  }
                },
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting claim: $e');
      if (mounted) {
        showAppSnack(context, 'Failed to submit claim: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.post.isLost ? AppColors.lostAlert : AppColors.foundSuccess;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Claim Item', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_outlined, color: color, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Ownership Verification',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'The finder has set a security gatekeeper. To claim this item, please answer the question or provide a unique detail that only the owner would know.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (widget.post.secretDetailQuestion != null) ...[
            Text(
              'QUESTION FROM FINDER:',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.secretDetailQuestion!,
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'YOUR PROOF / ANSWER:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary(context), letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _proofCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the item details, serial numbers, unique stickers, or any other proof...',
              fillColor: AppColors.cardBg(context),
              filled: true,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Proof & Request Claim', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
