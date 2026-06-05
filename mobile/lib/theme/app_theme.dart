import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'app_typography.dart';

/// PROPPITER theme — Canva-style light UI + brand palette
class AppTheme {
  AppTheme._();

  static AppPalette _active = AppPalette.dark;

  // ── Layout tokens ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 28;
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);

  // ── Runtime colors (synced via [AppThemeBridge]) ──
  static Color primary = AppPalette.dark.primary;
  static Color primaryHover = AppPalette.dark.primary;
  static Color primaryDark = AppPalette.dark.primary;
  static Color primaryLight = AppPalette.dark.primaryLight;
  static Color cta = AppPalette.dark.accent;
  static Color ctaDark = AppPalette.dark.accent;
  static Color accentDeep = AppPalette.dark.primary;
  static Color accentDeepLight = AppPalette.dark.primaryLight;
  static Color accentMid = AppPalette.dark.primary;
  static Color accentMidLight = AppPalette.dark.primaryLight;
  static Color accentSoft = AppPalette.dark.primary;
  static Color accentSoftLight = AppPalette.dark.primaryLight;
  static Color accentMuted = AppPalette.dark.textSecondary;
  static Color accentMutedLight = AppPalette.dark.surfaceVariant;
  static Color success = AppPalette.dark.success;
  static Color successLight = AppPalette.dark.surfaceVariant;
  static Color warning = AppPalette.dark.warning;
  static Color warningLight = AppPalette.dark.surfaceVariant;
  static Color live = AppPalette.dark.error;
  static Color accentTeal = AppPalette.dark.primary;
  static Color accentTealLight = AppPalette.dark.primaryLight;
  static Color accentAmber = AppPalette.dark.warning;
  static Color accentAmberLight = AppPalette.dark.surfaceVariant;
  static Color accentSky = AppPalette.dark.primary;
  static Color accentSkyLight = AppPalette.dark.primaryLight;
  static Color accentRose = AppPalette.dark.accent;
  static Color accentRoseLight = AppPalette.dark.surfaceVariant;
  static Color surfaceWarm = AppPalette.dark.background;
  static Color backgroundAlt = AppPalette.dark.surfaceVariant;
  static Color headerTint = AppPalette.dark.surface;
  static Color cardTint = AppPalette.dark.surface;
  static Color navTint = AppPalette.dark.surface;
  static Color inputFill = AppPalette.dark.inputFill;
  static Color surfaceElevated = AppPalette.dark.surfaceElevated;
  static Color textPrimary = AppPalette.dark.textPrimary;
  static Color textSecondary = AppPalette.dark.textSecondary;
  static Color border = AppPalette.dark.border;
  static Color divider = AppPalette.dark.divider;
  static Color error = AppPalette.dark.error;

  static void syncPalette(Brightness brightness) {
    _active = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
    final p = _active;
    primary = p.primary;
    primaryHover = p.primary;
    primaryDark = p.primary;
    primaryLight = p.primaryLight;
    cta = p.accent;
    ctaDark = p.accent;
    accentDeep = p.primary;
    accentDeepLight = p.primaryLight;
    accentMid = p.primary;
    accentMidLight = p.primaryLight;
    accentSoft = p.primary;
    accentSoftLight = p.primaryLight;
    accentMuted = p.textSecondary;
    accentMutedLight = p.surfaceVariant;
    success = p.success;
    successLight = p.surfaceVariant;
    warning = p.warning;
    warningLight = p.surfaceVariant;
    live = p.error;
    accentTeal = p.primary;
    accentTealLight = p.primaryLight;
    accentAmber = p.warning;
    accentAmberLight = p.surfaceVariant;
    accentSky = p.primary;
    accentSkyLight = p.primaryLight;
    accentRose = p.accent;
    accentRoseLight = p.surfaceVariant;
    surfaceWarm = p.background;
    backgroundAlt = p.surfaceVariant;
    headerTint = p.surface;
    cardTint = p.surface;
    navTint = p.surface;
    inputFill = p.inputFill;
    surfaceElevated = p.surfaceElevated;
    textPrimary = p.textPrimary;
    textSecondary = p.textSecondary;
    border = p.border;
    divider = p.divider;
    error = p.error;
  }

  static List<Color> get sectionAccents => [
        primary,
        cta,
        accentDeep,
        accentSoft,
        warning,
      ];

  static Color sectionAccentLight(int index) {
    final lights = [primaryLight, accentRoseLight, accentDeepLight, accentSoftLight, successLight];
    return lights[index % lights.length];
  }

  static BoxShadow cardShadowFor(AppPalette p) => BoxShadow(
        color: p.cardShadow,
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  static BoxShadow get cardShadow => cardShadowFor(_active);

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? cardTint,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: border.withOpacity(0.55)),
        boxShadow: [cardShadow],
      );

  static ButtonStyle pillFilledFor(AppPalette p) => FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onPrimary,
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        textStyle: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 15),
      );

  static ButtonStyle pillPrimaryFor(AppPalette p) => FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        textStyle: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 15),
      );

  static ButtonStyle get pillFilled => pillFilledFor(_active);
  static ButtonStyle get pillPrimary => pillPrimaryFor(_active);

  static ButtonStyle pillOutlinedFor(AppPalette p) => OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primary, width: 1.5),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
      );

  static ButtonStyle get pillOutlined => pillOutlinedFor(_active);

  static ThemeData get theme => lightTheme;
  static ThemeData get light => lightTheme;

  static ThemeData get lightTheme => _build(AppPalette.light);
  static ThemeData get darkTheme => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isLight = p == AppPalette.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.accent,
        onSecondary: p.onPrimary,
        error: p.error,
        onError: p.onPrimary,
        surface: p.surface,
        onSurface: p.textPrimary,
        background: p.background,
        onBackground: p.textPrimary,
      ),
      scaffoldBackgroundColor: p.background,
      extensions: [AppPaletteTheme(palette: p)],
    );

    final textTheme = AppTypography.textTheme(p);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.prompt(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        iconTheme: IconThemeData(color: p.textPrimary, size: 22),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceVariant,
        selectedColor: p.primaryLight,
        labelStyle: GoogleFonts.prompt(color: p.textPrimary, fontSize: 13),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(style: pillFilledFor(p)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: pillOutlinedFor(p)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: p.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: p.border.withOpacity(0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        hintStyle: GoogleFonts.prompt(color: p.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.prompt(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surfaceElevated,
        contentTextStyle: GoogleFonts.prompt(color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.textPrimary,
        tileColor: p.surface,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return p.accent;
          return null;
        }),
        checkColor: MaterialStateProperty.all(p.onPrimary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      iconTheme: IconThemeData(color: p.textPrimary),
    );
  }
}

/// Syncs [AppTheme] runtime colors with current [ThemeData] brightness
class AppThemeBridge extends StatelessWidget {
  const AppThemeBridge({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    AppTheme.syncPalette(Theme.of(context).brightness);
    return child ?? const SizedBox.shrink();
  }
}
