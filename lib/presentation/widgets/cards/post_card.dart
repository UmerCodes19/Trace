// lib/presentation/widgets/cards/post_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../common/status_chip.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});
  final SimplePostModel post;

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
                Icon(Icons.edit_rounded, color: AppColors.jadePrimary, size: 18),
                const SizedBox(width: 12),
                Text('Edit Report', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
              ],
            ),
          ),
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
    setState(() => _isResolving = true);
    try {
      await ApiService().updatePost(widget.post.id, {'status': 'resolved'});
      if (mounted) {
        ref.invalidate(postsProvider);
      }
      if (mounted) {
        showAppSnack(context, '🎉 Awesome! Post marked as resolved.');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isResolving = false);
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
    
    try {
      await ApiService().deletePost(widget.post.id);
      if (mounted) {
        ref.invalidate(postsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        showAppSnack(context, 'Failed to delete post: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.post.imageUrls.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: widget.post.imageUrls[0],
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (context, url) => Container(
                      color: AppColors.jadePrimary.withOpacity(0.1),
                      child: const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.jadePrimary.withOpacity(0.1),
                      child: const Icon(Icons.image_not_supported_outlined, size: 20),
                    ),
                  )
                else
                  Container(
                    color: AppColors.jadePrimary.withOpacity(0.1),
                    child: const Icon(Icons.image_outlined, size: 30),
                  ),
                
                // Tag Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: widget.post.type == 'lost' 
                      ? StatusChip.lost(small: true) 
                      : StatusChip.found(small: true),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5, 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.textPrimary(context), 
                          height: 1.1
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 10, color: AppColors.textSecondary(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.post.location.building,
                              style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    AppDateUtils.timeAgo(widget.post.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 9, 
                      fontWeight: FontWeight.w500, 
                      color: AppColors.textSecondary(context).withOpacity(0.7)
                    ),
                  ),
                ],
              ),
            ),
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
