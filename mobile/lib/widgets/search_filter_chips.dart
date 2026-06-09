import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_filters.dart';
import '../services/search_zone_catalog.dart';
import '../theme/app_theme.dart';

/// Chips สำหรับตัวกรองทำเล/รถไฟฟ้า/โครงการ/สถานศึกษา — ลบได้ทีละรายการ
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.padding = EdgeInsets.zero,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final hasInvestor = filters.investorCategory != null;
    if (!filters.hasZoneFilters && !filters.hasPinRadius && !hasInvestor) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);
    final chips = <Widget>[];

    if (filters.investorCategory == 'with_tenant') {
      chips.add(
        InputChip(
          label: Text(
            s.filterSaleWithTenant,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => onFiltersChanged(filters.copyWith(clearInvestor: true)),
          backgroundColor: AppTheme.primaryLight,
          side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else if (filters.investorCategory == 'bmv') {
      chips.add(
        InputChip(
          label: Text(
            s.filterBmv,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => onFiltersChanged(filters.copyWith(clearInvestor: true)),
          backgroundColor: AppTheme.primaryLight,
          side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (filters.hasPinRadius) {
      chips.add(
        InputChip(
          label: Text(
            s.mapPinActive(filters.radiusKm!),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => onFiltersChanged(filters.copyWith(clearPin: true)),
          backgroundColor: AppTheme.primaryLight,
          side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    void addChips(List<String>? ids, String category, void Function(String) onRemove) {
      for (final id in ids ?? const <String>[]) {
        chips.add(
          InputChip(
            label: Text(
              SearchZoneCatalog.instance.labelFor(
                category: category,
                id: id,
                isEnglish: s.isEnglish,
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onRemove(id),
            backgroundColor: AppTheme.primaryLight,
            side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }
    }

    addChips(filters.geoZoneSlugs, 'location', (id) {
      final next = List<String>.from(filters.geoZoneSlugs ?? [])..remove(id);
      onFiltersChanged(filters.copyWith(
        geoZoneSlugs: next.isEmpty ? null : next,
        clearGeoZones: next.isEmpty,
      ));
    });
    addChips(filters.transitSlugs, 'transit', (id) {
      final next = List<String>.from(filters.transitSlugs ?? [])..remove(id);
      onFiltersChanged(filters.copyWith(
        transitSlugs: next.isEmpty ? null : next,
        clearTransit: next.isEmpty,
      ));
    });
    addChips(filters.educationSlugs, 'education', (id) {
      final next = List<String>.from(filters.educationSlugs ?? [])..remove(id);
      onFiltersChanged(filters.copyWith(
        educationSlugs: next.isEmpty ? null : next,
        clearEducation: next.isEmpty,
      ));
    });

    return Padding(
      padding: padding,
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}
