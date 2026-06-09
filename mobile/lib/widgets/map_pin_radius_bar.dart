import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_filters.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// โทนสีปุ่มปักหมุด — `brandHeader` บนหัวม่วง, `surface` บนพื้นขาว
enum MapPinRadiusBarTone { surface, brandHeader }

/// Map search controls — place pin + adjust radius (500 m–10 km).
class MapPinRadiusBar extends StatelessWidget {
  const MapPinRadiusBar({
    super.key,
    required this.filters,
    required this.pinPlacementMode,
    required this.onPinPlacementModeChanged,
    required this.onFiltersChanged,
    this.tone = MapPinRadiusBarTone.surface,
  });

  final SearchFilters filters;
  final bool pinPlacementMode;
  final ValueChanged<bool> onPinPlacementModeChanged;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final MapPinRadiusBarTone tone;

  bool get _onBrandHeader => tone == MapPinRadiusBarTone.brandHeader;

  ButtonStyle get _pinButtonStyle {
    if (_onBrandHeader) {
      return FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        disabledBackgroundColor: Colors.white.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
      );
    }
    return FilledButton.styleFrom(
      backgroundColor: AppTheme.cta,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppTheme.cta.withOpacity(0.45),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
    );
  }

  static double _roundKm(double km) => (km * 10).round() / 10;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final radius = _roundKm(
      filters.radiusKm ?? kSearchPinRadiusDefaultKm,
    );
    final hasPin = filters.hasPinRadius;
    final radiusLabelColor =
        _onBrandHeader ? Colors.white.withOpacity(0.88) : AppTheme.textSecondary;
    final radiusHintColor =
        _onBrandHeader ? Colors.white.withOpacity(0.75) : AppTheme.textSecondary;
    final sliderActive =
        _onBrandHeader ? Colors.white : p.primary;
    final sliderInactive = _onBrandHeader
        ? Colors.white.withOpacity(0.35)
        : p.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onPinPlacementModeChanged(!pinPlacementMode),
                icon: Icon(
                  pinPlacementMode ? Icons.push_pin : Icons.add_location_alt_outlined,
                  size: 18,
                ),
                label: Text(
                  pinPlacementMode ? s.mapPinTapHint : s.mapPinPlace,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: _pinButtonStyle,
              ),
            ),
            if (hasPin) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onFiltersChanged(filters.copyWith(clearPin: true)),
                tooltip: s.mapPinClear,
                icon: const Icon(Icons.close, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              s.mapPinRadiusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: radiusLabelColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.mapPinRadiusDisplay(radius),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _onBrandHeader ? Colors.white : p.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: sliderActive,
            inactiveTrackColor: sliderInactive,
            thumbColor: sliderActive,
            overlayColor: sliderActive.withOpacity(0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: radius,
            min: kSearchPinRadiusMinKm,
            max: kSearchPinRadiusMaxKm,
            divisions: 95,
            label: s.mapPinRadiusDisplay(radius),
            onChanged: (v) {
              onFiltersChanged(
                filters.copyWith(radiusKm: _roundKm(v)),
              );
            },
          ),
        ),
        if (hasPin)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              s.mapPinActive(radius),
              style: TextStyle(fontSize: 11, color: radiusHintColor),
            ),
          ),
      ],
    );
  }
}
