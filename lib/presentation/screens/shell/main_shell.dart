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
      const _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/home'),
      const _TabItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map', path: '/map'),
      const _TabItem(icon: Icons.add_box_outlined, activeIcon: Icons.add_box_rounded, label: 'Create', path: '/create'),
      const _TabItem(icon: Icons.play_circle_outline_rounded, activeIcon: Icons.play_circle_fill_rounded, label: 'Traces', path: '/reels'),
      const _TabItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Inbox', path: '/chats'),
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
        onHorizontalDragEnd: location.startsWith('/map') ? null : (details) {
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

class _MorphingActivePillDock extends StatefulWidget {
  const _MorphingActivePillDock({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  @override
  State<_MorphingActivePillDock> createState() => _MorphingActivePillDockState();
}

class _MorphingActivePillDockState extends State<_MorphingActivePillDock> {
  double? _manualDragX;
  double _stretchScaleX = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 14.0 : 26.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final dockWidth = screenWidth - 48; // 24 padding on each side
    
    // Dynamic Flex Math
    final activeWidth = (dockWidth - 24) * 0.40; // Active gets 40% of inner space
    final inactiveWidth = ((dockWidth - 24) - activeWidth) / (widget.tabs.length - 1);

    final tabWidths = List<double>.filled(widget.tabs.length, 0.0);
    for (int i = 0; i < widget.tabs.length; i++) {
      tabWidths[i] = (widget.currentIndex == i) ? activeWidth : inactiveWidth;
    }

    double currentLeft = 0;
    final tabPositions = <double>[];
    for (int i = 0; i < widget.tabs.length; i++) {
      tabPositions.add(currentLeft);
      currentLeft += tabWidths[i];
    }

    // Determine position left for active highlight pill
    double highlightLeft;
    double highlightWidth = tabWidths[widget.currentIndex];

    if (_manualDragX != null) {
      highlightLeft = (_manualDragX! - 12 - (highlightWidth / 2)).clamp(0.0, dockWidth - 24 - highlightWidth);
    } else {
      highlightLeft = tabPositions[widget.currentIndex];
    }

    void _handleDragUpdate(double localX, double deltaX) {
      setState(() {
        _manualDragX = localX;
        final targetScale = (1.0 + (deltaX.abs() * 0.12)).clamp(1.0, 1.40);
        _stretchScaleX = (_stretchScaleX * 0.6) + (targetScale * 0.4);
      });

      int closestIndex = widget.currentIndex;
      double minDistance = double.infinity;
      for (int i = 0; i < widget.tabs.length; i++) {
        final center = tabPositions[i] + tabWidths[i] / 2;
        final distance = (center - (localX - 12)).abs();
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }

      if (closestIndex != widget.currentIndex) {
        HapticFeedback.lightImpact();
        widget.onTap(closestIndex);
      }
    }

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomMargin),
      height: 64,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          setState(() {
            _manualDragX = details.localPosition.dx;
            _stretchScaleX = 1.05;
          });
          HapticFeedback.selectionClick();
        },
        onHorizontalDragUpdate: (details) {
          _handleDragUpdate(details.localPosition.dx, details.primaryDelta ?? 0.0);
        },
        onHorizontalDragEnd: (details) {
          setState(() {
            _manualDragX = null;
            _stretchScaleX = 1.0;
          });
          HapticFeedback.mediumImpact();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Translucent pure glass structure
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xE60A0A0A) // Deep Onyx
                        : const Color(0xF2FFFFFF), // Pure Alabaster
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.08) 
                          : Colors.black.withOpacity(0.05),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.5) 
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Morphing Active Pill highlight shape with liquid glass stretching
            AnimatedPositioned(
              duration: _manualDragX != null ? Duration.zero : const Duration(milliseconds: 320),
              curve: _manualDragX != null ? Curves.linear : Curves.easeOutBack,
              left: 12 + highlightLeft,
              top: 8,
              width: highlightWidth,
              height: 48,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(_stretchScaleX, 1.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accent.withOpacity(isDark ? 0.25 : 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(widget.tabs.length, (index) {
                  final isSelected = widget.currentIndex == index;
                  final tab = widget.tabs[index];
                  
                  return GestureDetector(
                    onTap: () => widget.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      width: tabWidths[index],
                      height: 64,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isSelected ? accent : AppColors.textSecondary(context).withOpacity(0.7),
                            size: 22,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    letterSpacing: -0.2,
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
