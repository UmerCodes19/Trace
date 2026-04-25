import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/cards/post_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/lottie_empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _userName = 'there';
  int _unreadChats = 0;
  bool _searchFocused = false;
  Timer? _debounce;

  static const _tabs = [
    _FeedTab(label: 'For You', type: null),
    _FeedTab(label: 'Lost', type: 'lost'),
    _FeedTab(label: 'Found', type: 'found'),
    _FeedTab(label: 'Resolved', type: 'returned'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _loadHeaderData();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state =
            _searchCtrl.text.toLowerCase();
        setState(() {});
      }
    });
  }

  Future<void> _loadHeaderData() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (!mounted || user == null) return;

    final unread = await ref
        .read(apiServiceProvider)
        .getUnreadCountForUser(user.uid);
    if (!mounted) return;

    setState(() {
      _userName = user.name.isEmpty ? 'there' : user.name.split(' ').first;
      _unreadChats = unread;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${timeGreeting()}, $_userName',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Lost & Found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GlassCard(
                          borderRadius: 40,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.settings_outlined,
                              color: AppColors.textPrimary(context),
                              size: 22,
                            ),
                          ),
                        ),
                        if (_unreadChats > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lostAlert,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.lostAlert.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                _unreadChats > 99 ? '99+' : '$_unreadChats',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Search bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _searchFocused
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: GlassCard(
                  borderRadius: 24,
                  borderGlow: _searchFocused
                      ? accent.withOpacity(0.3)
                      : null,
                  child: SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: _searchFocused
                                ? accent
                                : AppColors.textSecondary(context),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              focusNode: _searchFocus,
                              decoration: InputDecoration(
                                hintText: 'Search lost items...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textHint(context),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                filled: false,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary(context),
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // ── Tab bar ───────────────────────────────────────────────
            _CustomTabBar(
              controller: _tabCtrl,
              tabs: _tabs,
            ),

            const SizedBox(height: 4),

            // ── Feed ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: _tabs
                    .map(
                      (tab) => _FeedList(
                        type: tab.type,
                        searchQuery: _searchCtrl.text.toLowerCase(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTabBar extends StatelessWidget {
  const _CustomTabBar({
    required this.controller,
    required this.tabs,
  });
  final TabController controller;
  final List<_FeedTab> tabs;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final isActive = controller.index == i;
          return GestureDetector(
            onTap: () {
              AppHaptics.light();
              controller.animateTo(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? accent
                    : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : AppColors.border(context),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                tabs[i].label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedList extends ConsumerStatefulWidget {
  const _FeedList({this.type, required this.searchQuery});
  final String? type;
  final String searchQuery;

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList>
    with AutomaticKeepAliveClientMixin {
  List<SimplePostModel> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      List<dynamic> postsList;

      if (widget.type == 'returned') {
        final claimedPosts = await api.getPosts(status: 'claimed');
        final resolvedPosts = await api.getPosts(status: 'resolved');
        postsList = [...claimedPosts, ...resolvedPosts];
        postsList.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );
      } else if (widget.type != null) {
        postsList = await api.getPosts(type: widget.type, status: 'open');
      } else {
        postsList = await api.getPosts(status: 'open');
      }

      if (!mounted) return;
      setState(() {
        _posts = postsList.map((p) => SimplePostModel.fromMap(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SimplePostModel> get _filteredPosts {
    if (widget.searchQuery.isEmpty) return _posts;
    final query = widget.searchQuery;
    return _posts
        .where(
          (post) =>
              post.title.toLowerCase().contains(query) ||
              post.description.toLowerCase().contains(query) ||
              post.location.building.toLowerCase().contains(query) ||
              post.aiTags.any((tag) => tag.toLowerCase().contains(query)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) return const _LoadingList();
    if (_error != null) return _ErrorState(error: _error!);
    if (_filteredPosts.isEmpty) {
      return LottieEmptyStateWidget(
        lottieAsset: 'assets/lottie/empty_search.json',
        fallbackIcon: Icons.search_off_rounded,
        title: 'Nothing here yet',
        subtitle: 'Be the first to report a lost or found item on campus.',
        actionLabel: 'Create Post',
        onAction: () => context.go('/create'),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _loadPosts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: _filteredPosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          // Only animate first 6 items to reduce animation overhead
          final child = PostCard(post: _filteredPosts[i]);
          if (i < 6) {
            return child
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 50))
                .slideY(begin: 0.15, delay: Duration(milliseconds: i * 50));
          }
          return child;
        },
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonPostCard(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Failed to load posts',
      subtitle: error,
      iconColor: AppColors.lostAlert,
    );
  }
}

class _FeedTab {
  const _FeedTab({required this.label, this.type});
  final String label;
  final String? type;
}
