import 'package:flutter/material.dart';

/// ─── Brand Colors ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ─── Navy family ──────────────────────────────────────────────────────────
  static const Color navyDarkest = Color(0xFF1B3C53);
  static const Color navyMid     = Color(0xFF234C6A);
  static const Color navyLight   = Color(0xFF456882);

  // ─── Warm canvas (light mode) ─────────────────────────────────────────────
  static const Color beigeWarm   = Color(0xFFD2C1B6);
  static const Color beigeLight  = Color(0xFFF5F0EB);
  static const Color beigeDark   = Color(0xFFBAAFA6);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color lostAlert    = Color(0xFFE0874A);
  static const Color lostAlertBg  = Color(0xFFFBF0E8);
  static const Color foundSuccess = Color(0xFF5A8F6F);
  static const Color foundBg      = Color(0xFFEAF3EE);

  // ─── Neutrals ─────────────────────────────────────────────────────────────
  static const Color white        = Color(0xFFFFFFFF);
  static const Color black        = Color(0xFF0D0D0D);
  static const Color grey100      = Color(0xFFF7F6F5);
  static const Color grey200      = Color(0xFFEAE8E6);
  static const Color grey300      = Color(0xFFD1CEC9);
  static const Color grey500      = Color(0xFF9A958F);
  static const Color grey700      = Color(0xFF5C5853);

  // ─── Shimmer (light) ──────────────────────────────────────────────────────
  static const Color shimmerBase   = Color(0xFFEFEDE9);
  static const Color shimmerHigh   = Color(0xFFFAF8F5);

  // ─── Dark Mode Palette ────────────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0A0A14);
  static const Color darkSurface    = Color(0xFF12121F);
  static const Color darkCard       = Color(0xFF1A1A2E);
  static const Color darkCardHover  = Color(0xFF22223A);
  static const Color darkElevated   = Color(0xFF25253D);
  static const Color darkBorder     = Color(0xFF2D2D48);
  static const Color darkBorderHigh = Color(0xFF3D3D5C);
  static const Color darkText       = Color(0xFFEAEAF2);
  static const Color darkSubtext    = Color(0xFF8888A0);
  static const Color darkHint       = Color(0xFF5E5E78);

  // ─── Dark Shimmer ─────────────────────────────────────────────────────────
  static const Color darkShimmerBase = Color(0xFF1A1A2E);
  static const Color darkShimmerHigh = Color(0xFF2D2D48);

  // ─── Dark Semantic ────────────────────────────────────────────────────────
  static const Color darkLostBg     = Color(0xFF2A1D14);
  static const Color darkFoundBg    = Color(0xFF152218);

  // ─── Accent Presets ───────────────────────────────────────────────────────
  static const Color accentCyan    = Color(0xFF22D3EE);
  static const Color accentTeal    = Color(0xFF2DD4BF);
  static const Color accentIndigo  = Color(0xFF818CF8);
  static const Color accentPurple  = Color(0xFFA78BFA);
  static const Color accentRose    = Color(0xFFFB7185);
  static const Color accentAmber   = Color(0xFFFBBF24);
  static const Color accentEmerald = Color(0xFF34D399);
  static const Color accentCoral   = Color(0xFFFF6B6B);

  static const Color defaultAccent = accentCyan;

  static const List<Color> accentPresets = [
    accentCyan,
    accentTeal,
    accentIndigo,
    accentPurple,
    accentRose,
    accentAmber,
    accentEmerald,
    accentCoral,
  ];

  static const List<String> accentPresetNames = [
    'Cyan',
    'Teal',
    'Indigo',
    'Purple',
    'Rose',
    'Amber',
    'Emerald',
    'Coral',
  ];

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const List<Color> navyGradient = [navyDarkest, navyMid];
  static const List<Color> lostGradient = [lostAlert, Color(0xFFD4663A)];
  static const List<Color> foundGradient= [foundSuccess, Color(0xFF4A7A5F)];

  // Glass gradient overlays
  static const List<Color> darkMeshGradient = [
    Color(0xFF0A0A14),
    Color(0xFF0F1028),
    Color(0xFF14102A),
    Color(0xFF0A0A14),
  ];

  static const List<Color> lightMeshGradient = [
    Color(0xFFF5F0EB),
    Color(0xFFF0E8E0),
    Color(0xFFF5EDE5),
    Color(0xFFF5F0EB),
  ];

  // ─── Glassmorphism helpers ────────────────────────────────────────────────

  /// Glass card background
  static Color glass(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF1A1A2E).withOpacity(0.6)
        : Colors.white.withOpacity(0.65);
  }

  /// Glass card border
  static Color glassBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.8);
  }

  /// Glass card border with subtle accent tint
  static Color glassBorderAccent(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? accent.withOpacity(0.15)
        : accent.withOpacity(0.2);
  }

  /// Card background (solid, non-glass)
  static Color cardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkCard : white;
  }

  /// Elevated card background
  static Color cardBgElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkElevated : white;
  }

  /// Page background
  static Color pageBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBg : beigeLight;
  }

  /// Surface (slightly lighter than page)
  static Color surface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : white;
  }

  /// Primary text
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkText : navyDarkest;
  }

  /// Secondary text
  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSubtext : grey500;
  }

  /// Tertiary / hint text
  static Color textHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkHint : grey500;
  }

  /// Border color
  static Color border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBorder : grey200;
  }

  /// Strong border color
  static Color borderStrong(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBorderHigh : grey300;
  }

  /// Shimmer base
  static Color shimmerBaseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkShimmerBase : shimmerBase;
  }

  /// Shimmer highlight
  static Color shimmerHighColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkShimmerHigh : shimmerHigh;
  }

  /// Post type background (for badges, chips)
  static Color postTypeBg(BuildContext context, bool isLost) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLost) return isDark ? darkLostBg : lostAlertBg;
    return isDark ? darkFoundBg : foundBg;
  }
}

/// ─── Post Type Utilities ─────────────────────────────────────────────────────
enum PostType { lost, found, returned }

extension PostTypeX on PostType {
  Color get color {
    switch (this) {
      case PostType.lost:     return AppColors.lostAlert;
      case PostType.found:    return AppColors.foundSuccess;
      case PostType.returned: return AppColors.navyLight;
    }
  }

  Color get bgColor {
    switch (this) {
      case PostType.lost:     return AppColors.lostAlertBg;
      case PostType.found:    return AppColors.foundBg;
      case PostType.returned: return AppColors.grey100;
    }
  }

  String get label {
    switch (this) {
      case PostType.lost:     return 'Lost';
      case PostType.found:    return 'Found';
      case PostType.returned: return 'Returned';
    }
  }

  String get emoji {
    switch (this) {
      case PostType.lost:     return '🔴';
      case PostType.found:    return '🟢';
      case PostType.returned: return '✅';
    }
  }
}
