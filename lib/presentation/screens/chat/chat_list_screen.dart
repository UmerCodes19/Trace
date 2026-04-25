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
      _chats = chatsData.map((c) => SimpleChatModel.fromMap(c)).toList();
      if (!silent) {
        _isLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Messages',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          GlassCard(
            borderRadius: 40,
            child: IconButton(
              onPressed: () => _loadChats(),
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.textPrimary(context),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => const SkeletonChatTile(),
            )
          : _uid.isEmpty
              ? const Center(child: Text('Login required'))
                  : _chats.isEmpty
                  ? LottieEmptyStateWidget(
                      lottieAsset: 'assets/lottie/empty_chats.json',
                      fallbackIcon: Icons.forum_outlined,
                      title: 'No chats yet',
                      subtitle:
                          'Open a post and tap claim to start a conversation.',
                      actionLabel: 'Browse Items',
                      onAction: () => context.go('/home'),
                    )
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadChats,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        itemCount: _chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final chat = _chats[i];
                          final unread = chat.unreadCount[_uid] ?? 0;

                          return InkWell(
                            onTap: () => context
                                .push('/chat/${chat.id}')
                                .then((_) => _loadChats()),
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              borderRadius: 16,
                              elevation: 1,
                              borderGlow: unread > 0
                                  ? accent.withOpacity(0.2)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: accent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (chat.postTitle ?? '').isEmpty
                                                ? 'Conversation'
                                                : chat.postTitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color:
                                                  AppColors.textPrimary(context),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chat.lastMessage.isEmpty
                                                ? 'No messages yet'
                                                : chat.lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textSecondary(
                                                  context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppDateUtils.shortTime(
                                              chat.lastMessageTime),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary(
                                                context),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      accent.withOpacity(0.3),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              unread > 99
                                                  ? '99+'
                                                  : '$unread',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: i * 50));
                        },
                      ),
                    ),
    );
  }
}
