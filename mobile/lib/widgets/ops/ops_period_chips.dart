import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// เลือกช่วงวันรายงาน — 7 / 14 / 30
class OpsPeriodChips extends StatelessWidget {
  const OpsPeriodChips({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labels,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final Map<int, String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: labels.entries.map((e) {
        final selected = value == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (_) => onChanged(e.key),
          selectedColor: AppTheme.primaryLight,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          ),
          side: BorderSide(
            color: selected ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}
