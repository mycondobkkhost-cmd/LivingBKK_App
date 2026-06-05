import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_theme.dart';

/// Layout tokens — v2 design system
abstract final class LiLayout {
  static const double pagePadding = 16;
  static const double headerHeight = 52;
  static const double searchHeight = 48;
  static const double txnTabHeight = 40;
  static const double feedImageAspect = 16 / 9;

  static Color get searchFill => AppTheme.inputFill;
  static Color get tabInactiveBg => AppTheme.backgroundAlt;
  static Color get divider => AppTheme.divider;

  static BoxDecoration searchBarDecorationFor(AppPalette p) => BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get cardDecoration => AppTheme.cardDecoration();

  static BoxDecoration get searchBarDecoration => searchBarDecorationFor(AppPalette.light);

  static BoxDecoration get categoryCircleDecoration => BoxDecoration(
        color: AppTheme.primaryLight,
        shape: BoxShape.circle,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get priceOnCard => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary,
        height: 1.1,
      );
}
