import 'package:flutter/material.dart';

/// RealXtate — official brand identity (rebrand 2026)
class LivingBkkBrand {
  LivingBkkBrand._();

  static const String name = 'RealXtate';
  static const String nameTh = 'RealXtate';
  static const String nameEn = 'RealXtate';

  /// กำกับใต้ชื่อแบรนด์ (แยกจากสโลแกน)
  static const String descriptorEn = 'Real Estate Matching Platform';

  /// สโลแกนบนโลโก้ / ใต้ชื่อ (brand brief final)
  static const String taglineTh =
      'ข้อมูลแม่นยำ • ลงประกาศฟรี • บริการครบวงจร';
  static const String taglineEn =
      'Verified listings • Free to post • Full-service support';

  static const String storeSubtitleTh = 'แมตช์ทรัพย์แม่นยำ โพสต์ฟรี';
  static const String storeSubtitleEn = 'Verified Property Matching';

  static const String loginMainSloganTh =
      'แพลตฟอร์มแมตช์อสังหาฯ ข้อมูลแม่นยำ โพสต์ฟรี';
  static const String loginMainSloganEn =
      'Verified property matching — list for free';

  static const String loginSubSloganLineTh = taglineTh;
  static const String loginSubSloganLineEn = taglineEn;

  static const Color loginSubSloganColor = Color(0xFFE84393);

  static String loginSubSloganLine(Locale locale) =>
      locale.languageCode == 'th' ? loginSubSloganLineTh : loginSubSloganLineEn;

  static String loginMainSlogan(Locale locale) =>
      locale.languageCode == 'th' ? loginMainSloganTh : loginMainSloganEn;

  // ── Robinhood TH–inspired palette (PROP purple · PITER orange/yellow) ──
  static const Color propPurple = Color(0xFF4E2A84);
  static const Color piterOrange = Color(0xFFFF6B00);
  static const Color accentYellow = Color(0xFFFFCB05);
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color propNavy = Color(0xFF1A1B41);
  static const Color piterPink = piterOrange;
  static const Color pageBackground = Color(0xFFF8F9FA);

  static const Color robinhoodPurple = propPurple;
  static const Color robinhoodPurpleDark = Color(0xFF3A1F66);
  static const Color robinhoodPurpleMid = Color(0xFF6B3FA0);
  static const Color robinhoodPurpleLight = Color(0xFFF3E8FF);

  // ── RealXtate palette (brand brief 2026) ──
  static const Color purplePrimary = propNavy;
  static const Color purpleLight = Color(0xFF9B6DFF);
  static const Color purpleMid = Color(0xFF7B5CE8);
  static const Color pink = piterPink;
  static const Color navy = propNavy;
  static const Color offWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color sidebarTint = Color(0xFFFAF9FF);

  static const Map<String, String> colorTokens = {
    'purple': '#4E2A84',
    'purple_light': '#9B6DFF',
    'yellow': '#FFCB05',
    'orange': '#FF6B00',
    'navy': '#1A1B41',
    'off_white': '#F8F9FA',
  };

  /// Robinhood header — solid purple
  static const Color headerGradientStart = robinhoodPurple;
  static const Color headerGradientEnd = robinhoodPurpleDark;

  // ── Dark UI surfaces (RealXtate brief) ──
  static const Color navyMid = Color(0xFF16142A);
  static const Color surface = Color(0xFF16142A);
  static const Color surfaceElevated = Color(0xFF221E3C);
  static const Color surfaceInput = Color(0xFF221E3C);
  static const Color darkBg = Color(0xFF0E0C18);

  static const Color purple = purpleLight;
  static const Color purpleDark = purplePrimary;
  static const Color purpleDeep = Color(0xFF4A2F99);
  static const Color purpleGlow = Color(0x409B6DFF);
  static const Color magenta = pink;
  static const Color magentaDark = Color(0xFFE04A78);
  static const Color lilac = Color(0xFF9E96BE);
  static const Color blush = navy;

