// lib/presentation/screens/shell/main_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  List<_TabItem> _getTabs() {
    final user = ref.read(authServiceProvider).currentUser;
    final isAdmin = user?.isAdmin ?? false;
    return [
      const _TabItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Feed', path: '/home'),
      const _TabItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map', path: '/map'),
      const _TabItem(icon: Icons.add_rounded, activeIcon: Icons.add_rounded, label: 'Post', path: '/create'),
      const _TabItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chats', path: '/chats'),
      _TabItem(
        icon: isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
        activeIcon: isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
        label: isAdmin ? 'Admin' : 'Profile',
        path: isAdmin ? '/admin' : '/profile',
      ),
    ];
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.mediumImpact();
    setState(() => _currentIndex = index);
    context.go(_getTabs()[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs();
    final location = GoRouterState.of(context).uri.toString();
    final resolvedIndex = tabs.indexWhere((t) => location.startsWith(t.path));
    if (resolvedIndex != -1 && resolvedIndex != _currentIndex) {
      Future.microtask(() { if (mounted) setState(() => _currentIndex = resolvedIndex); });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allow body to flow behind the floating dock
      body: widget.child,
      bottomNavigationBar: _ImmersiveFloatingDock(
        currentIndex: _currentIndex,
        tabs: tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _ImmersiveFloatingDock extends StatelessWidget {
  const _ImmersiveFloatingDock({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.jadePrimary;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 32.0 : 50.0; // Higher for better ergonomics

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomMargin),
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Background
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.black.withOpacity(0.7) 
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final isSelected = currentIndex == index;
                final tab = tabs[index];
                
                // Special handling for the center 'Post' button
                if (index == 2) {
                  return _PostActionCircle(onTap: () => onTap(index));
                }

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? accent : AppColors.textSecondary(context),
                          size: 24,
                        ).animate(target: isSelected ? 1 : 0).scale(
                          begin: const Offset(1, 1), 
                          end: const Offset(1.2, 1.2),
                          curve: Curves.elasticOut,
                          duration: 400.ms,
                        ),
                        const SizedBox(height: 4),
                        if (isSelected)
                          Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                          ).animate().scale(curve: Curves.easeOutBack),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 1, end: 0, curve: Curves.easeOutQuart);
  }
}

class _PostActionCircle extends StatelessWidget {
  const _PostActionCircle({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.jadePrimary, AppColors.deepJade],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.jadePrimary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: 2.seconds,
      curve: Curves.easeInOut,
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.path});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
