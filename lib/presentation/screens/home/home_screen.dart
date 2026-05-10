// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../notifications/notification_list_screen.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/cards/post_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/lottie_empty_state.dart';
import '../../widgets/common/trace_logo.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/search/visual_search_sheet.dart';

// Trace Guide Imports
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/utils/tutorial_keys.dart';
import '../../../core/utils/app_guide_orchestrator.dart';
import '../../../core/services/tutorial_service.dart';
import '../../widgets/common/welcome_cinematic.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedBuilding;
  String? _selectedCategory;
  String? _selectedRecency;

  String _cleanCMSUsername(String name) {
    if (name.toUpperCase().contains('CMS USER') || name.contains('(') || name.contains(')')) {
      final regExp = RegExp(r'\d{2}-\d{5,6}-\d{3}');
      final match = regExp.firstMatch(name);
      if (match != null) return match.group(0)!;
    }
    return name;
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Trigger check after frame mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowIntroTour();
    });
  }

  Future<void> _checkAndShowIntroTour() async {
    final service = ref.read(tutorialServiceProvider);
    final completed = await service.isFeatureTourCompleted('intro_tour');
    if (completed || !mounted) return;

    // Trigger Cinematic Welcome
    if (mounted) {
      WelcomeCinematic.show(
        context,
        onStartTour: () {
          ref.read(activeTourStateProvider.notifier).state = ActiveTourState.home;
          _launchGrandTour();
        },
        onDismiss: () {
          service.markFeatureTourCompleted('intro_tour');
          ref.read(activeTourStateProvider.notifier).state = ActiveTourState.none;
        },
      );
    }
  }

  void _launchGrandTour() {
    final service = ref.read(tutorialServiceProvider);

    final targets = <TargetFocus>[
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.navHomeKey,
        title: 'Home',
        description: 'Your feed showing all latest lost and found items.',
        stepLabel: 'Feed',
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.feedSearchKey,
        title: 'Search',
        description: 'Type what you are looking for here.',
        stepLabel: 'Find',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
      ),
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.feedFilterKey,
        title: 'Filter',
        description: 'Filter items by building or date.',
        stepLabel: 'Sort',
        align: ContentAlign.bottom,
      ),
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.navMapKey,
        title: 'Map',
        description: 'View item locations across the campus.',
        stepLabel: 'Map',
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),
    ];

    final notifier = ref.read(activeTourStateProvider.notifier);
    final router = GoRouter.of(context);

    AppGuideOrchestrator.showTutorial(
      context: context,
      featureKey: 'intro_tour',
      targets: targets,
      tutorialService: service,
      onFinish: () {
        // Bypass spatial engine and vector directly into creation studio
        notifier.state = ActiveTourState.create;
        router.go('/create');
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showBuildingFilterSheet() {
    final buildings = ['Library', 'Science Block', 'Hostel', 'Main Café', 'Admin Office', 'Engineering Dept'];
    final categories = ['Electronics', 'Keys & Cards', 'Bags & Wallets', 'Documents', 'Books & Stationery', 'Others'];
    final recencyOptions = ['Today', 'Last 3 Days', 'This Week', 'This Month'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                Widget _buildFilterChip({
                  required String label,
                  required bool isSelected,
                  required VoidCallback onTap,
                }) {
                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.015)),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.transparent 
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      child: Text(
                        label, 
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Refine Search Filters',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppColors.textPrimary(context),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  _selectedBuilding = null;
                                  _selectedCategory = null;
                                  _selectedRecency = null;
                                });
                                setState(() {}); // trigger home refresh
                              },
                              child: Text(
                                'Reset All',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.jadePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Campus Building
                        Text(
                          'CAMPUS BUILDING',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              label: 'All Buildings',
                              isSelected: _selectedBuilding == null,
                              onTap: () {
                                setSheetState(() => _selectedBuilding = null);
                                setState(() {});
                              },
                            ),
                            ...buildings.map((b) => _buildFilterChip(
                              label: b,
                              isSelected: _selectedBuilding == b,
                              onTap: () {
                                setSheetState(() => _selectedBuilding = b);
                                setState(() {});
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Item Category
                        Text(
                          'ITEM CATEGORY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              label: 'All Categories',
                              isSelected: _selectedCategory == null,
                              onTap: () {
                                setSheetState(() => _selectedCategory = null);
                                setState(() {});
                              },
                            ),
                            ...categories.map((c) => _buildFilterChip(
                              label: c,
                              isSelected: _selectedCategory == c,
                              onTap: () {
                                setSheetState(() => _selectedCategory = c);
                                setState(() {});
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Date Posted
                        Text(
                          'DATE POSTED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              label: 'All Time',
                              isSelected: _selectedRecency == null,
                              onTap: () {
                                setSheetState(() => _selectedRecency = null);
                                setState(() {});
                              },
                            ),
                            ...recencyOptions.map((r) => _buildFilterChip(
                              label: r,
                              isSelected: _selectedRecency == r,
                              onTap: () {
                                setSheetState(() => _selectedRecency = r);
                                setState(() {});
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Apply Button
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      endDrawer: const NotificationDrawer(),
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Greeting
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeGreeting(), 
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _cleanCMSUsername(user?.name ?? 'Guest'), 
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.w800, 
                                  color: AppColors.textPrimary(context), 
                                  letterSpacing: -0.5
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Right: Actions (Leaderboard & Notifications)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/leaderboard'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.card(context),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border(context), width: 1),
                                ),
                                child: Icon(
                                  Icons.workspace_premium_rounded, 
                                  color: Colors.amber.shade600, 
                                  size: 23
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Builder(
                              builder: (ctx) => GestureDetector(
                                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.card(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border(context), width: 1),
                                  ),
                                  child: Stack(
                                    children: [
                                      Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary(context), size: 22),
                                      // We can add a red dot if unread here, for now it's static
                                      Positioned(
                                        right: 0,
                                        top: 2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.lostAlert,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.card(context), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Search Bar & Filters
                    _buildPremiumSearchBar(context),
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
              _PostFeed(query: _searchQuery, filter: 'all', building: _selectedBuilding, category: _selectedCategory, recency: _selectedRecency),
              _PostFeed(query: _searchQuery, filter: 'lost', building: _selectedBuilding, category: _selectedCategory, recency: _selectedRecency),
              _PostFeed(query: _searchQuery, filter: 'found', building: _selectedBuilding, category: _selectedCategory, recency: _selectedRecency),
              _PostFeed(query: _searchQuery, filter: 'resolved', building: _selectedBuilding, category: _selectedCategory, recency: _selectedRecency),
              _MyClaimsFeed(query: _searchQuery, building: _selectedBuilding, category: _selectedCategory, recency: _selectedRecency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSearchBar(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilter = _selectedBuilding != null || _selectedCategory != null || _selectedRecency != null;

    return Row(
      children: [
        // 1. Unified Search Pill
        Expanded(
          child: Container(
            key: TutorialKeys.feedSearchKey,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(26), // perfectly pill-shaped
              border: Border.all(color: AppColors.border(context), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.textPrimary(context), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Search lost items...',
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary(context)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // AI Scanner Icon inside the pill
                Container(
                  height: 32,
                  width: 32,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: AppColors.jadePrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.center_focus_weak_rounded, color: AppColors.jadePrimary, size: 18),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const VisualSearchSheet(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 2. Advanced Filter Hub Toggle
        GestureDetector(
          onTap: _showBuildingFilterSheet,
          child: Container(
            key: TutorialKeys.feedFilterKey,
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: hasActiveFilter ? accent : AppColors.card(context),
              shape: BoxShape.circle,
              border: Border.all(color: hasActiveFilter ? accent : AppColors.border(context), width: 1),
              boxShadow: [
                BoxShadow(
                  color: hasActiveFilter ? accent.withOpacity(0.3) : Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded, // Premium filter icon
              color: hasActiveFilter ? Colors.white : AppColors.textPrimary(context),
              size: 24,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildNotificationsRightDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? AppColors.navyDarkest : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final notificationsAsync = ref.watch(notificationsProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final user = ref.read(authServiceProvider).currentUser;
                          if (user != null) {
                            await ref.read(apiServiceProvider).markAllNotificationsRead(user.uid);
                            ref.invalidate(notificationsProvider);
                          }
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.jadePrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Expanded(
                    child: notificationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jadePrimary)),
                      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textColor))),
                      data: (list) {
                        if (list.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 48, color: subColor.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  'All caught up!',
                                  style: GoogleFonts.plusJakartaSans(color: subColor, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final n = list[index] as Map<String, dynamic>;
                            final isRead = (n['is_read'] ?? n['isRead'] ?? true) as bool;
                            return Dismissible(
                              key: Key(n['id']?.toString() ?? index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                padding: const EdgeInsets.only(right: 20),
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                              ),
                              onDismissed: (direction) async {
                                final api = ref.read(apiServiceProvider);
                                try {
                                  await api.markNotificationRead(n['id']);
                                  ref.invalidate(notificationsProvider);
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead 
                                      ? (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02))
                                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isRead 
                                        ? Colors.transparent
                                        : AppColors.jadePrimary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.jadePrimary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.jadePrimary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['title'] ?? 'Notification',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n['body'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: subColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
  final String? building;
  final String? category;
  final String? recency;

  const _PostFeed({
    required this.query,
    required this.filter,
    this.building,
    this.category,
    this.recency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final posts = postsAsync.value;

    if (posts == null && postsAsync.isLoading) {
      return const _LoadingFeed();
    }
    if (postsAsync.hasError && posts == null) {
      return Center(child: Text('Error: ${postsAsync.error}'));
    }

    final activePosts = posts ?? [];
    final filtered = activePosts.where((p) {
      // 1. Tab Type & Status Pre-Filtering
      if (filter == 'lost') {
        if (p.type != 'lost' || p.status == 'resolved') return false;
      } else if (filter == 'found') {
        if (p.type != 'found' || p.status == 'resolved') return false;
      } else if (filter == 'resolved') {
        if (p.status != 'resolved') return false;
      }

      // 2. Campus Building Filtering
      if (building != null && p.location.building.toLowerCase() != building!.toLowerCase()) {
        return false;
      }

      // 3. Category Semantic Keyword Filtering
      if (category != null) {
        final categoryLower = category!.toLowerCase();
        final title = p.title.toLowerCase();
        final desc = p.description.toLowerCase();
        final tags = p.aiTags.map((t) => t.toLowerCase()).toList();

        bool hasMatch = false;
        if (categoryLower == 'electronics') {
          final keywords = ['electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch', 'camera'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'keys & cards') {
          final keywords = ['key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge', 'cnic'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'bags & wallets') {
          final keywords = ['bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede', 'pocketbook'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'documents') {
          final keywords = ['document', 'paper', 'file', 'cnic', 'passport', 'booklet', 'degree', 'certificate'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'books & stationery') {
          final keywords = ['book', 'stationery', 'pen', 'pencil', 'notebook', 'register', 'binder', 'calculator'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'others') {
          final keywords = [
            'electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch',
            'key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge',
            'bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede',
            'document', 'paper', 'file', 'cnic', 'passport', 'booklet',
            'book', 'stationery', 'pen', 'pencil', 'notebook', 'register'
          ];
          hasMatch = !keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        }
        if (!hasMatch) return false;
      }

      // 4. Date Recency Filtering
      if (recency != null) {
        final now = DateTime.now();
        final diff = now.difference(p.timestamp);
        if (recency == 'Today') {
          if (diff.inDays >= 1) return false;
        } else if (recency == 'Last 3 Days') {
          if (diff.inDays >= 3) return false;
        } else if (recency == 'This Week') {
          if (diff.inDays >= 7) return false;
        } else if (recency == 'This Month') {
          if (diff.inDays >= 30) return false;
        }
      }

      // 5. Tokenized Search Query Filtering
      if (query.trim().isNotEmpty) {
        final cleanQuery = query.toLowerCase().trim();
        final title = p.title.toLowerCase();
        final desc = p.description.toLowerCase();
        final bName = p.location.building.toLowerCase();

        if (title.contains(cleanQuery) || desc.contains(cleanQuery) || bName.contains(cleanQuery)) {
          return true;
        }

        final words = cleanQuery.split(' ').where((w) => w.length > 1).toList();
        if (words.isEmpty) return false;

        int matchScore = 0;
        for (var word in words) {
          if (title.contains(word)) matchScore += 2;
          if (desc.contains(word)) matchScore += 1;
          if (bName.contains(word)) matchScore += 1;
          if (p.aiTags.any((tag) => tag.toLowerCase().contains(word) || word.contains(tag.toLowerCase()))) {
            matchScore += 2;
          }
        }

        if (matchScore < 2) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const LottieEmptyStateWidget(
        lottieAsset: 'assets/animations/empty_feed.json',
        fallbackIcon: Icons.travel_explore_rounded,
        title: 'No Items Discovered',
        subtitle: 'Try adjusting your filters, or check the Map to see items around campus.',
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
  final String? building;
  final String? category;
  final String? recency;
  const _MyClaimsFeed({
    required this.query,
    this.building,
    this.category,
    this.recency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(myClaimsProvider);
    final claims = claimsAsync.value;

    if (claims == null && claimsAsync.isLoading) {
      return const _LoadingFeed();
    }
    if (claimsAsync.hasError && claims == null) {
      return Center(child: Text('Error: ${claimsAsync.error}'));
    }

    final activeClaims = claims ?? [];
    final filtered = activeClaims.where((c) {
      final post = c['posts'];
      if (post == null) return false;
      
      final postBuilding = post['location']?['building']?.toString() ?? '';
      
      // 1. Campus Building Filtering
      if (building != null && postBuilding.toLowerCase() != building!.toLowerCase()) {
        return false;
      }

      // 2. Category Semantic Keyword Filtering
      if (category != null) {
        final categoryLower = category!.toLowerCase();
        final title = (post['title'] ?? '').toString().toLowerCase();
        final desc = (post['description'] ?? '').toString().toLowerCase();
        final tags = (post['aiTags'] != null) 
            ? (post['aiTags'] as List).map((t) => t.toString().toLowerCase()).toList() 
            : <String>[];

        bool hasMatch = false;
        if (categoryLower == 'electronics') {
          final keywords = ['electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch', 'camera'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'keys & cards') {
          final keywords = ['key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge', 'cnic'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'bags & wallets') {
          final keywords = ['bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede', 'pocketbook'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'documents') {
          final keywords = ['document', 'paper', 'file', 'cnic', 'passport', 'booklet', 'degree', 'certificate'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'books & stationery') {
          final keywords = ['book', 'stationery', 'pen', 'pencil', 'notebook', 'register', 'binder', 'calculator'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (categoryLower == 'others') {
          final keywords = [
            'electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch',
            'key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge',
            'bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede',
            'document', 'paper', 'file', 'cnic', 'passport', 'booklet',
            'book', 'stationery', 'pen', 'pencil', 'notebook', 'register'
          ];
          hasMatch = !keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        }
        if (!hasMatch) return false;
      }

      // 3. Date Recency Filtering
      if (recency != null && post['timestamp'] != null) {
        final pTime = DateTime.parse(post['timestamp'].toString());
        final now = DateTime.now();
        final diff = now.difference(pTime);
        if (recency == 'Today') {
          if (diff.inDays >= 1) return false;
        } else if (recency == 'Last 3 Days') {
          if (diff.inDays >= 3) return false;
        } else if (recency == 'This Week') {
          if (diff.inDays >= 7) return false;
        } else if (recency == 'This Month') {
          if (diff.inDays >= 30) return false;
        }
      }

      // 4. Tokenized Search Query Filtering
      if (query.trim().isNotEmpty) {
        final cleanQuery = query.toLowerCase().trim();
        final title = (post['title'] ?? '').toString().toLowerCase();
        final desc = (post['description'] ?? '').toString().toLowerCase();
        final bName = postBuilding.toLowerCase();

        if (title.contains(cleanQuery) || desc.contains(cleanQuery) || bName.contains(cleanQuery)) {
          return true;
        }

        final words = cleanQuery.split(' ').where((w) => w.length > 1).toList();
        if (words.isEmpty) return false;

        int matchScore = 0;
        for (var word in words) {
          if (title.contains(word)) matchScore += 2;
          if (desc.contains(word)) matchScore += 1;
          if (bName.contains(word)) matchScore += 1;
        }
        if (matchScore < 2) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const LottieEmptyStateWidget(
        lottieAsset: 'assets/animations/empty_feed.json',
        fallbackIcon: Icons.handshake_rounded,
        title: 'No Active Claims',
        subtitle: 'When you claim an item or someone claims yours, the handshake will appear here.',
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

            final status = claim['status']?.toString();
            return PostCard(
              post: postModel,
              statusOverride: status,
            )
                .animate()
                .fadeIn(delay: (index * 30).ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart);
          },
        ),
      ),
    );
  }
}
