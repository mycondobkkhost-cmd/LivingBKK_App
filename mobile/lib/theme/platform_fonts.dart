import 'package:flutter/material.dart';

/// ฟอนต์หลักทั้งแอป — IBM Plex Sans Thai (bundled, ใกล้ Shopee / UI e-commerce ไทย)
abstract final class AppFonts {
  static const family = 'IBMPlexSansThai';

  static TextStyle text({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    bool display = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextTheme textTheme({bool displayHeadlines = false}) {
    TextStyle role({
      required double size,
      FontWeight weight = FontWeight.w400,
      double? height,
      double? letterSpacing,
    }) =>
        text(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: letterSpacing,
          display: displayHeadlines && size >= 24,
        );

    return TextTheme(
      displayLarge: role(size: 32, weight: FontWeight.w700, height: 1.15, letterSpacing: -0.5),
      displayMedium: role(size: 28, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.4),
      headlineLarge: role(size: 24, weight: FontWeight.w700, height: 1.25),
      headlineMedium: role(size: 20, weight: FontWeight.w600, height: 1.3),
      titleLarge: role(size: 18, weight: FontWeight.w600),
      titleMedium: role(size: 16, weight: FontWeight.w600),
      bodyLarge: role(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyMedium: role(size: 14, weight: FontWeight.w400, height: 1.45),
      bodySmall: role(size: 12, weight: FontWeight.w400, height: 1.4),
      labelLarge: role(size: 14, weight: FontWeight.w600),
      labelMedium: role(size: 12, weight: FontWeight.w600),
    );
  }
}
