import 'package:flutter/material.dart';

/// PROPPITER — official brand identity (rebrand 2026)
class LivingBkkBrand {
  LivingBkkBrand._();

  static const String name = 'PROPPITER';
  static const String nameTh = 'PROPPITER';
  static const String nameEn = 'PROPPITER';

  /// สโลแกนแอป (คงเดิม — ไม่ใช่ tagline บนโลโก้ FIND. LIVE. INVEST.)
  /// สโลแกนรองใต้โลโก้ (ตาม brand guide)
  static const String taglineTh =
      'โพสต์ฟรี • ปิดดีลไว • ไม่ต้องหาลูกค้าเอง';
  static const String taglineEn =
      'Post for free • Close deals faster • No chasing clients yourself';

  static const String loginMainSloganTh = 'แอปอสังหาที่ครบเครื่องที่สุดในไทย';
  static const String loginMainSloganEn =
      "Thailand's most complete property app";

  static const String loginSubSloganLineTh =
      'ครบทุกดีลอสังหา · ลงประกาศฟรี · อัปเดตสถานะตลอดเวลา';
  static const String loginSubSloganLineEn =
      'All deals in one place · Free listing · Real-time updates';

  static const Color loginSubSloganColor = Color(0xFFE84393);

  static String loginSubSloganLine(Locale locale) =>
      locale.languageCode == 'th' ? loginSubSloganLineTh : loginSubSloganLineEn;

  static String loginMainSlogan(Locale locale) =>
      locale.languageCode == 'th' ? loginMainSloganTh : loginMainSloganEn;

  /// กำกับใต้ชื่อแบรนด์ (แยกจากสโลแกน)
  static const String descriptorEn = 'Real Estate Agent Platform';

  // ── PROPPITER palette (brand brief 2026) ──
  static const Color purplePrimary = Color(0xFF583AD6);
  static const Color purpleLight = Color(0xFF9B6DFF);
  static const Color purpleMid = Color(0xFF7B5CE8);
  static const Color pink = Color(0xFFDB3D76);
  static const Color navy = Color(0xFF18104B);
  static const Color offWhite = Color(0xFFF9F9FB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color sidebarTint = Color(0xFFFAF9FF);

  static const Map<String, String> colorTokens = {
    'purple': '#583AD6',
    'purple_light': '#9B6DFF',
    'pink': '#DB3D76',
    'navy': '#18104B',
    'off_white': '#F9F9FB',
  };

  /// Canva-style hero gradient (cyan → lavender) — home / auth light surfaces
  static const Color headerGradientStart = Color(0xFFECF5FC);
  static const Color headerGradientEnd = Color(0xFFE3E3FD);

  // ── Dark UI surfaces (PROPPITER brief) ──
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
  static const Color adminBg = Color(0xFF141428);

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5634E3), purpleLight, pink],
    stops: [0.0, 0.55, 1.0],
  );

  /// Light hero — โทนเดียวกับ Canva AI home (ฟ้าอ่อน → ม่วงอ่อน)
  static const LinearGradient canvaHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd, offWhite],
    stops: [0.0, 0.45, 1.0],
  );

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