  static const Color mint = Color(0xFF00E676);
  static const Color mintLight = Color(0xFF1B3D2F);
  static const Color gold = Color(0xFFFFD54F);
  static const Color live = Color(0xFFFF5252);
  static const Color peach = Color(0xFFFFB74D);
  static const Color peachLight = Color(0xFF3D3020);
  /// พื้นหลังศูนย์แอดมิน — โทนสว่าง (อ่านง่าย ไม่กลืนกับข้อความเทา)
  static const Color adminBg = offWhite;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [propPurple, purpleLight, accentYellow, accentOrange],
    stops: [0.0, 0.4, 0.72, 1.0],
  );

  static const LinearGradient robinhoodHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [robinhoodPurple, robinhoodPurpleMid, accentOrange],
    stops: [0.0, 0.55, 1.0],
  );

  /// บล็อก header หน้าแรก — ม่วงสว่าง ไล่เฉดนุ่ม (safe area → ค้นหา)
  static const Color homeHeaderBlockColor = Color(0xFF6E4EC4);

  static const LinearGradient homeHeaderBlockGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5E42B0),
      Color(0xFF7254C8),
      Color(0xFF9178E0),
      Color(0xFFA888F0),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
  );

  /// หัวม่วง dark — deep purple 4-stop (ไม่มีขาว)
  static const LinearGradient homeHeaderBlockGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A1548),
      Color(0xFF3A1F66),
      Color(0xFF4E2A84),
      Color(0xFF5E42B0),
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  /// หน้าแรก — deep purple → orange fade (Robinhood delivery feel)
  static const LinearGradient homeHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      robinhoodPurple,
      robinhoodPurpleMid,
      Color(0xFFB85CE8),
      accentOrange,
      pageBackground,
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.28, 0.48, 0.68, 0.9, 1.0],
  );

  /// หน้าแรก dark — purple → darkBg fade
  static const LinearGradient homeHeaderGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A1548),
      Color(0xFF3A1F66),
      Color(0xFF4E2A84),
      Color(0xFF352A6B),
      darkBg,
      darkBg,
    ],
    stops: [0.0, 0.28, 0.48, 0.68, 0.9, 1.0],
  );

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color pageBackgroundOf(BuildContext context) =>
      isLight(context) ? pageBackground : darkBg;

  static LinearGradient homeHeaderBlockGradientOf(BuildContext context) =>
      isLight(context) ? homeHeaderBlockGradient : homeHeaderBlockGradientDark;

  static LinearGradient homeHeaderGradientOf(BuildContext context) =>
      isLight(context) ? homeHeaderGradient : homeHeaderGradientDark;

  static LinearGradient promoGradientOf(BuildContext context) =>
      isLight(context) ? promoGradientLight : promoGradient;

  static const LinearGradient canvaHeroGradient = robinhoodHeaderGradient;

  static const LinearGradient loginSoftGradient = canvaHeroGradient;

  static const Color loginAccentPurple = purplePrimary;
  static const Color loginAccentPurpleSoft = purpleLight;

  static const Color loginAccentBlue = loginAccentPurple;
  static const Color loginAccentBlueSoft = loginAccentPurpleSoft;

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBg, navy, Color(0xFF1A1040)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [pink, purpleLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyMid, navy],
  );

  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy, navyMid],
  );

  static const Gradient authAccentOrb = RadialGradient(
    colors: [Color(0x559B6DFF), Color(0x00FF5B8A)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, navyMid],
  );

  static const LinearGradient promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2055), Color(0xFF3D2060)],
  );

  /// แถบลงประกาศบนหน้าแรก — light / Canva-style
  static const LinearGradient promoGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE9FE), Color(0xFFFFFFFF)],
  );

  static String tagline(Locale locale) =>
      locale.languageCode == 'th' ? taglineTh : taglineEn;
}

extension LivingBkkBrandContext on BuildContext {
  bool get isLightTheme => LivingBkkBrand.isLight(this);

  Color get brandPageBackground => LivingBkkBrand.pageBackgroundOf(this);

  LinearGradient get homeHeaderBlockGradient =>
      LivingBkkBrand.homeHeaderBlockGradientOf(this);

  LinearGradient get homeHeaderGradient =>
      LivingBkkBrand.homeHeaderGradientOf(this);

  LinearGradient get promoGradient => LivingBkkBrand.promoGradientOf(this);
}
