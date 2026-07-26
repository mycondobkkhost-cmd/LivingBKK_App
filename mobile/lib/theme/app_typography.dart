import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Centralized Prompt typography scale
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(AppPalette p) {
    final base = GoogleFonts.promptTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.prompt(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: p.textPrimary,
      ),
      displayMedium: GoogleFonts.prompt(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: p.textPrimary,
      ),
      headlineLarge: GoogleFonts.prompt(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: p.textPrimary,
      ),
      headlineMedium: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: p.textPrimary,
      ),
      titleLarge: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      titleMedium: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      bodyLarge: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: p.textPrimary,
      ),
      bodyMedium: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: p.textPrimary,
      ),
      bodySmall: GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: p.textSecondary,
      ),
      labelLarge: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      labelMedium: GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
      ),
    );
  }

  static TextStyle heroHeadline(AppPalette p, {bool highlightAccent = true}) {
    return GoogleFonts.prompt(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: p.textPrimary,
    );
  }

  static TextStyle price(AppPalette p) => GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: p.primary,
        height: 1.1,
      );

  static TextStyle caption(AppPalette p) => GoogleFonts.prompt(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      );
}

/// Typography สำหรับการ์ด spotlight / ลิสติ้งเต็มความกว้าง
abstract final class HomeTypography {
  static TextStyle listingTitleStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: p.textPrimary,
      );

  static TextStyle locationLineStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: p.textSecondary,
      );

  static TextStyle specChipStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: p.textPrimary,
      );

  static TextStyle priceStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: p.primary,
      );

  static TextStyle priceStrikeStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.1,
        color: p.textSecondary,
        decoration: TextDecoration.lineThrough,
      );

  static TextStyle perMonthStyle(AppPalette p) => GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: p.textSecondary,
      );

  static TextStyle metaStyle(AppPalette p, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.prompt(
        fontSize: 11,
        fontWeight: weight,
        height: 1.2,
        color: p.textSecondary,
      );
}
