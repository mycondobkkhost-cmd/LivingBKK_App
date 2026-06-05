import '../theme/living_bkk_brand.dart';

/// Brand identity loaded from Supabase `app_brand_settings` (with local fallback).
class BrandSettings {
  const BrandSettings({
    required this.id,
    required this.name,
    required this.taglineEn,
    required this.taglineTh,
    this.logoMarkUrl,
    this.logoHorizontalUrl,
    this.logoWhiteUrl,
    this.faviconUrl,
    this.appIconUrl,
    this.brandGuideUrl,
    this.colors = const {},
    this.fontFamily = 'Prompt',
  });

  final String id;
  final String name;
  final String taglineEn;
  final String taglineTh;
  final String? logoMarkUrl;
  final String? logoHorizontalUrl;
  final String? logoWhiteUrl;
  final String? faviconUrl;
  final String? appIconUrl;
  final String? brandGuideUrl;
  final Map<String, String> colors;
  final String fontFamily;

  static BrandSettings defaults = BrandSettings(
    id: 'default',
    name: LivingBkkBrand.name,
    taglineEn: LivingBkkBrand.taglineEn,
    taglineTh: LivingBkkBrand.taglineTh,
    brandGuideUrl: 'assets/brand/livingbkk-brand-guide.png',
    colors: LivingBkkBrand.colorTokens,
  );

  factory BrandSettings.fromJson(Map<String, dynamic> json) {
    final rawColors = json['colors'];
    final colors = <String, String>{};
    if (rawColors is Map) {
      rawColors.forEach((k, v) {
        if (v != null) colors[k.toString()] = v.toString();
      });
    }

    final typo = json['typography'];
    var fontFamily = 'Prompt';
    if (typo is Map && typo['font_family'] != null) {
      fontFamily = typo['font_family'].toString();
    }

    return BrandSettings(
      id: json['id'] as String? ?? 'default',
      name: json['name'] as String? ?? LivingBkkBrand.name,
      taglineEn: json['tagline_en'] as String? ?? LivingBkkBrand.taglineEn,
      taglineTh: json['tagline_th'] as String? ?? LivingBkkBrand.taglineTh,
      logoMarkUrl: json['logo_mark_url'] as String?,
      logoHorizontalUrl: json['logo_horizontal_url'] as String?,
      logoWhiteUrl: json['logo_white_url'] as String?,
      faviconUrl: json['favicon_url'] as String?,
      appIconUrl: json['app_icon_url'] as String?,
      brandGuideUrl: json['brand_guide_url'] as String?,
      colors: colors.isEmpty ? LivingBkkBrand.colorTokens : colors,
      fontFamily: fontFamily,
    );
  }

  String tagline(bool isEnglish) => isEnglish ? taglineEn : taglineTh;

  String mainSlogan(bool isEnglish) => isEnglish
      ? LivingBkkBrand.loginMainSloganEn
      : LivingBkkBrand.loginMainSloganTh;
}
