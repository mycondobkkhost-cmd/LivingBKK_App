import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/price_slider_scale.dart';

/// แถบเลื่อนงบประมาณ min–max — เช่า / ซื้อ
class BudgetRangeSlider extends StatelessWidget {
  const BudgetRangeSlider({
    super.key,
    required this.minPos,
    required this.maxPos,
    required this.onChanged,
    this.isSale = false,
    this.label,
  });

  final double minPos;
  final double maxPos;
  final ValueChanged<RangeValues> onChanged;
  final bool isSale;
  final String? label;

  double _posToBaht(double p) => isSale
      ? PriceSliderScale.salePositionToBaht(p)
      : PriceSliderScale.rentPositionToBaht(p);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final minBaht = _posToBaht(minPos);
    final maxBaht = _posToBaht(maxPos);
    final displayLabel = label ??
        (isSale ? s.requirementFieldBudgetRangeSale : s.requirementFieldBudgetRangeRent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$displayLabel: ${PriceSliderScale.formatBaht(minBaht, isSale: isSale)} – ${PriceSliderScale.formatBaht(maxBaht, isSale: isSale)}',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        RangeSlider(
          values: RangeValues(minPos, maxPos),
          min: 0,
          max: 1,
          divisions: 100,
          activeColor: AppTheme.primary,
          labels: RangeLabels(
            PriceSliderScale.formatBaht(minBaht, isSale: isSale),
            PriceSliderScale.formatBaht(maxBaht, isSale: isSale),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
