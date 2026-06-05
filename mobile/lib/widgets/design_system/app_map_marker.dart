import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// On-map price pill (purple → pink gradient per design spec).
class AppMapMarker extends StatelessWidget {
  const AppMapMarker({
    super.key,
    required this.label,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final padH = compact ? 8.0 : 10.0;
    final padV = compact ? 4.0 : 6.0;
    final fontSize = compact ? 11.0 : 12.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selected
              ? [p.primary, p.accent]
              : [p.primary.withOpacity(0.95), p.accent.withOpacity(0.92)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: selected ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: selected
            ? Border.all(color: Colors.white.withOpacity(0.85), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Text(
          label,
          style: AppTypography.caption(p).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Formats net price for map markers (shared with [MapPriceMarker]).
String formatMapMarkerPrice(
  double priceNet, {
  required bool isRent,
  bool isEnglish = false,
}) {
  String core;
  if (priceNet >= 1000000) {
    core = '${(priceNet / 1000000).toStringAsFixed(1)}M';
  } else if (priceNet >= 1000) {
    core = '${(priceNet / 1000).round()}k';
  } else {
    core = priceNet.round().toString();
  }
  final suffix = isRent ? (isEnglish ? '/mo' : '/ด') : '';
  return '฿$core$suffix';
}
