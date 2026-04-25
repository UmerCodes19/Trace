import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../common/glass_card.dart';
import '../common/pressable_scale.dart';
import '../common/status_chip.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final SimplePostModel post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: PressableScale(
        onTap: () => context.push('/post/${widget.post.id}'),
        child: GlassCard(
          elevation: 2,
          borderRadius: 20,
          opacity: isDark ? 0.4 : 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image carousel ───────────────────────────────────────
              if (widget.post.imageUrls.isNotEmpty)
                _ImageCarousel(urls: widget.post.imageUrls),

              // ── Content ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + timestamp row
                    Row(
                      children: [
                        widget.post.isLost
                            ? StatusChip.lost(small: true)
                            : StatusChip.found(small: true),
                        const Spacer(),
                        Text(
                          AppDateUtils.timeAgo(widget.post.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      widget.post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      widget.post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Location chip
                    _LocationChip(location: widget.post.location.building),

                    const SizedBox(height: 12),

                    Divider(
                      height: 1,
                      color: AppColors.border(context),
                    ),

                    const SizedBox(height: 10),

                    // Footer: user + claim button
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkElevated
                                : AppColors.grey100,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.post.posterName.isEmpty
                                      ? 'Anonymous'
                                      : widget.post.posterName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                              if (widget.post.isCMSVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.foundSuccess,
                                  size: 13,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Social Stats
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded, size: 14, color: AppColors.textHint(context)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.post.viewCount}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite_rounded, size: 14, color: widget.post.likesCount > 0 ? Colors.redAccent : AppColors.textHint(context)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.post.likesCount}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        if (widget.post.isOpen)
                          _ClaimButton(
                            isLost: widget.post.isLost,
                            onTap: () =>
                                context.push('/post/${widget.post.id}'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image Carousel ───────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.urls});
  final List<String> urls;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final url = widget.urls[i];
                final isRemote =
                    url.startsWith('http://') || url.startsWith('https://');
                if (isRemote) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.shimmerBaseColor(context),
                      highlightColor: AppColors.shimmerHighColor(context),
                      child: Container(color: AppColors.shimmerBaseColor(context)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.cardBg(context),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textHint(context),
                        size: 40,
                      ),
                    ),
                  );
                }
                return Image.file(
                  File(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.cardBg(context),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textHint(context),
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            // Gradient overlay for readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black26],
                  ),
                ),
              ),
            ),

            // Dots
            if (widget.urls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.urls.length, (i) {
                    final accent = Theme.of(context).colorScheme.primary;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _current == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _current == i
                            ? accent
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: _current == i
                            ? [
                                BoxShadow(
                                  color: accent.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Location Chip ────────────────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 13,
          color: accent,
        ),
        const SizedBox(width: 4),
        Text(
          location,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Claim Button ─────────────────────────────────────────────────────────────
class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.isLost, required this.onTap});
  final bool isLost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isLost ? AppColors.lostAlert : AppColors.foundSuccess;

    return PressableScale(
      onTap: onTap,
      scaleFactor: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          isLost ? 'I Found It' : 'Claim',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
