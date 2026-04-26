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

    final result = await api.toggleLike(_post!.id, currentUid);
    setState(() {
      _hasLiked = result['liked'];
      _post = _post!.copyWith(
        likesCount: result['likeCount'] ?? (_post!.likesCount + (result['liked'] ? 1 : -1)),
      );
    });
    AppHaptics.light();
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
  });
  final SimplePostModel post;
  final bool hasLiked;
  final VoidCallback onResolved;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    final isOwner = currentUid == post.userId;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: CustomScrollView(
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
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
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
                          child: _PostImage(
                            url: post.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradient overlay
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
                  
                  // ─── Social Actions Row ──────────────────────────────────
                  Row(
                    children: [
                      // Likes
                      _SocialAction(
                        icon: hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: '${post.likesCount}',
                        color: hasLiked ? Colors.redAccent : AppColors.textSecondary(context),
                        onTap: onToggleLike,
                      ),
                      const SizedBox(width: 20),
                      // Views
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
                      // Share
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
                  const SizedBox(height: 28),
                  if (!isOwner && post.isOpen)
                    _ClaimSection(post: post, currentUid: currentUid ?? ''),
                  const SizedBox(height: 32),
                  CommentsSection(postId: post.id),
                  const SizedBox(height: 100),
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

class _ClaimSection extends ConsumerWidget {
  const _ClaimSection({required this.post, required this.currentUid});
  final SimplePostModel post;
  final String currentUid;

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
              post.isLost
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
        GestureDetector(
          onTap: () async {
            AppHaptics.medium();
            final api = ref.read(apiServiceProvider);
            final chatId = await api.createChat({
              'postId': post.id,
              'buyerId': currentUid, // Using buyerId as currentUserId field
              'sellerId': post.userId, // Using sellerId as otherUserId field
              'postTitle': post.title,
              'otherUserName': post.posterName,
            });
            if (context.mounted) {
              context.push('/chat/${chatId['id']}');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  HSLColor.fromColor(color)
                      .withHue((HSLColor.fromColor(color).hue + 20) % 360)
                      .toColor(),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                post.isLost ? '💬 I Found This' : '💬 This Is Mine',
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
