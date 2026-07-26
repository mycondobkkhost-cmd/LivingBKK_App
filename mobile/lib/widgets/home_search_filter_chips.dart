import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/search_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import '../theme/living_bkk_brand.dart';

/// ตัวกรองด่วนใต้ช่องค้นหา — เช่า/ซื้อ + ตัวกรอง (แนว Shopee)
class HomeSearchFilterChips extends StatelessWidget {
  const HomeSearchFilterChips({
    super.key,
    required this.session,
    required this.onOpenFilters,
    this.hasActiveFilters = false,
  });

  final SearchSessionController session;
  final VoidCallback onOpenFilters;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final type = session.filters.listingType;
        final isRent = type == 'rent';
        final isSale = type == 'sale';
        final isAll = type == null;

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              LiLayout.pagePadding,
              6,
              LiLayout.pagePadding,
              6,
            ),
            children: [
              _chip(
                p,
                label: s.isEnglish ? 'All' : 'ทั้งหมด',
                selected: isAll,
                onTap: () => session.setListingType(null),
              ),
              const SizedBox(width: 8),
              _chip(
                p,
                label: s.rent,
                selected: isRent,
                onTap: () => session.setListingType('rent'),
              ),
              const SizedBox(width: 8),
              _chip(
                p,
                label: s.sale,
                selected: isSale,
                onTap: () => session.setListingType('sale'),
              ),
              const SizedBox(width: 10),
              _filterBtn(
                p,
                label: hasActiveFilters ? s.filtersActive : s.advancedFilters,
                active: hasActiveFilters,
                onTap: onOpenFilters,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(
    AppPalette p, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? p.primary : p.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: selected ? p.primary : p.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: selected ? Colors.white : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterBtn(
    AppPalette p, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? LivingBkkBrand.brandRed.withOpacity(0.08)
          : p.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: active ? p.primary : p.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: active ? p.primary : p.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? p.primary : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
