import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class NotificationDrawer extends ConsumerStatefulWidget {
  const NotificationDrawer({super.key});

  static void _onNotificationTap(BuildContext context, WidgetRef ref, Map<String, dynamic> n) async {
    final api = ref.read(apiServiceProvider);
    
    try {
      await api.markNotificationRead(n['id']);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }

    final type = n['type']?.toString().toLowerCase() ?? 'general';
    final data = n['data'] as Map<String, dynamic>? ?? {};

    if (type == 'match' && data['postId'] != null) {
      context.push('/post/${data['postId']}');
    } else if (type == 'claim_request' && data['postId'] != null) {
      context.push('/post/${data['postId']}/claims?title=${Uri.encodeComponent(n['title'] ?? 'Post')}');
    } else if ((type == 'claim_response' || type == 'claim_accepted') && data['chatId'] != null) {
      context.push('/chat/${data['chatId']}');
    } else if (type == 'item_resolved' && data['postId'] != null) {
      context.push('/post/${data['postId']}');
    } else if (data['postId'] != null) {
      context.push('/post/${data['postId']}');
    }
  }

  @override
  ConsumerState<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends ConsumerState<NotificationDrawer> {
  bool _isClearingOptimistically = false;

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'unknown';
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final Duration diff = DateTime.now().difference(dt);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Drawer(
      backgroundColor: AppColors.pageBg(context),
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(32))),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded),
                        tooltip: 'Mark all as read',
                        onPressed: () async {
                          final user = ref.read(authServiceProvider).currentUser;
                          if (user != null) {
                            await ref.read(apiServiceProvider).markAllNotificationsRead(user.uid);
                            ref.invalidate(notificationsProvider);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.lostAlert),
                        tooltip: 'Clear all',
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear All?'),
                              content: const Text('Do you want to delete all notifications permanently?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('Clear', style: TextStyle(color: AppColors.lostAlert))
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final user = ref.read(authServiceProvider).currentUser;
                            if (user != null) {
                              // STEP 1: Instant visual feedback
                              setState(() {
                                _isClearingOptimistically = true;
                              });
                              
                              // STEP 2: Execute back-end silent processing
                              try {
                                await ref.read(apiServiceProvider).clearAllNotifications(user.uid);
                                ref.invalidate(notificationsProvider);
                              } catch (e) {
                                debugPrint('Clear fail silently handled.');
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isClearingOptimistically 
                  ? _EmptyState() // Immediately override and show empty
                  : notificationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (notifications) {
                        if (notifications.isEmpty) return _EmptyState();
                        return _NotificationList(initialNotifications: notifications.map((e) => e as Map<String, dynamic>).toList());
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isRead = (notification['is_read'] ?? notification['isRead'] ?? true) as bool;
    final type = (notification['type'] ?? 'general') as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'match':
        icon = Icons.auto_awesome;
        color = AppColors.jadePrimary;
        break;
      case 'claim_request':
        icon = Icons.card_giftcard_rounded;
        color = Colors.amber;
        break;
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.blue;
        break;
      case 'item_resolved':
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = AppColors.textSecondary(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? Colors.transparent : color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isRead ? [] : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'] ?? 'Notification',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notification['time'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isRead ? AppColors.textSecondary(context).withOpacity(0.6) : color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification['body'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary(context).withOpacity(isRead ? 0.7 : 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(left: 12, top: 6),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textSecondary(context).withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications at the moment.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary(context).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> initialNotifications;
  const _NotificationList({required this.initialNotifications});

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialNotifications);
  }

  @override
  void didUpdateWidget(covariant _NotificationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNotifications.length != oldWidget.initialNotifications.length) {
      setState(() {
        _items = List.from(widget.initialNotifications);
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'unknown';
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return 'm ago';
    if (diff.inHours < 24) return 'h ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return _EmptyState();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(notificationsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = _items[index];
          return Dismissible(
            key: Key(n['id'].toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              final id = n['id'];
              setState(() {
                _items.removeAt(index);
              });
              try {
                await ref.read(apiServiceProvider).deleteNotification(id);
                // Invalidate provider to make sure app-wide badges stay synced
                ref.invalidate(notificationsProvider);
              } catch (e) {
                debugPrint('Failed to delete notification: ');
              }
            },
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lostAlert.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lostAlert.withOpacity(0.3)),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.lostAlert),
            ),
            child: GestureDetector(
              onTap: () => NotificationDrawer._onNotificationTap(context, ref, n),
              child: _NotificationCard(
                notification: {
                  ...n,
                  'time': _formatTimestamp(n['timestamp']),
                },
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

