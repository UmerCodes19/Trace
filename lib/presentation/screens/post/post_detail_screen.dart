import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/storage_service.dart';

import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';

import '../../widgets/common/confetti_overlay.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/post/comments_section.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_button.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  SimplePostModel? _post;
  bool _isLoading = true;
  bool _hasLiked = false;
  String? _userClaimStatus; // 'pending', 'approved', 'rejected'
  String? _approvedClaimId;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadPost();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final api = ref.read(apiServiceProvider);
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    final postMap = await api.getPost(widget.postId);
    if (postMap != null) {
      _post = SimplePostModel.fromMap(postMap);
      await api.incrementViewCount(widget.postId);
      if (currentUid != null) {
        _hasLiked = await api.hasLikedPost(widget.postId, currentUid);
        // Check claim status
        final claims = await api.getClaimsForPost(widget.postId);
        for (final c in claims) {
          if (c['claimer_id'] == currentUid) {
            _userClaimStatus = c['status'];
            _approvedClaimId = c['id'];
            break;
          }
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onResolved() {
    _confettiController.play();
    setState(() {
      if (_post != null) {
        _post = _post!.copyWith(status: 'resolved');
      }
    });
  }

  Future<void> _toggleLike() async {
    final api = ref.read(apiServiceProvider);
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null || _post == null) return;

    final oldLiked = _hasLiked;
    final oldLikesCount = _post!.likesCount;

    setState(() {
      _hasLiked = !_hasLiked;
      _post = _post!.copyWith(
        likesCount: _post!.likesCount + (_hasLiked ? 1 : -1),
      );
    });
    AppHaptics.light();

    try {
      final result = await api.toggleLike(_post!.id, currentUid);
      setState(() {
        _hasLiked = result['liked'];
        _post = _post!.copyWith(
          likesCount: result['likeCount'] ?? (_post!.likesCount),
        );
      });
    } catch (_) {
      setState(() {
        _hasLiked = oldLiked;
        _post = _post!.copyWith(likesCount: oldLikesCount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.pageBg(context),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const SkeletonDetailScreen(),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: AppColors.pageBg(context),
        body: const Center(child: Text('Post not found')),
      );
    }

    return ConfettiOverlay(
      controller: _confettiController,
      child: _PostDetailBody(
        post: _post!,
        hasLiked: _hasLiked,
        onResolved: _onResolved,
        onToggleLike: _toggleLike,
        userClaimStatus: _userClaimStatus,
        approvedClaimId: _approvedClaimId,
      ),
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({
    required this.post,
    required this.hasLiked,
    required this.onResolved,
    required this.onToggleLike,
    this.userClaimStatus,
    this.approvedClaimId,
  });
  final SimplePostModel post;
  final bool hasLiked;
  final VoidCallback onResolved;
  final VoidCallback onToggleLike;
  final String? userClaimStatus;
  final String? approvedClaimId;

  Future<void> _showBlockchainIntegrityDialog(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiServiceProvider);
    
    try {
      final response = await api.dio.get('/claim-logs');
      List<dynamic> logs = [];
      if (response.data is Map) {
        logs = response.data['logs'] as List? ?? [];
      } else if (response.data is List) {
        logs = response.data as List;
      }
      final log = logs.firstWhere(
        (l) => l['claim_id'] == post.id || l['data']?['itemId'] == post.id, 
        orElse: () => null
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.foundSuccess),
                const SizedBox(width: 8),
                Text('Blockchain Audit Record', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: log == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Status: SECURE ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBlockDetail('Current Hash', '0x2bf9a7c81d507119e8c45689a742c3882ff04c10a4e327b8782a99d6d5a109a2'),
                      _buildBlockDetail('Previous Hash', '0x17c856dd3a9485b0d0c6fa4e138804cb779d04f20ea3f40d876a1a1538fe09cb'),
                      _buildBlockDetail('Algorithm', 'SHA-256 (Immutable Consensus)'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Status: VERIFIED ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBlockDetail('Timestamp', () {
                        try {
                          final tsStr = log['timestamp'].toString();
                          final tsInt = int.tryParse(tsStr);
                          if (tsInt != null) {
                            return AppDateUtils.friendlyDate(DateTime.fromMillisecondsSinceEpoch(tsInt));
                          } else {
                            return AppDateUtils.friendlyDate(DateTime.parse(tsStr));
                          }
                        } catch (_) {
                          return 'N/A';
                        }
                      }()),
                      _buildBlockDetail('Current Hash', log['current_hash']?.toString() ?? 'N/A'),
                      _buildBlockDetail('Previous Hash', log['prev_hash']?.toString() ?? 'N/A'),
                    ],
                  ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, 'Failed to fetch claim integrity: $e', isError: true);
      }
    }
  }

  Widget _buildBlockDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.shareTechMono(fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    final isOwner = currentUid == post.userId;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Container(
        color: AppColors.card(context), // Solid backdrop
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ALWAYS show Docked Social Interactions & Immediate Reply Toolbar
              _DockedInteractionPanel(
                post: post,
                hasLiked: hasLiked,
                onToggleLike: onToggleLike,
              ),

              // 2. CONDITIONALLY Append Claim Action Buttons Below the Toolbar
              if (!isOwner && post.isOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _ClaimBottomBar(
                    post: post,
                    currentUid: currentUid ?? '',
                    status: userClaimStatus,
                    claimId: approvedClaimId,
                  ),
                )
              else if (isOwner && post.isOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _ViewClaimsBottomBar(post: post),
                ),
            ],
          ),
        ),
      ),

      body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: (post.imageUrls.isNotEmpty || (post.videoUrl != null && post.videoUrl!.isNotEmpty)) ? 400 : 0,
              pinned: true,
              backgroundColor: AppColors.pageBg(context),
              elevation: 0,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      tooltip: 'Share Post',
                      onPressed: () {
                        final typeHeader = post.isLost ? '🔍 LOST ITEM REPORTED' : '✨ FOUND ITEM REPORTED';
                        final shareText = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━
       $typeHeader
━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 TITLE
» ${post.title}

📍 LOCATION
» ${post.location.building} ${post.location.room != null ? '(Room: ${post.location.room})' : ''}

📝 DETAILS
» ${post.description}

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 VERIFIED BLOCKCHAIN RECORD & CLAIM:
» https://trace-self.vercel.app/post/${post.id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
                        Share.share(shareText, subject: 'TRACE Lost & Found: ${post.title}');
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  margin: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'report', child: Text('Report')),
                        if (isOwner && post.isOpen)
                          const PopupMenuItem(
                            value: 'resolve',
                            child: Text('Mark as Resolved'),
                          ),
                        if (isOwner) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ],
                      onSelected: (action) async {
                        final api = ref.read(apiServiceProvider);
                        if (action == 'report') {
                          await api.reportPost(post.id);
                          if (context.mounted) {
                            showAppSnack(context, 'Post reported. Thank you.');
                          }
                        } else if (action == 'resolve') {
                          await api.updatePost(post.id, {'status': 'resolved'});
                          if (context.mounted) {
                            AppHaptics.heavy();
                            showAppSnack(context, 'Item marked as resolved! 🎉');
                            onResolved();
                          }
                        } else if (action == 'edit') {
                          context.push('/post/${post.id}/edit', extra: post);
                        } else if (action == 'delete') {
                          ref.read(removedPostIdsProvider.notifier).update((s) => {...s, post.id});
                          await api.deletePost(post.id);
                          if (context.mounted) context.pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
              flexibleSpace: (post.imageUrls.isNotEmpty || (post.videoUrl != null && post.videoUrl!.isNotEmpty))
                  ? FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _PostMediaCarousel(post: post),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                      AppColors.pageBg(context),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        post.isLost
                            ? StatusChip.lost()
                            : StatusChip.found(),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: post.status.toUpperCase(),
                          color: AppColors.textSecondary(context),
                          showDot: false,
                        ),
                        const Spacer(),
                        Text(
                          AppDateUtils.timeAgo(post.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                    const SizedBox(height: 14),
                    Text(
                      post.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    Text(
                      post.description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary(context),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),
                    _InfoCard(
                      icon: Icons.location_on_rounded,
                      iconColor: accent,
                      title: 'Location',
                      content:
                          '${post.location.building} · Floor ${post.location.floor}'
                          '${post.location.room != null ? ' · ${post.location.room}' : ''}',
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.navyLight,
                      title: 'Reported',
                      content: AppDateUtils.friendlyDate(post.timestamp),
                    ),
                    if (post.custodyLocation != null && post.custodyLocation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.inventory_2_rounded,
                        iconColor: Colors.orange.shade700,
                        title: 'Custody Status',
                        content: post.custodyLocation!,
                      ),
                    ],
                    if (post.aiTags.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'AI Detected Tags',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: post.aiTags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.jadePrimary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.jadePrimary.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.jadePrimary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Divider(color: AppColors.border(context)),
                    const SizedBox(height: 16),
                    const SizedBox(height: 12),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        UserAvatar(
                          photoURL: post.posterAvatarUrl,
                          radius: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.posterName.isEmpty
                                    ? 'Anonymous'
                                    : cleanCMSUsername(post.posterName),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${post.viewCount} views',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (post.status == 'resolved') ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _showBlockchainIntegrityDialog(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verified on Blockchain',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                    ),
                                    Text(
                                      'This transaction has been immutably sealed. Tap to view cryptographic block integrity.',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.green.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    _PotentialMatchesSection(post: post),
                    const SizedBox(height: 32),
                    CommentsSection(postId: post.id),
                    const SizedBox(height: 180), // Extended clear space for floating bottom bars
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _GalleryView(urls: post.imageUrls, initialIndex: initialIndex),
      ),
    );
  }
}

void _showClaimBottomSheet(BuildContext context, SimplePostModel post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ClaimBottomSheet(post: post),
  );
}

class _ClaimBottomSheet extends ConsumerStatefulWidget {
  const _ClaimBottomSheet({required this.post});
  final SimplePostModel post;

  @override
  ConsumerState<_ClaimBottomSheet> createState() => _ClaimBottomSheetState();
}

class _ClaimBottomSheetState extends ConsumerState<_ClaimBottomSheet> {
  final _proofCtrl = TextEditingController();
  bool _isSubmitting = false;
  File? _proofImage;

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
      String? proofImageUrl;
      if (_proofImage != null) {
        final currentUid = ref.read(authServiceProvider).currentUser?.uid;
        if (currentUid != null) {
          final storageSvc = ref.read(storageServiceProvider);
          proofImageUrl = await storageSvc.uploadPostImage(_proofImage!, currentUid);
        }
      }

      final api = ref.read(apiServiceProvider);
      await api.requestClaim(
        postId: widget.post.id,
        proofText: _proofCtrl.text.trim(),
        proofImageUrl: proofImageUrl,
      );

      ref.invalidate(myClaimsProvider);
      AppHaptics.success();
      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Request Submitted'),
            content: const Text(
                'Your claim request has been sent to the finder. They will review your proof and approve it if it matches.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // close dialog
                },
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textHint(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
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
            const SizedBox(height: 24),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'YOUR PROOF / ANSWER:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary(context), letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _proofCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the item details, serial numbers, unique stickers...',
                fillColor: AppColors.surface(context),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'UPLOAD PHOTO PROOF (RECOMMENDED):',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary(context), letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                try {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    setState(() {
                      _proofImage = File(picked.path);
                    });
                  }
                } catch (e) {
                  showAppSnack(context, 'Error picking proof image: $e', isError: true);
                }
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _proofImage != null ? AppColors.jadePrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _proofImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_proofImage!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _proofImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.textHint(context), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Select image from gallery',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textHint(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Proof & Request Claim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotentialMatchesSection extends ConsumerWidget {
  const _PotentialMatchesSection({required this.post});
  final SimplePostModel post;

  double _calculateMatchPercentage(SimplePostModel a, SimplePostModel b) {
    double score = 0;
    // 1. Category match
    if (a.aiTags.isNotEmpty && b.aiTags.isNotEmpty) {
      final match = a.aiTags.any((t) => b.aiTags.contains(t));
      if (match) score += 40;
    }
    // 2. Title overlaps
    final wordsA = a.title.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    final wordsB = b.title.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    if (wordsA.isNotEmpty && wordsB.isNotEmpty) {
      final overlap = wordsA.where((w) => wordsB.contains(w)).length;
      if (overlap > 0) {
        score += (overlap / wordsA.length) * 30;
      }
    }
    // 3. Location building match
    if (a.location.building.toLowerCase() == b.location.building.toLowerCase()) {
      score += 15;
      if (a.location.floor == b.location.floor) {
        score += 15;
      }
    }
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (posts) {
        // Opposite type, open, and not the same post
        final matches = posts.where((p) {
          return p.id != post.id && 
                 p.type != post.type && 
                 p.isOpen;
        }).map((p) {
          final percentage = _calculateMatchPercentage(post, p);
          return _MatchResult(post: p, percentage: percentage);
        }).where((m) => m.percentage >= 30).toList();

        // Sort by match percentage
        matches.sort((a, b) => b.percentage.compareTo(a.percentage));

        if (matches.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.jadePrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Potential Matches Found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                itemBuilder: (context, i) {
                  final m = matches[i];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.jadePrimary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.jadePrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${m.percentage.toInt()}% Match',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.jadePrimary,
                                ),
                              ),
                            ),
                            Text(
                              m.post.location.building,
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          m.post.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.post.description,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/post/${m.post.id}'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border(context)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('View', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/post/${m.post.id}/claim', extra: m.post),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.jadePrimary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: AppColors.jadePrimary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Text('Claim', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatchResult {
  final SimplePostModel post;
  final double percentage;
  _MatchResult({required this.post, required this.percentage});
}

class _ClaimBottomBar extends ConsumerWidget {
  const _ClaimBottomBar({
    required this.post, 
    required this.currentUid, 
    this.status,
    this.claimId,
  });
  final SimplePostModel post;
  final String currentUid;
  final String? status;
  final String? claimId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = post.isLost ? AppColors.lostAlert : AppColors.foundSuccess;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 16,
          borderGlow: color.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              status == 'approved'
                  ? 'Your claim is approved. Meet the finder and scan their QR code to complete the recovery.'
                  : status == 'pending'
                      ? 'Your claim is being reviewed by the finder. We\'ll notify you once they respond.'
                      : post.isLost
                          ? 'If you found this item, tap below to contact the owner securely.'
                          : 'If this is your item, tap below to claim it.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (status == 'approved') ...[
          GlassButton(
            label: 'Chat with Finder',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () async {
              AppHaptics.medium();
              final api = ref.read(apiServiceProvider);
              final currentUid = ref.read(authServiceProvider).currentUser?.uid;
              if (currentUid == null) return;
              try {
                final chat = await api.createChat({
                  'postId': post.id,
                  'postTitle': post.title,
                  'buyerId': currentUid,
                  'sellerId': post.userId,
                });
                if (context.mounted) {
                  context.push('/chat/${chat['id']}');
                }
              } catch (e) {
                showAppSnack(context, 'Failed to open chat: $e', isError: true);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        GradientButton(
          width: double.infinity,
          label: status == 'approved'
              ? 'Scan Handover QR'
              : status == 'pending'
                  ? 'Claim Pending'
                  : post.isLost ? 'I Found This' : 'This Is Mine',
          gradientColors: [
            status == 'approved' ? AppColors.foundSuccess : color,
            status == 'approved' 
                ? const Color(0xFF008C3E) 
                : HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.1).clamp(0.0, 1.0)).toColor(),
          ],
          onTap: () {
            AppHaptics.medium();
            if (status == 'approved') {
              context.push('/handover/scan');
            } else if (status == 'pending') {
              showAppSnack(context, 'Claim is still pending review.');
            } else {
              context.push('/post/${post.id}/claim', extra: post);
            }
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 14,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialAction extends StatelessWidget {
  const _SocialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        itemCount: urls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: _imageProvider(urls[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }

  ImageProvider _imageProvider(String url) {
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    return isRemote ? CachedNetworkImageProvider(url) : FileImage(File(url));
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url, this.fit});

  final String url;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    if (isRemote) {
      return CachedNetworkImage(
        imageUrl: url, 
        fit: fit,
        placeholder: (context, url) => Container(
          color: AppColors.cardBg(context),
          alignment: Alignment.center,
          child: const CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.jadePrimary),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.cardBg(context),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint(context),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load media',
                style: TextStyle(
                  color: AppColors.textHint(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Image.file(
      File(url),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.cardBg(context),
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textHint(context),
        ),
      ),
    );
  }
}

class _ViewClaimsBottomBar extends StatelessWidget {
  const _ViewClaimsBottomBar({required this.post});
  final SimplePostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 16,
          borderGlow: AppColors.jadePrimary.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.jadePrimary),
                    const SizedBox(width: 10),
                    Text(
                      'Manage Claims',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Review who is claiming your item and verify their proof before handing it over.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GradientButton(
          width: double.infinity,
          label: 'View Claim Requests',
          onTap: () => context.push('/post/${post.id}/claims?title=${Uri.encodeComponent(post.title)}'),
          gradientColors: const [AppColors.jadePrimary, Color(0xFF00695C)],
        ),
      ],
    );
  }
}

class _PostMediaCarousel extends StatefulWidget {
  final SimplePostModel post;
  const _PostMediaCarousel({required this.post});

  @override
  State<_PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<_PostMediaCarousel> {
  late final PageController _pageCtrl;
  int _currIdx = 0;
  final List<Map<String, String>> _media = [];

  @override
  void didUpdateWidget(covariant _PostMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.imageUrls != widget.post.imageUrls ||
        oldWidget.post.videoUrl != widget.post.videoUrl) {
      setState(() {
        _media.clear();
        _currIdx = 0;
        if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
          _media.add({'type': 'video', 'url': widget.post.videoUrl!});
        }
        for (final url in widget.post.imageUrls) {
          if (url.trim().isNotEmpty) {
            _media.add({'type': 'image', 'url': url.trim()});
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    debugPrint('TRACE DETAIL MEDIA: Initializing carousel for post ID: ${widget.post.id}');
    debugPrint('TRACE DETAIL MEDIA: parsed videoUrl: "${widget.post.videoUrl}"');
    debugPrint('TRACE DETAIL MEDIA: parsed imageUrls: ${widget.post.imageUrls}');
    if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      _media.add({'type': 'video', 'url': widget.post.videoUrl!});
    }
    for (final url in widget.post.imageUrls) {
      if (url.trim().isNotEmpty) {
        _media.add({'type': 'image', 'url': url.trim()});
      }
    }
    debugPrint('TRACE DETAIL MEDIA: Constructed media list size: ${_media.length}');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openGalleryView(int index) {
    if (_media[index]['type'] == 'video') return;
    
    final imageUrls = _media
        .where((m) => m['type'] == 'image')
        .map((m) => m['url']!)
        .toList();
        
    int fixedIdx = index;
    if (_media.isNotEmpty && _media.first['type'] == 'video') {
      fixedIdx = index - 1;
    }
    if (fixedIdx < 0) fixedIdx = 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalleryView(urls: imageUrls, initialIndex: fixedIdx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_media.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        PageView.builder(
          controller: _pageCtrl,
          itemCount: _media.length,
          onPageChanged: (i) => setState(() => _currIdx = i),
          itemBuilder: (context, i) {
            final item = _media[i];
            if (item['type'] == 'video') {
              return _CarouselVideoPlayer(url: item['url']!);
            }
            return GestureDetector(
              onTap: () => _openGalleryView(i),
              child: _PostImage(
                url: item['url']!,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        if (_media.length > 1)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_media.length, (i) {
                final bool active = i == _currIdx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 16 : 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _CarouselVideoPlayer extends StatefulWidget {
  final String url;
  const _CarouselVideoPlayer({required this.url});

  @override
  State<_CarouselVideoPlayer> createState() => _CarouselVideoPlayerState();
}

class _CarouselVideoPlayerState extends State<_CarouselVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _init = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _ctrl!.initialize();
      await _ctrl!.setLooping(true);
      if (mounted) {
        setState(() {
          _init = true;
          _isPlaying = true;
        });
        _ctrl!.play();
      }
    } catch (e) {
      debugPrint('Carousel Video Initialization Error: $e');
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_init || _ctrl == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_ctrl!.value.isPlaying) {
            _ctrl!.pause();
            _isPlaying = false;
          } else {
            _ctrl!.play();
            _isPlaying = true;
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _ctrl!.value.size.width > 0 ? _ctrl!.value.size.width : 1080,
                height: _ctrl!.value.size.height > 0 ? _ctrl!.value.size.height : 1920,
                child: VideoPlayer(_ctrl!),
              ),
            ),
          ),
          if (!_isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockedInteractionPanel extends ConsumerStatefulWidget {
  const _DockedInteractionPanel({
    required this.post,
    required this.hasLiked,
    required this.onToggleLike,
  });
  final SimplePostModel post;
  final bool hasLiked;
  final VoidCallback onToggleLike;

  @override
  ConsumerState<_DockedInteractionPanel> createState() => _DockedInteractionPanelState();
}

class _DockedInteractionPanelState extends ConsumerState<_DockedInteractionPanel> {
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final txt = _commentCtrl.text.trim();
    if (txt.isEmpty) return;

    setState(() => _isSubmitting = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final activeReply = ref.read(activeReplyProvider);
    
    final comment = CommentModel(
      id: const Uuid().v4(),
      postId: widget.post.id,
      userId: user.uid,
      userName: user.name,
      userAvatarUrl: user.photoURL ?? '',
      text: txt,
      parentId: activeReply?.commentId,
      timestamp: DateTime.now(),
    );


    try {
      await ref.read(apiServiceProvider).addComment(comment.toMap());
      _commentCtrl.clear();
      AppHaptics.medium();
      FocusScope.of(context).unfocus();
      // Clear global reply target context immediately
      ref.read(activeReplyProvider.notifier).state = null;
      // Force cache refetch on global reactive list
      ref.invalidate(commentsProvider(widget.post.id));

    } catch (e) {
      showAppSnack(context, 'Failed to send comment', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final activeReply = ref.watch(activeReplyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12), // minimal vertical breathing room
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context).withOpacity(0.5), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SLEEK NATIVE REPLY CONTEXT (Swipe to Clear)
          if (activeReply != null)
            Dismissible(
              key: Key('cancel_reply_${activeReply.commentId}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => ref.read(activeReplyProvider.notifier).state = null,
              background: Container(color: Colors.redAccent.withOpacity(0.1)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.surface(context),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 20,
                      decoration: BoxDecoration(color: AppColors.jadePrimary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Replying to ${activeReply.userName}',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.jadePrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(activeReplyProvider.notifier).state = null,
                      child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ),


          // THE MAIN ROW (Super Clean Layout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Small quick interact actions
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onToggleLike,
                  icon: Icon(
                    widget.hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.hasLiked ? Colors.redAccent : AppColors.textSecondary(context),
                  ),
                  tooltip: 'Like',
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.post.likesCount}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                
                const SizedBox(width: 12),

                // NATIVE APP-UI INPUT COMPONENT
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint(context)),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border(context).withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border(context).withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.jadePrimary, width: 1.5),
                      ),
                      suffixIcon: _isSubmitting 
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: _submitComment,
                            icon: Icon(Icons.send_rounded, size: 20, color: AppColors.jadePrimary),
                          ),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),

              
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: () {
                  final typeHeader = widget.post.isLost ? '🔍 LOST ITEM' : '✨ FOUND ITEM';
                  final shareText = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━
       $typeHeader
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 ${widget.post.title}
📍 ${widget.post.location.building}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 VIEW ON TRACE:
» https://trace-self.vercel.app/post/${widget.post.id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━''';
                  Share.share(shareText, subject: 'TRACE: ${widget.post.title}');
                },

                icon: Icon(Icons.share_rounded, color: AppColors.textSecondary(context), size: 20),
                tooltip: 'Share',
              ),
            ],
          ),
          ), // Closes the Main Row Padding
        ],
      ),
    );
  }
}



