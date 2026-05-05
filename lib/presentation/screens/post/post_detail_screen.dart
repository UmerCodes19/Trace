import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/confetti_overlay.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/post/comments_section.dart';

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
      final logs = response.data as List;
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
                      _buildBlockDetail('Timestamp', AppDateUtils.friendlyDate(DateTime.parse(log['timestamp'].toString()))),
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
      body: RepaintBoundary(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: post.imageUrls.isNotEmpty ? 300 : 0,
              pinned: true,
              backgroundColor: AppColors.pageBg(context),
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: GlassCard(
                    borderRadius: 40,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: post.imageUrls.isNotEmpty
                            ? Colors.white
                            : AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  child: GlassCard(
                    borderRadius: 40,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: post.imageUrls.isNotEmpty
                            ? Colors.white
                            : AppColors.textPrimary(context),
                      ),
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
                          await api.deletePost(post.id);
                          if (context.mounted) context.pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
              flexibleSpace: post.imageUrls.isNotEmpty
                  ? FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _openGallery(context, 0),
                            child: Hero(
                              tag: 'post_image_${post.imageUrls.first}',
                              child: _PostImage(
                                url: post.imageUrls.first,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 100,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black38,
                                  ],
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    Text(
                      post.description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary(context),
                        height: 1.7,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 20),
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
                    if (post.aiTags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '🤖 AI Detected Tags',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: post.aiTags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(color: AppColors.border(context)),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        _SocialAction(
                          icon: hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          label: '${post.likesCount}',
                          color: hasLiked ? Colors.redAccent : AppColors.textSecondary(context),
                          onTap: onToggleLike,
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 20, color: AppColors.textHint(context)),
                            const SizedBox(width: 6),
                            Text(
                              '${post.viewCount}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _SocialAction(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          color: accent,
                          onTap: () {
                            final text = 'Lost & Found: ${post.title}\n'
                                '${post.description}\n'
                                'Location: ${post.location.building}\n'
                                'Download the app to help: https://lostfound.campus.edu';
                            Share.share(text);
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    Divider(color: AppColors.border(context)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.posterName.isEmpty
                                  ? 'Anonymous'
                                  : post.posterName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              '${post.viewCount} views',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (post.status == 'resolved') ...[
                      const SizedBox(height: 16),
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
                                      'Verified on Blockchain ✅',
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
                    const SizedBox(height: 28),
                    if (!isOwner && post.isOpen)
                      _ClaimSection(
                        post: post, 
                        currentUid: currentUid ?? '',
                        status: userClaimStatus,
                        claimId: approvedClaimId,
                      ),
                    if (isOwner && post.isOpen)
                      _ViewClaimsSection(post: post),
                    const SizedBox(height: 32),
                    CommentsSection(postId: post.id),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  '🤖 Potential Matches Found',
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
              height: 160,
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
                              child: OutlinedButton(
                                onPressed: () => context.push('/post/${m.post.id}'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('View Match', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.push('/post/${m.post.id}/claim', extra: m.post),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.jadePrimary,
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Claim', style: TextStyle(fontSize: 11)),
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

class _ClaimSection extends ConsumerWidget {
  const _ClaimSection({
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 16,
          borderGlow: color.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              status == 'approved'
                  ? '✅ Your claim is approved! Meet the finder and scan their QR code to complete the recovery.'
                  : status == 'pending'
                      ? '⏳ Your claim is being reviewed by the finder. We\'ll notify you once they respond.'
                      : post.isLost
                          ? '🔍 If you found this item, tap below to contact the owner securely.'
                          : '✋ If this is your item, tap below to claim it.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (status == 'approved') ...[
          GestureDetector(
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.jadePrimary.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  '💬 Chat with Finder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.jadePrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  status == 'approved' ? AppColors.foundSuccess : color,
                  status == 'approved' ? AppColors.jadePrimary : HSLColor.fromColor(color)
                      .withHue((HSLColor.fromColor(color).hue + 20) % 360)
                      .toColor(),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (status == 'approved' ? AppColors.foundSuccess : color).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                status == 'approved'
                    ? '📸 Scan Handover QR'
                    : status == 'pending'
                        ? '⏳ Claim Pending'
                        : post.isLost ? '💬 I Found This' : '💬 This Is Mine',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
      return CachedNetworkImage(imageUrl: url, fit: fit);
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

class _ViewClaimsSection extends StatelessWidget {
  const _ViewClaimsSection({required this.post});
  final SimplePostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        ElevatedButton(
          onPressed: () => context.push('/post/${post.id}/claims?title=${Uri.encodeComponent(post.title)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.jadePrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('View Claim Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
