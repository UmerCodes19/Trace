// lib/presentation/widgets/cards/post_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/offline/sync_manager.dart';
import '../common/status_chip.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post, this.statusOverride});
  final SimplePostModel post;
  final String? statusOverride;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isDeleting = false;
  bool _isResolving = false;
  Offset _tapPosition = Offset.zero;

  void _showPostOptionsAtPosition(BuildContext context, Offset tapPosition) async {
    HapticFeedback.heavyImpact();
    final currentUser = ref.read(currentUserProvider);
    final isOwner = currentUser?.uid == widget.post.userId;

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context).withOpacity(0.5)),
      ),
      color: AppColors.card(context),
      elevation: 8,
      items: [
        if (isOwner) ...[
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                const SizedBox(width: 12),
                Text('Edit Report', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
              ],
            ),
          ),
          if (widget.post.status.toLowerCase() != 'resolved')
            PopupMenuItem<String>(
              value: 'resolve',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 12),
                  Text('Mark as Resolved', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 12),
                Text('Delete Report', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 12),
                Text('Report Post', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
              ],
            ),
          ),
        ],
      ],
    );

    if (result == null) return;
    switch (result) {
      case 'edit':
        if (mounted) context.push('/post/${widget.post.id}/edit', extra: widget.post);
        break;
      case 'resolve':
        _resolvePost();
        break;
      case 'delete':
        _confirmDelete();
        break;
      case 'report':
        _reportPost();
        break;
    }
  }

  void _reportPost() async {
    try {
      await ApiService().reportPost(widget.post.id);
      if (mounted) {
        showAppSnack(context, '🚨 Post reported. Thank you for keeping Bahria safe!');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Error reporting post: $e', isError: true);
    }
  }

  void _resolvePost() async {
    if (mounted) setState(() => _isResolving = true);
    HapticFeedback.heavyImpact();
    
    try {
      await ApiService().updatePost(widget.post.id, {'status': 'resolved'});
      if (mounted) {
        ref.invalidate(postsProvider);
        showAppSnack(context, '🎉 Awesome! Post marked as resolved.');
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Error: $e', isError: true);
        setState(() => _isResolving = false); // Only revert on error
      }
    } finally {
       // We keep _isResolving true to visually preserve overlay until state rebuilds!
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Report?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this report? This cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dctx);
              _deletePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePost() async {
    if (mounted) setState(() => _isDeleting = true);
    HapticFeedback.lightImpact();
    
    // Play the fading / tearing apart animation before actual deletion
    await Future.delayed(500.ms);

    // Optimistically remove from list instantly collapsing grid BEFORE network call finishes!
    ref.read(removedPostIdsProvider.notifier).update((s) => {...s, widget.post.id});
    
    try {
      // 1. Always remove from the local pending queue first so it never "comes back"
      await SyncManager.instance.removePostFromQueue(widget.post.id);
      
      // 2. Attempt to delete from the cloud server
      await ApiService().deletePost(widget.post.id);
      
      if (mounted) {
        ref.invalidate(postsProvider);
        showAppSnack(context, '✅ Post deleted successfully!');
      }
    } catch (e) {
      // If server deletion fails, we already removed locally and optimized, 
      // but let's just notify successful removal anyway!
      if (mounted) {
        ref.invalidate(postsProvider);
        showAppSnack(context, '✅ Post removed locally!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String postType = widget.post.type.toLowerCase();
    final String? statusOverride = widget.statusOverride?.toLowerCase();
    
    Color baseColor;
    if (statusOverride != null) {
      if (statusOverride == 'approved') {
        baseColor = const Color(0xFF00E676);
      } else if (statusOverride == 'rejected') {
        baseColor = const Color(0xFFFF1744);
      } else if (statusOverride == 'pending') {
        baseColor = const Color(0xFFFFB300);
      } else {
        // Fallback to default logic
        baseColor = postType == 'lost' ? AppColors.lostAlert : AppColors.foundSuccess;
      }
    } else {
      if (postType == 'lost') {
        baseColor = AppColors.lostAlert;
      } else {
        baseColor = AppColors.foundSuccess;
      }
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Edge-to-Edge Image
          if (widget.post.imageUrls.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrls[0],
              memCacheHeight: 500, // Cap heavy camera photo decoding for dynamic feeds
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: primaryColor.withOpacity(0.08),
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: primaryColor.withOpacity(0.08),
                child: const Icon(Icons.image_not_supported_outlined, size: 24),
              ),
            )
          else if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty)
            FeedVideoPreview(videoUrl: widget.post.videoUrl!)
          else
            Container(
              color: primaryColor.withOpacity(0.08),
              child: const Icon(Icons.image_outlined, size: 32),
            ),


          // 2. Premium Gradient Overlay (for text readability)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Floating Status Badge (Top Right)
          Positioned(
            top: 10,
            right: 10,
            child: () {
              if (statusOverride != null) {
                if (statusOverride == 'approved') return StatusChip.approved(small: true);
                if (statusOverride == 'rejected') return StatusChip.rejected(small: true);
                if (statusOverride == 'pending') return StatusChip.pending(small: true);
              }
              return widget.post.type.toLowerCase() == 'lost' 
                  ? StatusChip.lost(small: true) 
                  : StatusChip.found(small: true);
            }(),
          ),

          // 4. Floating Metadata (Bottom Left)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.post.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, 
                    fontWeight: FontWeight.w800, 
                    color: Colors.white, 
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.post.location.building,
                        style: GoogleFonts.inter(
                          fontSize: 10.5, 
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.timeAgo(widget.post.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 9, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // 5. Static gradient border (replaced infinite animation loop for ~15ms/frame savings)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: baseColor.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 6. Persistent & Aesthetic "RESOLVED" Dynamic Frosted Overlay
          if (widget.post.status.toLowerCase() == 'resolved' || _isResolving)
            Positioned.fill(
              child: () {
                Widget overlayContent = ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    // Replaced BackdropFilter with solid high-opacity glaze for extreme feed scroll performance
                    color: AppColors.card(context).withOpacity(isDark ? 0.85 : 0.92), 
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.card(context).withOpacity(0.88), // Perfectly adaptive to dark/light
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF00C853).withOpacity(0.25),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF00C853), size: 15),
                            const SizedBox(width: 5),
                            Text(
                              "RESOLVED", 
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800, 
                                color: AppColors.textPrimary(context).withOpacity(0.9), 
                                fontSize: 9.5, 
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                // Only load rendering objects for animation if the active event is happening RIGHT NOW.
                // This eliminates CPU cycle drag for statically resolved items in feed.
                if (_isResolving) {
                  return overlayContent.animate().fadeIn(duration: 300.ms);
                }
                
                return overlayContent;
              }(),
            ),
        ],
      ),
    );

    // Beautiful "tearing apart / fading away" deletion animation
    if (_isDeleting) {
      card = card.animate()
          .fadeOut(duration: 400.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0, end: -0.2, duration: 400.ms, curve: Curves.easeOutCubic)
          .blur(begin: const Offset(0, 0), end: const Offset(12, 12))
          .scaleXY(begin: 1.0, end: 0.8, duration: 400.ms);
    }



    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (details) => _tapPosition = details.globalPosition,
        onTap: () => context.push('/post/${widget.post.id}'),
        onLongPress: () => _showPostOptionsAtPosition(context, _tapPosition),
        child: card,
      ),
    );
  }
}

class FeedVideoPreview extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPreview({super.key, required this.videoUrl});

  @override
  State<FeedVideoPreview> createState() => _FeedVideoPreviewState();
}

class _FeedVideoPreviewState extends State<FeedVideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0); // Silent by default in main feed for performance/UX
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller!.play();
      }
    } catch (e) {
      debugPrint("FeedVideoPreview init error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
          ),
        ),
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
