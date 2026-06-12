import 'package:flutter/material.dart';

/// Breakpoints จาก template abuanwar072 (850 / 1100)
abstract final class AdminTemplateResponsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 850;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 850 && w < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;
}
