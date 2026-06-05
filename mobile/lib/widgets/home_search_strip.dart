import 'package:flutter/material.dart';

import '../data/property_catalog.dart';
import '../l10n/app_strings.dart';
import '../state/search_session_controller.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'li_home_header.dart';

/// แถบเช่า/ซื้อ + หมวดทรัพย์ (ใช้ร่วมหน้ารายการและแผนที่)
class HomeSearchStrip extends StatelessWidget {
  const HomeSearchStrip({
    super.key,
    required this.session,
    this.onCategoryTap,
  });

  final SearchSessionController session;
  final void Function(String? slug)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LiTransactionTabs(
                selectedRent: session.isRent,
                onRent: () => session.setListingType('rent'),
                onSale: () => session.setListingType('sale'),
              ),
            ),
            _PropertyTypeRow(
              selectedSlug: session.categorySlug,
              onTap: (slug) {
                session.setCategorySlug(slug);
                onCategoryTap?.call(slug);
              },
            ),
          ],
        );
      },
    );
  }
}

class _PropertyTypeRow extends StatelessWidget {
  const _PropertyTypeRow({
    required this.selectedSlug,
    required this.onTap,
  });

  final String? selectedSlug;
  final void Function(String? slug) onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 10, LiLayout.pagePadding, 4),
      child: Row(
        children: [
          _tab(s.allCategories, selectedSlug == null, () => onTap(null)),
          for (final c in PropertyCatalog.categories)
            _tab(
              s.isEnglish ? c.labelEn : c.labelTh,
              selectedSlug == c.slug,
              () => onTap(c.slug),
            ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 2,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
