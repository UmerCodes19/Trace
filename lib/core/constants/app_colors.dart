// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── The Luxury "Deep Jade" Palette ──────────────────────────────────────────
  // A unique, sophisticated identity that avoids "AI-typical" purples/blues.
  static const Color deepJade = Color(0xFF004D40); // Deep, rich green
  static const Color jadePrimary = Color(0xFF00796B); // Main brand color
  static const Color sageSecondary = Color(0xFF80CBC4); // Softer accent
  static const Color amberAccent = Color(0xFFFFA000); // Functional warm accent
  
  static const Color ink = Color(0xFF0F172A);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color ghost = Color(0xFFF8FAFC);
  static const Color slate = Color(0xFF64748B);
  
  static const Color darkBg = Color(0xFF050B0A); // Very deep forest black
  static const Color darkCard = Color(0xFF0D1615);
  static const Color darkBorder = Color(0xFF1B2B28);

  // ─── Semantic Aliases (Restored for Compatibility) ──────────────────────────
  static const Color navyDarkest = deepJade;
  static const Color navyMid = jadePrimary;
  static const Color navyLight = sageSecondary;
  static const Color beigeWarm = Color(0xFFF5F5F0);
  static const Color white = Colors.white;
  static const Color grey700 = Color(0xFF334155);
  
  static const Color lostAlert = Color(0xFFE53935); // Clean red
  static const Color lostAlertBg = Color(0xFFFFF1F0);
  static const Color foundSuccess = jadePrimary;
  static const Color foundBg = Color(0xFFE0F2F1);
  static const Color defaultAccent = jadePrimary;
  static const Color darkElevated = Color(0xFF14201E);

  // ─── Theme-Aware Helpers ──────────────────────────────────────────────────
  static Color pageBg(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkBg : ghost;

  static Color card(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkCard : Colors.white;

  static Color cardBg(BuildContext context) => card(context);

  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0D1615) : const Color(0xFFF0F4F4);

  static Color textPrimary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? Colors.white : deepJade;

  static Color textSecondary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? sageSecondary : const Color(0xFF455A64);

  static Color textHint(BuildContext context) => textSecondary(context);

  static Color border(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkBorder : const Color(0xFFCFD8DC);

  // Shimmer
  static Color shimmerBaseColor(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF14201E) : const Color(0xFFE0F2F1);
  
  static Color shimmerHighColor(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B2B28) : Colors.white;

  static Color shimmerBase(BuildContext context) => shimmerBaseColor(context);
  static Color shimmerHighlight(BuildContext context) => shimmerHighColor(context);

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color lost = lostAlert;
  static const Color found = foundSuccess;

  // ─── Accent Presets (Updated to Brand Identity) ─────────────────────────────
  static const List<Color> accentPresets = [jadePrimary, deepJade, Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)];
  static const List<String> accentPresetNames = ['Jade', 'Deep Forest', 'Teal', 'Emerald', 'Mint'];
}
