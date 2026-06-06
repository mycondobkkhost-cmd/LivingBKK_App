/// Official LivingBKK brand image assets (cropped from livingbkk-brand-guide.png).
/// Regenerate: `python3 scripts/sync-brand-assets.py`
class BrandAssets {
  BrandAssets._();

  static const _base = 'assets/brand';

  static const brandGuide = '$_base/livingbkk-brand-guide.png';

  /// Icon + LivingBKK wordmark — light background
  static const logoLockupLight = '$_base/logo-lockup-light.png';
  static const logoLockupEnLight = '$_base/logo-lockup-en-light.png';

  /// Icon + LivingBKK wordmark — dark background (white Living)
  static const logoLockupDark = '$_base/logo-lockup-dark.png';
  static const logoLockupEnDark = '$_base/logo-lockup-en-dark.png';

  /// Default lockup (light)
  static const logoLockup = logoLockupLight;

  /// Icon + LivingBKK wordmark only (no taglines).
  static const logoLockupCompactLight = '$_base/logo-lockup-compact-light.png';
  static const logoLockupCompactDark = '$_base/logo-lockup-compact-dark.png';

  static const logoMark = '$_base/logo-mark.png';
  /// ตัว P ล้วน — หัวหน้าแอป (ไม่มีวงกลม / ไม่มี wordmark)
  static const proppiterMarkP = '$_base/proppiter-mark-p.png';
  /// P + PROPPITER — lockup หัวหน้าแอป (พื้นโปร่งใส)
  static const proppiterHeaderLockup = '$_base/proppiter-header-lockup.png';
  static const logoStacked = '$_base/logo-stacked.png';
  static const logoStackedVertical = '$_base/logo-stacked-vertical.png';

  static const appIconWhite = '$_base/app-icon-white.png';
  static const appIconLavender = '$_base/app-icon-lavender.png';
  static const appIconNavy = '$_base/app-icon-navy.png';
  static const appIconGradient = '$_base/app-icon-gradient.png';
  static const appIconOutline = '$_base/app-icon-outline.png';
  static const favicon256 = '$_base/favicon-256.png';
}
