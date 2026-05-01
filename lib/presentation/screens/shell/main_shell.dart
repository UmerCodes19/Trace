// lib/presentation/screens/shell/main_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    context.go(_getTabs()[index].path);
  }

  void _onSwipe(int direction) {
    final nextIndex = _currentIndex + direction;
    if (nextIndex >= 0 && nextIndex < _getTabs().length) {
      _onTap(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs();
    final location = GoRouterState.of(context).uri.toString();
    final resolvedIndex = tabs.indexWhere((t) => location.startsWith(t.path));
    if (resolvedIndex != -1 && resolvedIndex != _currentIndex) {
      Future.microtask(() { if (mounted) setState(() => _currentIndex = resolvedIndex); });
    }

    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          // Swipe Left -> switch to next tab
          if (details.primaryVelocity! < -400) {
            _onSwipe(1);
          } 
          // Swipe Right -> switch to previous tab
          else if (details.primaryVelocity! > 400) {
            _onSwipe(-1);
          }
        },
        child: widget.child,
      ),
      bottomNavigationBar: _MorphingActivePillDock(
        currentIndex: _currentIndex,
        tabs: tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _MorphingActivePillDock extends StatelessWidget {
  const _MorphingActivePillDock({
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
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 14.0 : 26.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final dockWidth = screenWidth - 48;
    
    // Exact center-locked layout math for Morphing Active Pill
    final baseTabWidth = (dockWidth - 24) / tabs.length;
    final activeWidth = baseTabWidth * 1.42;

    // Available width per half (left and right of center button)
    final halfWidth = (dockWidth - 24 - baseTabWidth) / 2;
    final tabWidths = List<double>.filled(tabs.length, 0.0);

    // Left half (tabs 0, 1):
    if (currentIndex == 0 || currentIndex == 1) {
      tabWidths[currentIndex] = activeWidth;
      final otherIndex = currentIndex == 0 ? 1 : 0;
      tabWidths[otherIndex] = halfWidth - activeWidth;
    } else {
      tabWidths[0] = halfWidth / 2;
      tabWidths[1] = halfWidth / 2;
    }

    // Right half (tabs 3, 4):
    if (currentIndex == 3 || currentIndex == 4) {
      tabWidths[currentIndex] = activeWidth;
      final otherIndex = currentIndex == 3 ? 4 : 3;
      tabWidths[otherIndex] = halfWidth - activeWidth;
    } else {
      tabWidths[3] = halfWidth / 2;
      tabWidths[4] = halfWidth / 2;
    }

    // Lock center button exactly to the base width
    tabWidths[2] = baseTabWidth;

    double currentLeft = 0;
    final tabPositions = <double>[];
    for (int i = 0; i < tabs.length; i++) {
      tabPositions.add(currentLeft);
      currentLeft += tabWidths[i];
    }

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomMargin),
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Translucent pure glass structure
          ClipRRect(
            borderRadius: BorderRadius.circular(31),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xEE0A1312)
                      : const Color(0xF4FFFFFF),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.08) 
                        : Colors.black.withOpacity(0.045),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.4) 
                          : Colors.black.withOpacity(0.07),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Option B — The Morphing Active Pill highlight shape
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: 12 + tabPositions[currentIndex],
            top: 7,
            width: tabWidths[currentIndex],
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.jadePrimary.withOpacity(0.18)
                    : AppColors.jadePrimary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.jadePrimary.withOpacity(isDark ? 0.22 : 0.12),
                  width: 1.0,
                ),
              ),
            ),
          ),

          // Tab Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = currentIndex == index;
                final tab = tabs[index];
                
                // Special rendering for center 'Post' button
                if (index == 2) {
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      width: tabWidths[index],
                      height: 62,
                      alignment: Alignment.center,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.jadePrimary, AppColors.deepJade],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.jadePrimary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: tabWidths[index],
                    height: 62,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? accent : AppColors.textSecondary(context).withOpacity(0.72),
                          size: 21,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: isSelected ? 1.0 : 0.0,
                              child: Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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
