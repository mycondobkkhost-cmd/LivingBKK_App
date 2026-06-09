import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/brand_service.dart';
import '../state/locale_controller.dart';
import '../theme/brand_assets.dart';
import '../theme/living_bkk_brand.dart';

enum LivingBkkLogoSize { sm, md, lg }

/// RealXtate logo — official lockup PNG จาก master (ห้ามประกอบฟอนต์เอง)
class LivingBkkLogo extends StatelessWidget {
  const LivingBkkLogo({
    super.key,
    this.size = LivingBkkLogoSize.md,
    this.showTagline = false,
    this.showMainSlogan = false,
    this.taglineSingleLine = false,
    this.light = false,
    this.onGradient = false,
    this.isEnglish,
  });

  final LivingBkkLogoSize size;
  final bool showTagline;
  final bool showMainSlogan;
  final bool taglineSingleLine;
  final bool light;
  final bool onGradient;
  final bool? isEnglish;

  double get _lockupHeight => switch (size) {
        LivingBkkLogoSize.sm => 28,
        LivingBkkLogoSize.md => 36,
        LivingBkkLogoSize.lg => 48,
      };

  String _lockupAsset(bool onDark) =>
      onDark ? BrandAssets.logoLockupCompactDark : BrandAssets.logoLockupCompactLight;

  bool _resolveEnglish(BuildContext context) {
    if (isEnglish != null) return isEnglish!;
    return LocaleController.instance?.isEnglish ??
        Localizations.localeOf(context).languageCode == 'en';
  }

  bool _resolveOnDark(BuildContext context) {
    if (light) return true;
    if (onGradient) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final en = _resolveEnglish(context);
    final onDark = _resolveOnDark(context);
    final brand = BrandService.instance.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _lockupAsset(onDark || onGradient),
          height: _lockupHeight,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: LivingBkkBrand.name,
        ),
        if (showMainSlogan) ...[
          SizedBox(height: size == LivingBkkLogoSize.lg ? 6 : 4),
          Text(
            brand.mainSlogan(en),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.prompt(
              fontSize: size == LivingBkkLogoSize.lg ? 13 : 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: LivingBkkBrand.purplePrimary,
            ),
          ),
        ],
        if (showTagline) ...[
          SizedBox(height: size == LivingBkkLogoSize.lg ? 8 : 4),
          Padding(
            padding: EdgeInsets.only(right: taglineSingleLine ? 8 : 0),
            child: Text(
              brand.tagline(en),
              maxLines: taglineSingleLine ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: GoogleFonts.prompt(
                fontSize: taglineSingleLine
                    ? (size == LivingBkkLogoSize.lg ? 13.5 : 11.5)
                    : (size == LivingBkkLogoSize.lg ? 10.5 : 9.5),
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: onDark || onGradient
                    ? LivingBkkBrand.loginSubSloganColor.withOpacity(0.95)
                    : (en
                        ? const Color(0xFF4D4FE0)
                        : LivingBkkBrand.purplePrimary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Brand mark only (transparent P icon).
class LivingBkkLogoMarkWidget extends StatelessWidget {
  const LivingBkkLogoMarkWidget({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.logoMark,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'RealXtate',
    );
  }
}
