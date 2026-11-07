import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Light and dark [ThemeData] used by the application.
///
/// The dark theme is the primary experience (matching Sportzfy), while the
/// light theme keeps the same teal branding with brighter surfaces.
abstract final class AppTheme {
  static const String _fontFallback = 'Noto Sans Bengali';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: isDark ? AppColors.teal : AppColors.tealDark,
      onPrimary: isDark ? AppColors.onBrand : AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary,
      surfaceContainerHighest: isDark
          ? AppColors.darkElevated
          : const Color(0xFFEDF3F1),
      onSurfaceVariant: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
      outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      error: AppColors.live,
    );

    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final hintColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      fontFamilyFallback: const [_fontFallback, 'Hind Siliguri', 'sans-serif'],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        shape: Border(bottom: BorderSide(color: borderColor)),
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.teal : AppColors.tealDeep,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: hintColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark ? AppColors.darkElevated : const Color(0xFFEDF3F1),
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: hintColor,
        suffixIconColor: hintColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.live),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.onBrand,
          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.onBrand.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.onBrand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.tealSoft : AppColors.tealDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.tealSoft : AppColors.tealDark,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.white,
        selectedColor: AppColors.teal,
        disabledColor: isDark ? AppColors.darkCard : AppColors.lightBorder,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onBrand,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.teal,
        inactiveTrackColor: Colors.white24,
        thumbColor: AppColors.teal,
        overlayColor: AppColors.teal.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
        linearTrackColor: AppColors.tealSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkElevated
            : AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.teal,
        selectionColor: Color(0x5500BFA5),
        selectionHandleColor: AppColors.teal,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightBorder),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal.withValues(alpha: 0.45)
              : borderColor,
        ),
      ),
    );
  }
}
