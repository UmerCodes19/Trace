import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

/// ─── Date / Time ─────────────────────────────────────────────────────────────
class AppDateUtils {
  AppDateUtils._();

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }

  static String friendlyDate(DateTime dt) =>
      DateFormat('EEEE, MMMM d').format(dt);

  static String shortTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt);
}

/// ─── Distance ────────────────────────────────────────────────────────────────
class AppDistanceUtils {
  AppDistanceUtils._();

  static String friendlyDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m away';
    return '${(meters / 1000).toStringAsFixed(1)}km away';
  }
}

/// ─── Haptics ─────────────────────────────────────────────────────────────────
class AppHaptics {
  AppHaptics._();

  static void light()   => HapticFeedback.lightImpact();
  static void medium()  => HapticFeedback.mediumImpact();
  static void heavy()   => HapticFeedback.heavyImpact();
  static void success() => HapticFeedback.heavyImpact();
}

/// ─── Greeting ────────────────────────────────────────────────────────────────
String timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// ─── Snackbar ────────────────────────────────────────────────────────────────
void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.redAccent : AppColors.jadePrimary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFA151E1D) : const Color(0xFAFFFFFF),
      elevation: 8,
      action: action,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 3200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isError 
              ? Colors.redAccent.withOpacity(0.3) 
              : AppColors.jadePrimary.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 82), // Floats cleanly over the custom bottom navigation
    ),
  );
}

/// ─── Input sanitization ──────────────────────────────────────────────────────
String sanitizeInput(String input) {
  String result = input.trim();
  result = result.replaceAll('<', '');
  result = result.replaceAll('>', '');
  result = result.replaceAll('"', '');
  result = result.replaceAll("'", '');
  return result;
}
