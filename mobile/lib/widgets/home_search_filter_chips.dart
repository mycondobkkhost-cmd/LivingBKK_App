import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/search_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// ตัวกรองด่วนใต้ช่องค้นหา — เช่า/ซื้อ + ปุ่มตัวกรอง
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
        final isRent = session.isRent;
        final isSale = session.filters.listingType == 'sale';

        return Padding(
          padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 4),
          child: Row(
            children: [
              _chip(
                p,
                s.rent,
                isRent && !isSale,
                () => session.setListingType('rent'),
              ),
              const SizedBox(width: 8),
              _chip(
                p,
                s.sale,
                isSale,
                () => session.setListingType('sale'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onOpenFilters,
                icon: Icon(
                  Icons.tune,
                  size: 18,
                  color: hasActiveFilters ? p.primary : p.textSecondary,
                ),
                label: Text(
                  hasActiveFilters ? s.filtersActive : s.advancedFilters,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasActiveFilters ? p.primary : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(AppPalette p, String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? p.onPrimary : p.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      backgroundColor: p.surface,
      selectedColor: p.primary,
      side: BorderSide(color: selected ? p.primary : p.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
    );
  }
}
