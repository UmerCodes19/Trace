// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../notifications/notification_list_screen.dart';
import '../../widgets/security/two_factor_setup_dialog.dart';
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

  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Trigger check after frame mounts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndShowIntroTour();
      await _checkAndPrompt2FA();
    });
  }

  Future<void> _checkAndPrompt2FA() async {
    // Give the cinematic tour a chance to clear if it fired
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // If enabled, don't bother.
    if (user.isTwoFactorEnabled) return;

    // Check local persistence so we don't spam.
    final prefs = await SharedPreferences.getInstance();
    final hasBeenPrompted = prefs.getBool('has_prompted_2fa_${user.uid}') ?? false;

    if (hasBeenPrompted) return;

    // Only prompt if not already enabled.
    if (mounted) {
      // Save so we only auto-prompt once per account login event cycle
      await prefs.setBool('has_prompted_2fa_${user.uid}', true);
      
      // Stylish Dialog before launching the setup modal
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.pageBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Secure Account?',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              'Would you like to enable Two-Factor Authentication (2FA) now for enhanced account security?',
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Maybe Later', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  TwoFactorSetupDialog.show(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Setup Now'),
              ),
            ],
          ),
        );
      }
    }
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
    final isDesktop = MediaQuery.of(context).size.width >= 1150;

    return Scaffold(
      endDrawer: const NotificationDrawer(),
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        cleanCMSUsername(user?.name ?? 'Guest'), 
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26, 
                                          fontWeight: FontWeight.w800, 
                                          color: AppColors.textPrimary(context), 
                                          letterSpacing: -0.5
                                        ),
                                        maxLines: 1,
                                      ),
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
            if (isDesktop) ...[
              _buildDesktopRightPanel(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRightPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    final buildings = ['Library', 'Science Block', 'Hostel', 'Main Café', 'Admin Office', 'Engineering Dept'];
    final categories = ['Electronics', 'Keys & Cards', 'Bags & Wallets', 'Documents', 'Books & Stationery', 'Others'];
    final recencyOptions = ['Today', 'Last 3 Days', 'This Week', 'This Month'];

    final hasActiveFilter = _selectedBuilding != null || _selectedCategory != null || _selectedRecency != null;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0E17) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
                if (hasActiveFilter)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBuilding = null;
                        _selectedCategory = null;
                        _selectedRecency = null;
                      });
                    },
                    child: Text(
                      'Reset Filters',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.jadePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Inline Filters Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'REFINED CONTROLS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.jadePrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDesktopDropdown<String>(
                    label: 'Campus Block',
                    value: _selectedBuilding,
                    placeholder: 'All Buildings',
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Buildings')),
                      ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                    ],
                    onChanged: (val) => setState(() => _selectedBuilding = val),
                  ),
                  const SizedBox(height: 16),

                  _buildDesktopDropdown<String>(
                    label: 'Category',
                    value: _selectedCategory,
                    placeholder: 'All Categories',
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),

                  _buildDesktopDropdown<String>(
                    label: 'Date Range',
                    value: _selectedRecency,
                    placeholder: 'All Time',
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Time')),
                      ...recencyOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                    ],
                    onChanged: (val) => setState(() => _selectedRecency = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Scanner Promo Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [AppColors.jadePrimary.withOpacity(0.15), Colors.transparent]
                      : [AppColors.jadePrimary.withOpacity(0.08), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.jadePrimary.withOpacity(0.2),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.jadePrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.center_focus_weak_rounded,
                          color: AppColors.jadePrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Scanner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lost an item? Upload or take a picture of your belonging. Our AI scanner matches features instantly against all campus found entries.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const VisualSearchSheet(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.jadePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Launch AI Scanner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Hub
            Text(
              'CAMPUS STATUS SUMMARY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatHubRow(
              icon: Icons.radar_rounded,
              title: 'Active Lost Items',
              value: '12 Reports',
              color: AppColors.lost,
            ),
            const SizedBox(height: 10),
            _buildStatHubRow(
              icon: Icons.handshake_rounded,
              title: 'Recovered Belongings',
              value: '84 Claims',
              color: AppColors.found,
            ),
            const SizedBox(height: 10),
            _buildStatHubRow(
              icon: Icons.emoji_events_rounded,
              title: 'Leaderboard Karma',
              value: 'Level 4 (Elite)',
              color: Colors.amber.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary(context),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: Text(
                placeholder,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary(context),
                size: 20,
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatHubRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

class _PostFeed extends ConsumerStatefulWidget {
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
  ConsumerState<_PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends ConsumerState<_PostFeed> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Proactively load next chunk when user hits 85% scroll depth
    if (currentScroll >= (maxScroll * 0.85)) {
      final config = FeedFilterConfig(
        query: widget.query,
        filter: widget.filter,
        building: widget.building,
        category: widget.category,
        recency: widget.recency,
      );
      ref.read(paginatedFeedProvider(config).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = FeedFilterConfig(
      query: widget.query,
      filter: widget.filter,
      building: widget.building,
      category: widget.category,
      recency: widget.recency,
    );

    final feedAsync = ref.watch(paginatedFeedProvider(config));

    return feedAsync.when(
      loading: () => const _LoadingFeed(),
      error: (err, _) => Center(child: Text('Connection failure: $err', style: const TextStyle(color: Colors.grey))),
      data: (state) {
        if (state.posts.isEmpty) {
          return const LottieEmptyStateWidget(
            lottieAsset: 'assets/animations/empty_feed.json',
            fallbackIcon: Icons.travel_explore_rounded,
            title: 'No Items Discovered',
            subtitle: 'Try adjusting your filters, or check the Map to see items around campus.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(paginatedFeedProvider(config)),
          color: AppColors.jadePrimary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridWidth = constraints.maxWidth;
              final crossCount = gridWidth > 1150 
                  ? 4 
                  : (gridWidth > 800 ? 3 : (gridWidth > 480 ? 2 : 1));

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.64,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = state.posts[index];
                          return PostCard(post: post)
                              .animate()
                              .fadeIn(delay: (index % 10 * 40).ms)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
                        },
                        childCount: state.posts.length,
                      ),
                    ),
                  ),
                  
                  // Loading more indicator at very bottom
                  if (state.isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.jadePrimary),
                          ),
                        ),
                      ),
                    ),

                  // Extra bottom buffer padding to account for bottom nav bars
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth;
        final crossCount = gridWidth > 1150 
            ? 4 
            : (gridWidth > 800 ? 3 : (gridWidth > 480 ? 2 : 1));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.64,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonPostCard(),
        );
      },
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
    
    // PRE-CALCULATION OPTIMIZATION: Compute constants ONCE outside the iteration loop
    final String? cLower = category?.toLowerCase();
    final String? qTrim = query.trim().isEmpty ? null : query.toLowerCase().trim();
    final List<String> qWords = (qTrim != null) ? qTrim.split(' ').where((w) => w.length > 1).toList() : [];
    final DateTime now = DateTime.now();
    final String? bLower = building?.toLowerCase();

    final filtered = activeClaims.where((c) {
      final post = c['posts'];
      if (post == null) return false;
      
      final String postBuilding = post['location']?['building']?.toString() ?? '';
      
      // 1. Campus Building Filtering (Uses pre-lowercased constant)
      if (bLower != null && postBuilding.toLowerCase() != bLower) {
        return false;
      }

      // 2. Category Semantic Keyword Filtering
      if (cLower != null) {
        final title = (post['title'] ?? '').toString().toLowerCase();
        final desc = (post['description'] ?? '').toString().toLowerCase();
        final tags = (post['aiTags'] != null) 
            ? (post['aiTags'] as List).map((t) => t.toString().toLowerCase()).toList() 
            : <String>[];

        bool hasMatch = false;
        if (cLower == 'electronics') {
          const keywords = ['electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch', 'camera'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (cLower == 'keys & cards') {
          const keywords = ['key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge', 'cnic'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (cLower == 'bags & wallets') {
          const keywords = ['bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede', 'pocketbook'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (cLower == 'documents') {
          const keywords = ['document', 'paper', 'file', 'cnic', 'passport', 'booklet', 'degree', 'certificate'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (cLower == 'books & stationery') {
          const keywords = ['book', 'stationery', 'pen', 'pencil', 'notebook', 'register', 'binder', 'calculator'];
          hasMatch = keywords.any((kw) => title.contains(kw) || desc.contains(kw) || tags.contains(kw));
        } else if (cLower == 'others') {
          const keywords = [
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

      // 3. Date Recency Filtering (Uses cached baseline DateTime)
      if (recency != null && post['timestamp'] != null) {
        try {
          final pTime = DateTime.parse(post['timestamp'].toString());
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
        } catch (_) {
          // Safety capture for parse issues
        }
      }

      // 4. Tokenized Search Query Filtering
      if (qTrim != null) {
        final title = (post['title'] ?? '').toString().toLowerCase();
        final desc = (post['description'] ?? '').toString().toLowerCase();
        final bName = postBuilding.toLowerCase();

        if (title.contains(qTrim) || desc.contains(qTrim) || bName.contains(qTrim)) {
          return true;
        }

        if (qWords.isEmpty) return false;

        int matchScore = 0;
        for (var word in qWords) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridWidth = constraints.maxWidth;
            final crossCount = gridWidth > 1150 
                ? 4 
                : (gridWidth > 800 ? 3 : (gridWidth > 480 ? 2 : 1));

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
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
            );
          },
        ),
      ),
    );
  }
}
