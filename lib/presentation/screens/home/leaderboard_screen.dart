// lib/presentation/screens/home/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/simple_user_model.dart';
import '../../widgets/common/user_avatar.dart';

final leaderboardProvider = FutureProvider<List<SimpleUserModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getLeaderboard();
  return data.map((u) => SimpleUserModel.fromMap(u as Map<String, dynamic>)).toList();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final pageBg = AppColors.pageBg(context);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final cardBg = AppColors.card(context);
    final borderCol = AppColors.border(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Campus Champions',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: leaderboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jadePrimary)),
          error: (err, _) => Center(child: Text('Failed to load champions: $err', style: GoogleFonts.inter(color: textColor))),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Text('No campus champions yet!', style: GoogleFonts.inter(color: subColor)),
              );
            }

            // Extract top 3 and others
            final topThree = users.take(3).toList();
            final others = users.skip(3).toList();

            return Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'LEADERBOARD',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.jadePrimary,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Most Helpful Students This Semester',
                  style: GoogleFonts.inter(fontSize: 13, color: subColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Podium Display
                if (topThree.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Rank 2 Pedestal
                        if (topThree.length > 1)
                          _buildPodiumColumn(context, topThree[1], 2, Colors.grey[400]!, 110.0),
                        // Rank 1 Pedestal (Tallest, center)
                        _buildPodiumColumn(context, topThree[0], 1, Colors.amber, 150.0),
                        // Rank 3 Pedestal
                        if (topThree.length > 2)
                          _buildPodiumColumn(context, topThree[2], 3, Colors.orangeAccent, 90.0),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Scrollable Ranked Feed
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border.all(color: borderCol, width: 0.5),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      itemCount: others.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final SimpleUserModel u = others[index];
                        final int rank = index + 4;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderCol, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                alignment: Alignment.center,
                                child: Text(
                                  '#$rank',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: subColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildUserAvatar(u, size: 36),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cleanCMSUsername(u.name),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${u.itemsReturned} items returned',
                                      style: GoogleFonts.inter(fontSize: 11, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${u.karmaPoints} pts',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.jadePrimary),
                                  ),
                                  Text(
                                    'LEVEL ${(u.karmaPoints / 100).toInt() + 1}',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: subColor.withOpacity(0.6), letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1, end: 0);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar(SimpleUserModel user, {double size = 44}) {
    return UserAvatar(photoURL: user.photoURL, radius: size / 2);
  }

  Widget _buildPodiumColumn(BuildContext context, SimpleUserModel user, int rank, Color medalColor, double colHeight) {
    final isRankOne = rank == 1;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar with halo
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: isRankOne ? 3.0 : 2.0),
                boxShadow: [
                  BoxShadow(color: medalColor.withOpacity(0.2), blurRadius: 12, spreadRadius: 2),
                ],
              ),
              child: _buildUserAvatar(user, size: isRankOne ? 60 : 48),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pageBg(context), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 11,
                  color: isRankOne ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ).animate().scale(delay: 150.ms, duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 12),
        
        // Name
        SizedBox(
          width: 80,
          child: Text(
            cleanCMSUsername(user.name),
            style: GoogleFonts.plusJakartaSans(fontSize: isRankOne ? 13 : 11, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),

        // Pedestal Column
        Container(
          width: isRankOne ? 90 : 80,
          height: colHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.01)]
                  : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.01)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${user.karmaPoints} pts',
                style: GoogleFonts.plusJakartaSans(fontSize: isRankOne ? 13 : 11, fontWeight: FontWeight.w800, color: AppColors.jadePrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'RANK $rank',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: subColor.withOpacity(0.4), letterSpacing: 0.5),
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, end: 0, duration: 500.ms, curve: Curves.easeOutQuart),
      ],
    );
  }
}
