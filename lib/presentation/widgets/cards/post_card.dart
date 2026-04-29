// lib/presentation/widgets/cards/post_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../common/status_chip.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final SimplePostModel post;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push('/post/${post.id}'),
        child: Container(
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
                    if (post.imageUrls.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: post.imageUrls[0],
                        fit: BoxFit.cover,
                        memCacheWidth: 400, // Performance: Lower res for memory efficiency
                        placeholder: (context, url) => Container(
                          color: AppColors.jadePrimary.withOpacity(0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
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
                      child: post.type == 'lost' 
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
                            post.title,
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
                                  post.location.building,
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
                        AppDateUtils.timeAgo(post.timestamp),
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
        ),
      ),
    );
  }
}
