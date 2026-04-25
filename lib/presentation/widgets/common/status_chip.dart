import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// ─── Status Chip ─────────────────────────────────────────────────────────────
/// A glassmorphic status chip with animated pulsing dot indicator.
/// Replaces inline badge implementations across the app.
class StatusChip extends StatefulWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.small = false,
  });

  /// Named constructors for common statuses
  factory StatusChip.lost({bool small = false}) => StatusChip(
        label: 'LOST',
        color: AppColors.lostAlert,
        small: small,
      );

  factory StatusChip.found({bool small = false}) => StatusChip(
        label: 'FOUND',
        color: AppColors.foundSuccess,
        small: small,
      );

  factory StatusChip.returned({bool small = false}) => StatusChip(
        label: 'RETURNED',
        color: AppColors.navyLight,
        showDot: false,
        small: small,
      );

  factory StatusChip.open({bool small = false}) => StatusChip(
        label: 'OPEN',
        color: AppColors.lostAlert,
        small: small,
      );

  factory StatusChip.resolved({bool small = false}) => StatusChip(
        label: 'RESOLVED',
        color: AppColors.foundSuccess,
        showDot: false,
        small: small,
      );

  final String label;
  final Color color;
  final bool showDot;
  final bool small;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.showDot) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? widget.color.withOpacity(0.15)
        : widget.color.withOpacity(0.1);

    final fontSize = widget.small ? 10.0 : 11.0;
    final hPad = widget.small ? 8.0 : 10.0;
    final vPad = widget.small ? 3.0 : 4.0;
    final dotSize = widget.small ? 5.0 : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.color.withOpacity(isDark ? 0.2 : 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDot) ...[
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_pulse.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3 * _pulse.value),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: widget.small ? 4 : 5),
          ],
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: widget.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
