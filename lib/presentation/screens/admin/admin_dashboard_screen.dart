import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/models/simple_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pressable_scale.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<SimplePostModel> _flaggedPosts = [];
  List<SimpleUserModel> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    final api = ref.read(apiServiceProvider);
    
    final stats = await api.getAdminStats();
    final flags = await api.getFlaggedPosts();
    final users = await api.getAllUsers();
    
    if (mounted) {
      setState(() {
        _stats = stats;
        _flaggedPosts = flags.map((m) => SimplePostModel.fromMap(m)).toList();
        _allUsers = users.map((m) => SimpleUserModel.fromMap(m)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Moderation'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildStatsTab(),
              _buildModerationTab(),
              _buildUsersTab(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshAll,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StatCard(
          title: 'Total Posts',
          value: '${_stats['totalPosts'] ?? 0}',
          icon: Icons.article_rounded,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Resolution Rate',
          value: '${(_stats['resolutionRate'] ?? 0).toStringAsFixed(1)}%',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Total Users',
          value: '${_stats['totalUsers'] ?? 0}',
          icon: Icons.people_rounded,
          color: Colors.purple,
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Total Comments',
          value: '${_stats['totalComments'] ?? 0}',
          icon: Icons.comment_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildModerationTab() {
    if (_flaggedPosts.isEmpty) {
      return Center(
        child: Text('No flagged posts! 🎉', 
          style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _flaggedPosts.length,
      itemBuilder: (context, index) {
        final post = _flaggedPosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
            title: Text(post.title),
            subtitle: Text('Reports: ${post.reportCount}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () => _confirmDeletePost(post.id),
                ),
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.green),
                  onPressed: () => _ignorePost(post.id),
                ),
              ],
                    ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Switch(
              value: user.isBanned,
              activeColor: Colors.red,
              onChanged: (val) => _toggleBan(user.uid, val),
                    ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _toggleBan(String uid, bool isBanned) async {
    final api = ref.read(apiServiceProvider);
    await api.setUserBanStatus(uid, isBanned);
    _refreshAll();
    if (mounted) {
      showAppSnack(context, isBanned ? 'User banned' : 'User unbanned');
    }
  }

  Future<void> _confirmDeletePost(String postId) async {
    final api = ref.read(apiServiceProvider);
    await api.deletePost(postId);
    _refreshAll();
    if (mounted) showAppSnack(context, 'Post deleted by admin');
  }

  Future<void> _ignorePost(String postId) async {
    // Clear reports
    final api = ref.read(apiServiceProvider);
    await api.clearPostReports(postId);
    _refreshAll();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
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
