// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/cards/post_card.dart';
import '../../widgets/common/lottie_empty_state.dart';
import '../../widgets/common/trace_logo.dart';
import '../../widgets/common/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeGreeting(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context))),
                              Text(
                                user?.name ?? 'Guest', 
                                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: -0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accent.withOpacity(0.2), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TraceLogo(color: accent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'TRACE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: _NotificationIcon(accent: accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(context),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, _) {
                        final posts = ref.watch(postsProvider).value ?? [];
                        final activeCount = posts.where((p) => p.status == 'open').length;
                        final recoveredCount = posts.where((p) => p.status == 'resolved').length;
                        final myReportsCount = posts.where((p) => p.userId == user?.uid).length;
                        
                        return _StatusSummary(
                          active: activeCount.toString().padLeft(2, '0'),
                          recovered: recoveredCount.toString().padLeft(2, '0'),
                          myReports: myReportsCount.toString().padLeft(2, '0'),
                          accent: accent,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                child: Container(
                  color: AppColors.pageBg(context),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: accent,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.textPrimary(context),
                    unselectedLabelColor: AppColors.textSecondary(context),
                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Lost'),
                      Tab(text: 'Found'),
                      Tab(text: 'Resolved'),
                      Tab(text: 'My Claims'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _PostFeed(query: _searchQuery, filter: 'all'),
              _PostFeed(query: _searchQuery, filter: 'lost'),
              _PostFeed(query: _searchQuery, filter: 'found'),
              _PostFeed(query: _searchQuery, filter: 'resolved'),
              _MyClaimsFeed(query: _searchQuery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textSecondary(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search for lost items...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0);
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.card(context), shape: BoxShape.circle, border: Border.all(color: AppColors.border(context), width: 0.5)),
          child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary(context), size: 22),
        ),
        Positioned(
          right: 2, top: 2,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1.seconds, curve: Curves.easeInOut).fadeOut(),
        ),
      ],
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({
    required this.accent,
    required this.active,
    required this.recovered,
    required this.myReports,
  });
  final Color accent;
  final String active;
  final String recovered;
  final String myReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryItem(label: 'Active Items', value: active, color: AppColors.lost)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryItem(label: 'Campus Recovered', value: recovered, color: AppColors.found)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryItem(label: 'My Reports', value: myReports, color: accent)),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  return local.year == now.year && local.month == now.month && local.day == now.day;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PostFeed extends ConsumerWidget {
  final String query;
  final String filter;

  const _PostFeed({required this.query, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      data: (posts) {
        var filtered = posts.where((p) {
          final matchesQuery = p.title.toLowerCase().contains(query.toLowerCase()) || 
                               p.description.toLowerCase().contains(query.toLowerCase());
          
          if (!matchesQuery) return false;

          if (filter == 'lost') return p.type == 'lost' && p.status != 'resolved';
          if (filter == 'found') return p.type == 'found' && p.status != 'resolved';
          if (filter == 'resolved') return p.status == 'resolved';
          
          return true; // 'all'
        }).toList();

        if (filtered.isEmpty) {
          return const LottieEmptyStateWidget(
            lottieAsset: 'assets/animations/empty_feed.json',
            fallbackIcon: Icons.inventory_2_outlined,
            title: 'Nothing here yet',
            subtitle: 'Try adjusting your search or filters.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(postsProvider),
          child: RepaintBoundary(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.64,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) => PostCard(post: filtered[index])
                  .animate()
                  .fadeIn(delay: (index * 30).ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart),
            ),
          ),
        );
      },
      loading: () => const _LoadingFeed(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.64,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonPostCard(),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});
  final Widget child;
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _MyClaimsFeed extends ConsumerWidget {
  final String query;
  const _MyClaimsFeed({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(myClaimsProvider);

    return claimsAsync.when(
      data: (claims) {
        var filtered = claims.where((c) {
          final post = c['posts'];
          if (post == null) return false;
          final matchesQuery = (post['title']?.toString().toLowerCase().contains(query.toLowerCase()) == true) || 
                               (post['description']?.toString().toLowerCase().contains(query.toLowerCase()) == true);
          return matchesQuery;
        }).toList();

        if (filtered.isEmpty) {
          return const LottieEmptyStateWidget(
            lottieAsset: 'assets/animations/empty_feed.json',
            fallbackIcon: Icons.inventory_2_outlined,
            title: 'No claims found',
            subtitle: 'You haven\'t submitted any claims yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myClaimsProvider),
          child: RepaintBoundary(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.64,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final claim = filtered[index];
                final postMap = claim['posts'];
                if (postMap == null) return const SizedBox.shrink();
                final postModel = SimplePostModel.fromMap(postMap);

                return Stack(
                  children: [
                    PostCard(post: postModel)
                        .animate()
                        .fadeIn(delay: (index * 30).ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: claim['status'] == 'approved' 
                              ? AppColors.foundSuccess
                              : (claim['status'] == 'rejected' ? Colors.redAccent : Colors.orangeAccent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          claim['status']?.toString().toUpperCase() ?? 'PENDING',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
      loading: () => const _LoadingFeed(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
