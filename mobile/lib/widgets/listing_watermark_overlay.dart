import 'package:flutter/material.dart';

import '../models/platform_watermark_settings.dart';
import '../theme/brand_assets.dart';

/// ลายน้ำบนรูปประกาศ — พรีวิวตามค่าแพลตฟอร์ม (ไม่ burn จริง)
class ListingWatermarkOverlay extends StatelessWidget {
  const ListingWatermarkOverlay({
    super.key,
    required this.settings,
    this.padding = 12,
  });

  final PlatformWatermarkSettings settings;
  final double padding;

  @override
  Widget build(BuildContext context) {
    if (!settings.enabled) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = settings.sizeRatio.clamp(0.04, 0.2);
        final width = (constraints.maxWidth * ratio).clamp(32.0, 160.0);
        final opacity = (settings.opacity / 255).clamp(0.08, 0.85);
        final url = settings.publicUrl?.trim();

        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Opacity(
              opacity: opacity,
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      width: width,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _fallback(width),
                    )
                  : _fallback(width),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback(double width) {
    return Image.asset(
      BrandAssets.logoMark,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.water_drop_outlined, size: width * 0.6),
    );
  }
}
