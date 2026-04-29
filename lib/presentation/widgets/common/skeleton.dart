import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';

/// ─── Base Skeleton Box ───────────────────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBaseColor(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// ─── Rich Post Card Skeleton ─────────────────────────────────────────────────
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.shimmerBaseColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBaseColor(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge + timestamp row
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBaseColor(context),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 50,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBaseColor(context),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBaseColor(context),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description line 1
                    Container(
                      width: double.infinity,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBaseColor(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description line 2
                    Container(
                      width: 180,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBaseColor(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Location chip
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBaseColor(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Divider
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.shimmerBaseColor(context),
                    ),
                    const SizedBox(height: 12),
                    // Footer
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBaseColor(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.shimmerBaseColor(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 50,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBaseColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
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

/// ─── Profile Header Skeleton ─────────────────────────────────────────────────
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A3448) : const Color(0xFF2D5A78),
      highlightColor: isDark ? const Color(0xFF254060) : const Color(0xFF3D7090),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 24,
          24,
          32,
        ),
        child: Column(
          children: [
            // Settings icon
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Avatar
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Container(
              width: 160,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            // Email
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 6),
            // Department
            Container(
              width: 140,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Chat Tile Skeleton ──────────────────────────────────────────────────────
class SkeletonChatTile extends StatelessWidget {
  const SkeletonChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.shimmerBaseColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseColor(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBaseColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBaseColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBaseColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBaseColor(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Detail Screen Skeleton ──────────────────────────────────────────────────
class SkeletonDetailScreen extends StatelessWidget {
  const SkeletonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // Badges
            Row(
              children: [
                Container(
                  width: 80,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBaseColor(context),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBaseColor(context),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Container(
              width: 250,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseColor(context),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            // Description lines
            for (int i = 0; i < 3; i++) ...[
              Container(
                width: i == 2 ? 180 : double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBaseColor(context),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 16),
            // Info cards
            for (int i = 0; i < 2; i++) ...[
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBaseColor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// ─── Settings Section Skeleton ───────────────────────────────────────────────
class SkeletonSettingsSection extends StatelessWidget {
  const SkeletonSettingsSection({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Container(
            width: 120,
            height: 12,
            margin: const EdgeInsets.only(left: 4, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.shimmerBaseColor(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.shimmerBaseColor(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: List.generate(
                itemCount,
                (i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBaseColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.shimmerBaseColor(context),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 160,
                              height: 11,
                              decoration: BoxDecoration(
                                color: AppColors.shimmerBaseColor(context),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── QR Code Skeleton ────────────────────────────────────────────────────────
class SkeletonQrCode extends StatelessWidget {
  const SkeletonQrCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseColor(context),
      highlightColor: AppColors.shimmerHighColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Warning banner
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseColor(context),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 28),
            // QR card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseColor(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBaseColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 140,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBaseColor(context),
                      borderRadius: BorderRadius.circular(10),
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
