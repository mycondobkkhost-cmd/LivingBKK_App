import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/brand_assets.dart';
import '../theme/living_bkk_brand.dart';

/// ขนาด lockup P + RealXtate — ใช้ร่วม header / splash / auth
enum ProppiterBrandHeroSize { compact, standard, auth, splash }

/// ขนาดต้นฉบับ `proppiter-header-lockup.png` — จุดเริ่มคำ RealXtate ≈ x=48
abstract final class ProppiterHeaderLockupMetrics {
  static const assetWidth = 214.0;
  static const assetHeight = 56.0;
  static const textStartX = 48.0;

  static double sloganIndentFor(double lockupHeight) =>
      lockupHeight * textStartX / assetHeight;
}

/// Lockup PNG + สโลแกน (ธีมเดียวกับหน้าแรก)
class ProppiterBrandHero extends StatelessWidget {
  const ProppiterBrandHero({
    super.key,
    this.size = ProppiterBrandHeroSize.standard,
    this.centered = false,
    this.showSlogan = true,
    this.sloganLeftIndent,
    this.sloganLift = 0,
  });

  final ProppiterBrandHeroSize size;
  final bool centered;
  final bool showSlogan;
  /// จัดสโลแกนให้ตรงจุดเริ่มคำว่า RealXtate (ไม่ใต้ไอคอน P)
  final double? sloganLeftIndent;
  /// ดึงสโลแกนขึ้น — กึ่งกลางช่องว่างใต้ lockup
  final double sloganLift;

  double get _lockupHeight {
    switch (size) {
      case ProppiterBrandHeroSize.compact:
        return 29;
      case ProppiterBrandHeroSize.standard:
        return 40;
      case ProppiterBrandHeroSize.auth:
        return 48;
      case ProppiterBrandHeroSize.splash:
        return 54;
    }
  }

  double get _sloganSize {
    switch (size) {
      case ProppiterBrandHeroSize.compact:
        return 10;
      case ProppiterBrandHeroSize.standard:
        return 12;
      case ProppiterBrandHeroSize.auth:
        return 13;
      case ProppiterBrandHeroSize.splash:
        return 14;
    }
  }

  /// splash ใช้ system font — กันเส้นเหลืองตอน Google Fonts ยังโหลดบน Web
  TextStyle _sloganTextStyle() {
    final base = TextStyle(
      fontSize: _sloganSize,
      fontWeight: FontWeight.w500,
      height: 1.15,
      color: Colors.white.withOpacity(0.92),
      decoration: TextDecoration.none,
    );
    if (size == ProppiterBrandHeroSize.splash) return base;
    return GoogleFonts.prompt(textStyle: base);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final align = centered ? Alignment.center : Alignment.centerLeft;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: align,
          child: Image.asset(
            BrandAssets.proppiterHeaderLockup,
            height: _lockupHeight,
            fit: BoxFit.contain,
            alignment: align,
            filterQuality: FilterQuality.high,
            semanticLabel: LivingBkkBrand.name,
            errorBuilder: (_, __, ___) => Image.asset(
              BrandAssets.logoLockupEnDark,
              height: _lockupHeight,
              fit: BoxFit.contain,
              alignment: align,
              filterQuality: FilterQuality.high,
              semanticLabel: LivingBkkBrand.name,
            ),
          ),
        ),
        if (showSlogan)
          Transform.translate(
            offset: Offset(0, -sloganLift),
            child: Padding(
              padding: EdgeInsets.only(
                left: sloganLeftIndent ??
                    ProppiterHeaderLockupMetrics.sloganIndentFor(_lockupHeight),
                top: switch (size) {
                  ProppiterBrandHeroSize.compact => 0,
                  ProppiterBrandHeroSize.auth => 3,
                  _ => 1,
                },
              ),
              child: Text(
                s.homeHeaderSlogan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: _sloganTextStyle(),
              ),
            ),
          ),
      ],
    );
  }
}
