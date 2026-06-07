import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config/home_promo_config.dart';
import '../../utils/promo_image_util.dart';

/// รูปโฆษณา — รองรับ URL จากหลังบ้านหรือ asset ในแอป
class HomePromoImage extends StatelessWidget {
  const HomePromoImage({
    super.key,
    required this.promo,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memoryBytes,
  });

  final HomePromoItem promo;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    final animated = PromoImageUtil.isAnimatedPromo(
      memoryBytes: memoryBytes,
      imageUrl: promo.imageUrl,
    );

    if (memoryBytes != null && memoryBytes!.isNotEmpty) {
      return Image.memory(
        memoryBytes!,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: animated,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (promo.hasNetworkImage) {
      return Image.network(
        promo.imageUrl!,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: animated,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (promo.hasBundledImage) {
      return Image.asset(
        promo.imageAsset!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: promo.gradient),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: (height ?? 48).clamp(24, 64),
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
