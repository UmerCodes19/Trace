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
      
      // Calculate heuristic match score for sorting
      final scoredData = data.map((claim) {
        final proofText = claim['proof_text']?.toString() ?? '';
        final score = _calculateScore(proofText, widget.postTitle);
        return {
          ...claim,
          '_score': score,
        };
      }).toList();

      // Sort by score in descending order
      scoredData.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));

      if (mounted) {
        setState(() {
          _claims = scoredData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateScore(String proof, String title) {
    int score = 0;
    if (proof.length > 20) score += 20;
    if (proof.length > 50) score += 30;

    final wordsProof = proof.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    final wordsTitle = title.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();

    for (final word in wordsTitle) {
      if (word.length > 3 && wordsProof.contains(word)) {
        score += 25;
      }
    }
    return score;
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

  void _showSideBySideComparison() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Side-by-Side Comparison', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: _claims.length,
            separatorBuilder: (_, __) => const VerticalDivider(width: 24, thickness: 1),
            itemBuilder: (context, index) {
              final claim = _claims[index];
              final user = claim['users'];
              final score = claim['_score'] as int;

              return Container(
                width: 240,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.jadePrimary.withOpacity(0.1),
                          child: Text(user['name']?[0] ?? '?'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Match: $score pts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: index == 0 ? Colors.green : Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('OWNERSHIP PROOF:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          claim['proof_text'] ?? 'No proof',
                          style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (claim['status'] == 'pending')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _respond(claim['id'], 'approved');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jadePrimary,
                          minimumSize: const Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Approve', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Claim Requests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        actions: [
          if (_claims.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_rounded),
              onPressed: _showSideBySideComparison,
              tooltip: 'Compare Side-by-Side',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    if (_claims.length >= 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: GestureDetector(
                          onTap: _showSideBySideComparison,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.jadePrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.jadePrimary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.compare_arrows_rounded, color: AppColors.jadePrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Multi-Claim Comparison Active',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.jadePrimary),
                                  ),
                                ),
                                Text(
                                  'Compare Side-by-Side',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.jadePrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _claims.length,
                        itemBuilder: (context, index) {
                          final claim = _claims[index];
                          final user = claim['users'];
                          final status = claim['status'];
                          final isBestMatch = index == 0 && _claims.length >= 2;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isBestMatch ? AppColors.jadePrimary : AppColors.border(context),
                                width: isBestMatch ? 1.5 : 1.0,
                              ),
                              boxShadow: isBestMatch ? [
                                BoxShadow(
                                  color: AppColors.jadePrimary.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
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
                                          Row(
                                            children: [
                                              Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              if (isBestMatch) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.jadePrimary,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text('✨ BEST MATCH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                                                ),
                                              ],
                                            ],
                                          ),
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
                    ),
                  ],
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
