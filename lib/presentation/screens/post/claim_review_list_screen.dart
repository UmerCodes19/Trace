import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class ClaimReviewListScreen extends ConsumerStatefulWidget {
  const ClaimReviewListScreen({super.key, required this.postId, required this.postTitle});
  final String postId;
  final String postTitle;

  @override
  ConsumerState<ClaimReviewListScreen> createState() => _ClaimReviewListScreenState();
}

class _ClaimReviewListScreenState extends ConsumerState<ClaimReviewListScreen> {
  bool _isLoading = true;
  List<dynamic> _claims = [];

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    final api = ref.read(apiServiceProvider);
    try {
      final data = await api.getClaimsForPost(widget.postId);
      if (mounted) {
        setState(() {
          _claims = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(String claimId, String status) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.respondToClaim(claimId, status);
      showAppSnack(context, 'Claim ${status == 'approved' ? 'approved' : 'rejected'}');
      _loadClaims(); // Reload list
    } catch (e) {
      showAppSnack(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Claim Requests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _claims.length,
                  itemBuilder: (context, index) {
                    final claim = _claims[index];
                    final user = claim['users'];
                    final status = claim['status'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.jadePrimary.withOpacity(0.1),
                                child: Text(user['name']?[0] ?? '?'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(user['email'] ?? '', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                                  ],
                                ),
                              ),
                              _StatusBadge(status: status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('OWNERSHIP PROOF:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                            claim['proof_text'] ?? 'No proof provided',
                            style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                          ),
                          if (status == 'pending') ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _respond(claim['id'], 'rejected'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _respond(claim['id'], 'approved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.jadePrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (status == 'approved') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final api = ref.read(apiServiceProvider);
                                  final currentUid = ref.read(authServiceProvider).currentUser?.uid;
                                  if (currentUid == null) return;
                                  try {
                                    final chat = await api.createChat({
                                      'postId': widget.postId,
                                      'postTitle': widget.postTitle,
                                      'buyerId': claim['claimer_id'],
                                      'sellerId': currentUid,
                                    });
                                    if (context.mounted) {
                                      context.push('/chat/${chat['id']}');
                                    }
                                  } catch (e) {
                                    showAppSnack(context, 'Failed to open chat');
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: const Text('💬 Chat with Claimer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.jadePrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/handover/qr', extra: {
                                    'claimId': claim['id'],
                                    'itemTitle': widget.postTitle,
                                    'claimerName': user['name'] ?? 'User',
                                  });
                                },
                                icon: const Icon(Icons.qr_code_rounded, size: 18),
                                label: const Text('Start Coordination'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navyLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint(context)),
          const SizedBox(height: 16),
          Text('No claim requests yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textSecondary(context))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'approved') color = AppColors.foundSuccess;
    if (status == 'rejected') color = AppColors.lostAlert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
