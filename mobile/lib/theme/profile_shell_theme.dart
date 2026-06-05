import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Profile page + bottom nav — follows active [AppPalette] (light / dark / system).
class ProfileShellTheme {
  ProfileShellTheme._();

  static const double horizontalPadding = 24;
  static const double listIconSize = 22;

  static AppPalette palette(BuildContext context) => context.palette;

  static Color background(BuildContext context) => palette(context).background;

  static Color surface(BuildContext context) => palette(context).surface;

  static Color accent(BuildContext context) => palette(context).primary;

  static Color textPrimary(BuildContext context) => palette(context).textPrimary;

  static Color textSecondary(BuildContext context) =>
      palette(context).textSecondary;

  static Color divider(BuildContext context) => palette(context).divider;

  static Color badgeBackground(BuildContext context) =>
      palette(context).surfaceVariant;

  static Color inactiveNav(BuildContext context) =>
      palette(context).textSecondary.withOpacity(0.65);
}
