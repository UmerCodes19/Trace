import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFD32F2F) : null,
      action: action,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
