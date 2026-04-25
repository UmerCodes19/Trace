import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      const _TabItem(icon: Icons.home_rounded, label: 'Home', path: '/home'),
      const _TabItem(icon: Icons.map_rounded, label: 'Map', path: '/map'),
      const _TabItem(icon: Icons.add_circle_rounded, label: 'Post', path: '/create'),
      const _TabItem(icon: Icons.chat_bubble_rounded, label: 'Chats', path: '/chats'),
      if (isAdmin)
        const _TabItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin', path: '/admin')
      else
        const _TabItem(icon: Icons.person_rounded, label: 'Profile', path: '/profile'),
    ];
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    final tabs = _getTabs();
    context.go(tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs();
    final location = GoRouterState.of(context).uri.toString();
    final resolvedIndex = tabs.indexWhere((t) => location.startsWith(t.path));
    if (resolvedIndex != -1 && resolvedIndex != _currentIndex) {
      _currentIndex = resolvedIndex;
    }

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: _SmartDock(
        currentIndex: _currentIndex,
        tabs: tabs,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Smart Floating Dock ───────────────────────────────────────────────
class _SmartDock extends StatelessWidget {
  const _SmartDock({
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
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      bottom: true,
      child: Container(
        height: 100, // Room for the overlapping center button
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // The Glass Pill
            Container(
              height: 68,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withOpacity(0.65)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : AppColors.navyLight.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _DockItem(tab: tabs[0], isSelected: currentIndex == 0, accent: accent, onTap: () => onTap(0)),
                      _DockItem(tab: tabs[1], isSelected: currentIndex == 1, accent: accent, onTap: () => onTap(1)),
                      const SizedBox(width: 60), // Space for center FAB
                      _DockItem(tab: tabs[3], isSelected: currentIndex == 3, accent: accent, onTap: () => onTap(3)),
                      _DockItem(tab: tabs[4], isSelected: currentIndex == 4, accent: accent, onTap: () => onTap(4)),
                    ],
                  ),
                ),
              ),
            ),
            
            // The Elevated Center Button
            Positioned(
              top: 4,
              child: _CenterPostButton(
                accent: accent,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPostButton extends StatefulWidget {
  const _CenterPostButton({required this.accent, required this.isSelected, required this.onTap});
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CenterPostButton> createState() => _CenterPostButtonState();
}

class _CenterPostButtonState extends State<_CenterPostButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.accent,
                HSLColor.fromColor(widget.accent).withHue((HSLColor.fromColor(widget.accent).hue + 30) % 360).toColor(),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 0,
                spreadRadius: 1,
                offset: const Offset(0, 1) // Inner highlight effect
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.tab,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final _TabItem tab;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
              child: Icon(
                tab.icon,
                color: isSelected ? accent : (isDark ? Colors.white54 : AppColors.textHint(context)),
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label, required this.path});

  final IconData icon;
  final String label;
  final String path;
}
