import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/living_bkk_brand.dart';

/// โทนหลังบ้าน RealXtate — sidebar มืด + content อ่อน แบบแดชบอร์ดสะอาด
abstract final class AdminTemplateTheme {
  static const Color primaryColor = LivingBkkBrand.brandRed;
  static const Color accentColor = LivingBkkBrand.accentOrange;
  static const Color secondaryColor = Color(0xFF2A2D3E);
  static const Color sidebarBg = Color(0xFF1F2430);
  static const Color contentBg = Color(0xFFF5F6FA);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E2430);
  static const Color textMuted = Color(0xFF6B7280);

  static const double sidebarWidth = 256;
  static const double defaultPadding = 16;
  static const double cardRadius = 16;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle menuLabel({required bool selected, bool section = false}) {
    if (section) {
      return GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.8,
      );
    }
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected ? Colors.white : Colors.white60,
      height: 1.15,
    );
  }

  static TextStyle menuSubtitle({required bool selected}) => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: selected ? Colors.white70 : Colors.white38,
        height: 1.2,
      );

  static TextStyle pageTitle(BuildContext context) => GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: textPrimary,
        height: 1.15,
      );

  static TextStyle pageSubtitle() => GoogleFonts.poppins(
        fontSize: 12,
        color: textMuted,
        height: 1.3,
      );
}
