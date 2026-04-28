import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper that applies a press-down scale animation (0.98) with
/// spring-like physics, plus haptic feedback on tap.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    if (widget.haptic) HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: widget.child,
      ),
    );
  }
}
