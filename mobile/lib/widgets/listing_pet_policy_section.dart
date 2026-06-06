import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/listing_pet_policy.dart';
import '../theme/app_theme.dart';

/// นโยบายเลี้ยงสัตว์ — ตอนลงประกาศ
class ListingPetPolicySection extends StatelessWidget {
  const ListingPetPolicySection({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxWeightController,
    this.maxCountController,
  });

  final ListingPetPolicyInput value;
  final ValueChanged<ListingPetPolicyInput> onChanged;
  final TextEditingController? maxWeightController;
  final TextEditingController? maxCountController;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.petPolicySectionTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          s.petPolicySectionHint,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 10),
        RadioListTile<bool>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(s.petPolicyNotAllowed, style: const TextStyle(fontSize: 14)),
          value: false,
          groupValue: value.allowed,
          activeColor: AppTheme.primary,
          onChanged: (_) => onChanged(
            value.copyWith(
              allowed: false,
              clearMaxWeight: true,
              clearMaxCount: true,
              dogsAllowed: false,
              catsAllowed: false,
            ),
          ),
        ),
        RadioListTile<bool>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(s.petPolicyAllowed, style: const TextStyle(fontSize: 14)),
          value: true,
          groupValue: value.allowed,
          activeColor: AppTheme.primary,
          onChanged: (_) => onChanged(value.copyWith(allowed: true)),
        ),
        if (value.allowed) ...[
          const SizedBox(height: 8),
          Text(
            s.petPolicyTypesQuestion,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(s.petPolicyDogs, style: const TextStyle(fontSize: 14)),
            value: value.dogsAllowed,
            activeColor: AppTheme.primary,
            onChanged: (v) => onChanged(value.copyWith(dogsAllowed: v ?? false)),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(s.petPolicyCats, style: const TextStyle(fontSize: 14)),
            value: value.catsAllowed,
            activeColor: AppTheme.primary,
            onChanged: (v) => onChanged(value.copyWith(catsAllowed: v ?? false)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: maxWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.petPolicyMaxWeightLabel,
                    hintText: s.petPolicyOptionalHint,
                    border: const OutlineInputBorder(),
                    suffixText: s.t('กก.', 'kg'),
                  ),
                  onChanged: (raw) {
                    final w = double.tryParse(raw.replaceAll(',', ''));
                    onChanged(value.copyWith(
                      maxWeightKg: w,
                      clearMaxWeight: w == null && raw.trim().isEmpty,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.petPolicyMaxCountLabel,
                    hintText: s.petPolicyOptionalHint,
                    border: const OutlineInputBorder(),
                    suffixText: s.t('ตัว', 'pets'),
                  ),
                  onChanged: (raw) {
                    final c = int.tryParse(raw.replaceAll(',', ''));
                    onChanged(value.copyWith(
                      maxCount: c,
                      clearMaxCount: c == null && raw.trim().isEmpty,
                    ));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.petPolicyOptionalNote,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }
}
