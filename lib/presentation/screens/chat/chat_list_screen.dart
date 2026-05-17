import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_chat_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/lottie_empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/user_avatar.dart';
import '../../../core/utils/tutorial_keys.dart';
import '../../../core/utils/app_guide_orchestrator.dart';
import '../../../core/services/tutorial_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  List<SimpleChatModel> _chats = [];
  String _uid = '';
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadChats(silent: true),
    );
    // Force safety evaluation as soon as messaging view mounts
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInboxTour());
  }



  Future<void> _checkInboxTour() async {
    if (!mounted) return;
    final notifier = ref.read(activeTourStateProvider.notifier);
    if (notifier.state != ActiveTourState.inbox) return;
    notifier.state = ActiveTourState.none; // Consume immediately

    // Patiently poll until dynamic chat stream buffers successfully
    int retryCount = 0;
    while (_isLoading && mounted && retryCount < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      retryCount++;
    }

    if (mounted && !_isLoading) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _launchInboxTour();
    }
  }

  Future<void> _launchInboxTour() async {
    final service = ref.read(tutorialServiceProvider);
    if (await service.isFeatureTourCompleted('inbox_tour')) return;

    final targets = <TargetFocus>[
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.inboxListKey,
        title: 'Chats',
        description: 'Talk with other students to claim items.',
        stepLabel: 'Inbox',
        align: ContentAlign.bottom,
        radius: 24,
      ),
    ];

    final notifier = ref.read(activeTourStateProvider.notifier);
    final router = GoRouter.of(context);

    AppGuideOrchestrator.showTutorial(
      context: context,
      featureKey: 'inbox_tour',
      targets: targets,
      tutorialService: service,
      onFinish: () {
        notifier.state = ActiveTourState.profile;
        router.go('/profile');
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats({bool silent = false}) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _uid = '';
        _isLoading = false;
        _chats = [];
      });
      return;
    }

    final api = ref.read(apiServiceProvider);
    final chatsData = await api.getUserChats(user.uid);
    if (!mounted) return;

    setState(() {
      _uid = user.uid;
      _chats = chatsData.map((c) => SimpleChatModel.fromMap(Map<String, dynamic>.from(c as Map))).toList();
      if (!silent) {
        _isLoading = false;
      }
    });
    if (!silent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkInboxTour());
    }
  }

  Future<void> _deleteChat(SimpleChatModel chat) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Chat?'),
        content: const Text('This will permanently remove the entire conversation. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final String chatId = chat.id;
      // Optimistic instant state update
      setState(() {
        _chats.removeWhere((c) => c.id == chatId);
      });

      final api = ref.read(apiServiceProvider);
      final success = await api.deleteChat(chatId);
      if (mounted && !success) {
        showAppSnack(context, 'Failed to delete chat server-side', isError: true);
        _loadChats(silent: true); // Rollback if sync failed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUnread = _chats.fold<int>(0, (sum, c) => sum + (c.unreadCount[_uid] ?? 0));

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                  'Inbox',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              background: Container(
                key: TutorialKeys.inboxListKey,
                child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [Colors.blue.withOpacity(0.15), Colors.transparent] 
                              : [accent.withOpacity(0.08), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: -30,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: accent.withOpacity(isDark ? 0.08 : 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
            actions: [
              if (totalUnread > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lostAlert.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalUnread UNREAD',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lostAlert,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _loadChats(),
                icon: Icon(Icons.sync_rounded, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(width: 12),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Conversations regarding lost & found claims.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary(context).withOpacity(0.7),
                ),
              ),
            ),
          ),

          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SkeletonChatTile(),
                ),
                childCount: 6,
              ),
            )
          else if (_uid.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Login required')),
            )
          else if (_chats.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: LottieEmptyStateWidget(
                lottieAsset: 'assets/lottie/empty_chats.json',
                fallbackIcon: Icons.forum_outlined,
                title: 'No conversations yet',
                subtitle: 'Start a conversation by claiming an item on the feed.',
                actionLabel: 'Browse Items',
                onAction: () => context.go('/home'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final chat = _chats[i];
                    final unread = chat.unreadCount[_uid] ?? 0;
                    final hasPost = (chat.postTitle ?? '').isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Dismissible(
                        key: ValueKey(chat.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (direction) async {
                          await _deleteChat(chat);
                          // Return false because our manual _deleteChat logic triggers explicit internal list update/snack 
                          // managing the remove lifecycle correctly.
                          return false;
                        },
                        child: InkWell(
                          onTap: () => context.push('/chat/${chat.id}').then((_) => _loadChats()),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: unread > 0 
                                ? accent.withOpacity(isDark ? 0.1 : 0.05)
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: unread > 0
                                  ? accent.withOpacity(0.3)
                                  : AppColors.border(context).withOpacity(0.5),
                              width: unread > 0 ? 1.5 : 0.8,
                            ),
                            boxShadow: [
                              if (unread > 0)
                                BoxShadow(
                                  color: accent.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Rich Avatar pod
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: unread > 0 ? accent : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: UserAvatar(
                                      photoURL: chat.otherUserAvatar,
                                      radius: 26,
                                    ),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.surface(context), width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              
                              // Content body
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            chat.otherUserName?.toUpperCase() ?? 'CAMPUS USER',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                              color: AppColors.textPrimary(context).withOpacity(0.6),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          AppDateUtils.shortTime(chat.lastMessageTime),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                            color: unread > 0 ? accent : AppColors.textSecondary(context).withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Last Message Preview
                                    Text(
                                      chat.lastMessage.isEmpty ? 'Say hi! 👋' : chat.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Contextual item badge
                                    if (hasPost)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.inventory_2_outlined, 
                                              size: 11, 
                                              color: AppColors.textSecondary(context).withOpacity(0.7)),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                chat.postTitle!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary(context),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                      ),
                      ),
                    );
                  },
                  childCount: _chats.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
