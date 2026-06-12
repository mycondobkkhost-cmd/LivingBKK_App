import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// โทนสีจาก [Flutter Responsive Admin Panel](https://github.com/abuanwar072/Flutter-Responsive-Admin-Panel-or-Dashboard)
abstract final class AdminTemplateTheme {
  static const Color primaryColor = Color(0xFF2697FF);
  static const Color secondaryColor = Color(0xFF2A2D3E);
  static const Color sidebarBg = Color(0xFF212332);
  static const Color contentBg = Color(0xFFF7F8FC);

  static const double sidebarWidth = 256;
  static const double defaultPadding = 16;

  static TextStyle menuLabel({required bool selected, bool section = false}) {
    if (section) {
      return GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.6,
      );
    }
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected ? Colors.white : Colors.white54,
    );
  }

  static TextStyle pageTitle(BuildContext context) =>
      GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: const Color(0xFF1E1E2E),
      );

  static TextStyle pageSubtitle() => GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF6B7280),
      );
}
