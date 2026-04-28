import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({Color accent = AppColors.defaultAccent}) =>
      _buildLightTheme(accent);
  static ThemeData dark({Color accent = AppColors.defaultAccent}) =>
      _buildDarkTheme(accent);

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData _buildLightTheme(Color accent) {
    final accentDark = HSLColor.fromColor(accent)
        .withLightness(0.35)
        .withSaturation(0.7)
        .toColor();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: accentDark,
        onPrimary: AppColors.white,
        secondary: AppColors.lostAlert,
        onSecondary: AppColors.white,
        tertiary: AppColors.foundSuccess,
        onTertiary: AppColors.white,
        error: const Color(0xFFD32F2F),
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.navyDarkest,
        outline: AppColors.grey300,
        surfaceContainerHighest: AppColors.grey100,
        onSurfaceVariant: AppColors.grey700,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.beigeLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.navyDarkest, size: 24),
        titleTextStyle: _headingStyle(18, AppColors.navyDarkest),
      ),
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.grey200, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _bodyStyle(14, AppColors.grey500),
        labelStyle: _bodyStyle(14, AppColors.grey700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDarkest,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: _headingStyle(15, AppColors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyDarkest,
          side: const BorderSide(color: AppColors.navyLight, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: _headingStyle(15, AppColors.navyDarkest),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentDark,
          textStyle: _headingStyle(14, accentDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.grey300,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: accentDark,
        labelStyle: _bodyStyle(12, AppColors.grey700),
        side: const BorderSide(color: AppColors.grey200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 0.8,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyDarkest,
        contentTextStyle: _bodyStyle(14, AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: _headingStyle(18, AppColors.navyDarkest),
        contentTextStyle: _bodyStyle(14, AppColors.grey700),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return AppColors.grey300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withOpacity(0.3);
          }
          return AppColors.grey200;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: accent.withOpacity(0.15),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navyDarkest,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _bodyStyle(12, AppColors.white),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.3),
        selectionHandleColor: accent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _bodyStyle(14, AppColors.navyDarkest),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }


  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData _buildDarkTheme(Color accent) {
    final accentLight = HSLColor.fromColor(accent)
        .withLightness(0.65)
        .withSaturation(0.8)
        .toColor();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: accent,
        onPrimary: Colors.white,
        secondary: AppColors.lostAlert,
        onSecondary: Colors.white,
        tertiary: AppColors.foundSuccess,
        onTertiary: Colors.white,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        outline: AppColors.darkBorderHigh,
        surfaceContainerHighest: AppColors.darkElevated,
        onSurfaceVariant: AppColors.darkSubtext,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: _headingStyle(18, AppColors.darkText),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _bodyStyle(14, AppColors.darkHint),
        labelStyle: _bodyStyle(14, AppColors.darkSubtext),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: _headingStyle(15, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentLight,
          side: BorderSide(color: accent.withOpacity(0.5), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: _headingStyle(15, accentLight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: _headingStyle(14, accent),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkHint,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkElevated,
        selectedColor: accent,
        labelStyle: _bodyStyle(12, AppColors.darkSubtext),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.8,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevated,
        contentTextStyle: _bodyStyle(14, AppColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: _headingStyle(18, AppColors.darkText),
        contentTextStyle: _bodyStyle(14, AppColors.darkSubtext),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return AppColors.darkHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withOpacity(0.3);
          }
          return AppColors.darkBorder;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: accent.withOpacity(0.15),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _bodyStyle(12, AppColors.darkText),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.3),
        selectionHandleColor: accent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _bodyStyle(14, AppColors.darkText),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }


  // ─── Typography ───────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor =
        brightness == Brightness.light ? AppColors.navyDarkest : AppColors.darkText;
    final subtextColor =
        brightness == Brightness.light ? AppColors.grey700 : AppColors.darkSubtext;
    final lightColor =
        brightness == Brightness.light ? AppColors.grey500 : AppColors.darkHint;

    return TextTheme(
      displayLarge: _headingStyle(57, textColor),
      displayMedium: _headingStyle(45, textColor),
      displaySmall: _headingStyle(36, textColor),
      headlineLarge: _headingStyle(32, textColor),
      headlineMedium: _headingStyle(28, textColor),
      headlineSmall: _headingStyle(24, textColor),
      titleLarge: _headingStyle(22, textColor),
      titleMedium: _headingStyle(16, textColor),
      titleSmall: _headingStyle(14, textColor),
      bodyLarge: _bodyStyle(16, textColor),
      bodyMedium: _bodyStyle(14, subtextColor),
      bodySmall: _bodyStyle(12, lightColor),
      labelLarge: _headingStyle(14, textColor),
      labelMedium: _bodyStyle(12, subtextColor),
      labelSmall: _bodyStyle(11, lightColor),
    );
  }

  static TextStyle _headingStyle(double size, Color color) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle _bodyStyle(double size, Color color) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
      );
}