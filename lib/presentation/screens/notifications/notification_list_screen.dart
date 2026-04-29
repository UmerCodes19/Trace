import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final user = ref.read(authServiceProvider).currentUser;
              if (user != null) {
                await ref.read(apiServiceProvider).markAllNotificationsRead(user.uid);
                ref.refresh(notificationsProvider);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) return _EmptyState();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index] as Map<String, dynamic>;
                return _NotificationCard(
                  notification: {
                    ...n,
                    'time': _formatTimestamp(n['timestamp']),
                  },
                ).animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideX(begin: 0.1, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    // Handle both snake_case (new) and camelCase (old) for safety
    final isRead = (notification['is_read'] ?? notification['isRead'] ?? true) as bool;
    final type = (notification['type'] ?? 'general') as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'match':
        icon = Icons.auto_awesome;
        color = AppColors.jadePrimary;
        break;
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = AppColors.textSecondary(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead 
            ? AppColors.card(context).withOpacity(0.5)
            : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead 
              ? Colors.transparent 
              : AppColors.jadePrimary.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification['title'],
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      notification['time'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['body'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.jadePrimary,
                shape: BoxShape.circle,
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
