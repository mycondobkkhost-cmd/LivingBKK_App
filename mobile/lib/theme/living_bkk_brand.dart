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

  static const Color loginSubSloganColor = brandRedLight;

  static String loginSubSloganLine(Locale locale) =>
      locale.languageCode == 'th' ? loginSubSloganLineTh : loginSubSloganLineEn;

  static String loginMainSlogan(Locale locale) =>
      locale.languageCode == 'th' ? loginMainSloganTh : loginMainSloganEn;

  // ── RealXtate red palette (mock 2026 — สีอย่างเดียว) ──
  static const Color brandRed = Color(0xFFEE4D2D);
  static const Color brandRedDark = Color(0xFFD73211);
  static const Color brandRedMid = Color(0xFFE83822);
  static const Color brandRedLight = Color(0xFFFF6B4A);
  static const Color brandRedTint = Color(0xFFFFF0EB);

  /// ปุ่มบริการหน้าแรก (mock)
  static const Color servicePurple = Color(0xFF8A59D1);
  static const Color serviceGreen = Color(0xFF47B38D);
  static const Color serviceYellow = Color(0xFFF7D154);

  static const Color propPurple = brandRed;
  static const Color piterOrange = Color(0xFFF58220);
  static const Color accentYellow = serviceYellow;
  static const Color accentOrange = Color(0xFFF58220);
  static const Color propNavy = Color(0xFF333333);
  static const Color piterPink = brandRed;
  static const Color pageBackground = Color(0xFFF0F2F5);

  static const Color robinhoodPurple = brandRed;
  static const Color robinhoodPurpleDark = brandRedDark;
  static const Color robinhoodPurpleMid = brandRedMid;
  static const Color robinhoodPurpleLight = brandRedTint;

  // ── RealXtate palette (brand brief 2026) ──
  static const Color purplePrimary = propNavy;
  static const Color purpleLight = brandRedLight;
  static const Color purpleMid = brandRedMid;
  static const Color pink = brandRed;
  static const Color navy = propNavy;
  static const Color offWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color sidebarTint = Color(0xFFFFFAF8);

  static const Map<String, String> colorTokens = {
    'primary_red': '#EE4D2D',
    'primary_red_dark': '#D73211',
    'orange_cta': '#F58220',
    'service_purple': '#8A59D1',
    'service_green': '#47B38D',
    'service_yellow': '#F7D154',
    'navy': '#333333',
    'off_white': '#F5F5F5',
  };

  /// Header — solid red (mock)
  static const Color headerGradientStart = brandRed;
  static const Color headerGradientEnd = brandRedDark;

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
    colors: [brandRed, brandRedLight, accentYellow, accentOrange],
    stops: [0.0, 0.4, 0.72, 1.0],
  );

  static const LinearGradient robinhoodHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandRed, brandRedMid, accentOrange],
    stops: [0.0, 0.55, 1.0],
  );

  /// บล็อก header หน้าแรก — แดง → ส้มอุ่น (depth ไม่ flat)
  static const Color homeHeaderBlockColor = brandRed;

  static const LinearGradient homeHeaderBlockGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      brandRedLight,
      brandRed,
      brandRedMid,
      brandRedDark,
      Color(0xFFC42A0E),
    ],
    stops: [0.0, 0.28, 0.55, 0.82, 1.0],
  );

  /// หัวแดง dark
  static const LinearGradient homeHeaderBlockGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A2410),
      Color(0xFFB52E18),
      brandRedDark,
      brandRed,
      accentOrange,
    ],
    stops: [0.0, 0.28, 0.55, 0.82, 1.0],
  );

  /// หน้าแรก — red → warm wash → page background
  static const LinearGradient homeHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      brandRed,
      brandRedMid,
      brandRedLight,
      brandRedTint,
      pageBackground,
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.22, 0.42, 0.62, 0.88, 1.0],
  );

  /// หน้าแรก dark — red → darkBg
  static const LinearGradient homeHeaderGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8A2410),
      brandRedDark,
      brandRed,
      Color(0xFF3D2018),
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
    colors: [brandRed, brandRedLight, accentOrange],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// เงาอุ่นใต้การ์ด/แคปซูลค้นหา — ไม่ใช้ม่วง
  static List<BoxShadow> warmCardShadow({double opacity = 0.10}) => [
        BoxShadow(
          color: Color.fromRGBO(215, 50, 17, opacity),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, opacity * 0.45),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

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
    colors: [brandRedTint, Color(0xFFFFFFFF)],
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
