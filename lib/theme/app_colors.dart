import 'package:flutter/material.dart';

/// Central colour palette for the app.
///
/// The cyan brand colour, warm orange accent and near-black surfaces mirror the
/// Sportzfy identity, while the light theme keeps the same accents on brighter
/// surfaces.
abstract final class AppColors {
  // Brand — Sportzfy cyan
  static const Color teal = Color(0xFF00E5F5);
  static const Color tealDark = Color(0xFF00A9C6);
  static const Color tealDeep = Color(0xFF006B7A);
  static const Color tealSoft = Color(0xFF7CF7FF);

  /// Sportzfy's warm secondary accent.
  static const Color accent = Color(0xFFFF7A00);
  static const Color accentDeep = Color(0xFFE05E00);
  static const Color accentSoft = Color(0xFFFFB066);

  /// Text/icon colour that sits on top of the cyan brand colour.
  static const Color onBrand = Color(0xFF001014);

  // Dark theme — deep black with a blue tint.
  static const Color darkBackground = Color(0xFF07070C);
  static const Color darkSurface = Color(0xFF0D0D14);
  static const Color darkCard = Color(0xFF12121C);
  static const Color darkElevated = Color(0xFF1A1A26);
  static const Color darkBorder = Color(0xFF262635);
  static const Color darkTextPrimary = Color(0xFFF4F7F8);
  static const Color darkTextSecondary = Color(0xFF9BA6AD);

  // Light theme
  static const Color lightBackground = Color(0xFFF3F6F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E8EA);
  static const Color lightTextPrimary = Color(0xFF0B1418);
  static const Color lightTextSecondary = Color(0xFF5B6A70);

  // Status
  static const Color live = Color(0xFFFF3B30);
  static const Color liveDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFFB300);
  static const Color success = Color(0xFF25C46A);

  // Misc
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color overlay = Color(0xCC000000);

  /// Soft cyan glow used by elevated cards.
  static Color glow(Brightness brightness) => brightness == Brightness.dark
      ? teal.withValues(alpha: 0.16)
      : tealDark.withValues(alpha: 0.12);
}
