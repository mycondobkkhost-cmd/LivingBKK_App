import 'package:flutter/material.dart';

/// Semantic color tokens — Light (Canva-style) & Dark (PROPPITER)
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.border,
    required this.divider,
    required this.inputFill,
    required this.success,
    required this.warning,
    required this.error,
    required this.onPrimary,
    required this.cardShadow,
    required this.navShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color border;
  final Color divider;
  final Color inputFill;
  final Color success;
  final Color warning;
  final Color error;
  final Color onPrimary;
  final Color cardShadow;
  final Color navShadow;

  static const light = AppPalette(
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3F4F6),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1B41),
    textSecondary: Color(0xFF6B7280),
    primary: Color(0xFF4E2A84),
    primaryLight: Color(0xFFF3E8FF),
    accent: Color(0xFFFF6B00),
    border: Color(0xFFE5E7EB),
    divider: Color(0xFFE5E7EB),
    inputFill: Color(0xFFFFFFFF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    onPrimary: Colors.white,
    cardShadow: Color(0x0F1A1B41),
    navShadow: Color(0x0A000000),
  );

  static const dark = AppPalette(
    background: Color(0xFF0E0C18),
    surface: Color(0xFF16142A),
    surfaceVariant: Color(0xFF221E3C),
    surfaceElevated: Color(0xFF221E3C),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFB8B2D4),
    primary: Color(0xFF7B5CE8),
    primaryLight: Color(0xFF352A6B),
    accent: Color(0xFFFF6B9D),
    border: Color(0xFF2E2948),
    divider: Color(0x14FFFFFF),
    inputFill: Color(0xFF221E3C),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFD54F),
    error: Color(0xFFFF5252),
    onPrimary: Colors.white,
    cardShadow: Color(0x339B6DFF),
    navShadow: Color(0x40000000),
  );

  /// Legacy aliases used across the codebase
  Color get surfaceWarm => background;
  Color get backgroundAlt => surfaceVariant;
  Color get cardTint => surface;
  Color get headerTint => surface;
  Color get navTint => surface;
  Color get cta => accent;
  Color get accentMid => primary;
  Color get accentMidLight => primaryLight;
  Color get accentSoft => primary;
  Color get accentSoftLight => primaryLight;
  Color get accentDeep => primary;
  Color get accentDeepLight => primaryLight;
  Color get accentMuted => textSecondary;
  Color get accentMutedLight => surfaceVariant;
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPaletteTheme>()?.palette ?? AppPalette.dark;
}

/// ThemeExtension wrapper for [AppPalette]
class AppPaletteTheme extends ThemeExtension<AppPaletteTheme> {
  const AppPaletteTheme({required this.palette});

  final AppPalette palette;

  @override
  AppPaletteTheme copyWith({AppPalette? palette}) =>
      AppPaletteTheme(palette: palette ?? this.palette);

  @override
  AppPaletteTheme lerp(AppPaletteTheme? other, double t) => this;
}
