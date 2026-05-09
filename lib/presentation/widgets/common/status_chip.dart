import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// ─── Status Chip ─────────────────────────────────────────────────────────────
/// A glowing, glassmorphic status chip with a pulsing vector icon and soft backdrop shadows.
class StatusChip extends StatefulWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.small = false,
    this.icon,
  });

  /// Named constructors for common statuses
  factory StatusChip.lost({bool small = false}) => StatusChip(
        label: 'LOST',
        color: AppColors.lostAlert,
        small: small,
        icon: Icons.search_rounded,
      );

  factory StatusChip.found({bool small = false}) => StatusChip(
        label: 'FOUND',
        color: AppColors.foundSuccess,
        small: small,
        icon: Icons.verified_user_rounded,
      );

  factory StatusChip.returned({bool small = false}) => StatusChip(
        label: 'RETURNED',
        color: AppColors.navyLight,
        showDot: false,
        small: small,
        icon: Icons.assignment_turned_in_rounded,
      );

  factory StatusChip.open({bool small = false}) => StatusChip(
        label: 'OPEN',
        color: AppColors.lostAlert,
        small: small,
        icon: Icons.search_rounded,
      );

  factory StatusChip.resolved({bool small = false}) => StatusChip(
        label: 'RESOLVED',
        color: AppColors.foundSuccess,
        showDot: false,
        small: small,
        icon: Icons.verified_user_rounded,
      );

  factory StatusChip.approved({bool small = false}) => StatusChip(
        label: 'APPROVED',
        color: const Color(0xFF00E676), // Vibrant emerald green
        small: small,
        icon: Icons.check_circle_rounded,
        showDot: false,
      );

  factory StatusChip.pending({bool small = false}) => StatusChip(
        label: 'PENDING',
        color: const Color(0xFFFFB300), // Vibrant golden amber
        small: small,
        icon: Icons.hourglass_empty_rounded,
      );

  factory StatusChip.rejected({bool small = false}) => StatusChip(
        label: 'REJECTED',
        color: const Color(0xFFFF1744), // Vibrant hot red
        small: small,
        icon: Icons.cancel_rounded,
        showDot: false,
      );

  final String label;
  final Color color;
  final bool showDot;
  final bool small;
  final IconData? icon;

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
    _pulse = Tween(begin: 0.85, end: 1.02).animate(
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
    final fontSize = widget.small ? 9.5 : 10.5;
    final hPad = widget.small ? 9.0 : 11.0;
    final vPad = widget.small ? 4.5 : 6.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.50),
                widget.color.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.55), // Vibrant sharp border
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.12),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Transform.scale(
                    scale: widget.showDot ? _pulse.value : 1.0,
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: widget.small ? 12.0 : 13.5,
                    ),
                  ),
                ),
                SizedBox(width: widget.small ? 4 : 5),
              ],
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
