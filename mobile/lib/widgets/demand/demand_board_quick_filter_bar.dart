import 'package:flutter/material.dart';

import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/demand_board_filter_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';

/// แถบฟิลเตอร์แบบ Inquiry — ประเภท | หาซื้อ-เช่า | ช่วงราคา
class DemandBoardQuickFilterBar extends StatelessWidget {
  const DemandBoardQuickFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final DemandBoardFilterState filters;
  final ValueChanged<DemandBoardFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final txActive = filters.transaction != DemandBoardTransactionFilter.all;
    final typeActive = filters.propertySlugs.isNotEmpty || !filters.includeCommercial;
    final priceActive = filters.priceSort != DemandBoardPriceSort.recent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        2,
        LiLayout.pagePadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterLink(
              label: _propertyLabel(s),
              active: typeActive,
              onTap: () => _openPropertyPanel(context),
            ),
          ),
          Expanded(
            child: _FilterLink(
              label: _txLabel(s),
              active: txActive,
              onTap: () => _openTransactionPanel(context),
            ),
          ),
          Expanded(
            child: _FilterLink(
              label: _priceLabel(s),
              active: priceActive,
              onTap: () => _openPricePanel(context),
            ),
          ),
        ],
      ),
    );
  }

  String _propertyLabel(AppStrings s) {
    if (filters.propertySlugs.isEmpty) return s.demandFilterPropertyType;
    if (filters.propertySlugs.length == 1) {
      final slug = filters.propertySlugs.first;
      final cat = PropertyCatalog.bySlug(slug);
      return cat?.label(s.isEnglish) ?? s.demandFilterPropertyType;
    }
    return s.t(
      'ประเภท (${filters.propertySlugs.length})',
      'Types (${filters.propertySlugs.length})',
    );
  }

  String _txLabel(AppStrings s) {
    return switch (filters.transaction) {
      DemandBoardTransactionFilter.sale => s.demandLookingSale,
      DemandBoardTransactionFilter.rent => s.demandLookingRent,
      DemandBoardTransactionFilter.all => s.demandFilterTransaction,
    };
  }

  String _priceLabel(AppStrings s) {
    return switch (filters.priceSort) {
      DemandBoardPriceSort.highToLow => s.t('ราคาสูง→ต่ำ', 'High → low'),
      DemandBoardPriceSort.lowToHigh => s.t('ราคาต่ำ→สูง', 'Low → high'),
      DemandBoardPriceSort.recent => s.t('ช่วงราคา', 'Price'),
    };
  }

  Future<void> _openTransactionPanel(BuildContext context) async {
    final result = await showModalBottomSheet<DemandBoardFilterState>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickChoiceSheet(
        title: AppStrings.of(ctx).demandFilterTransaction,
        child: _TransactionBody(
          initial: filters.transaction,
          onApply: (tx) => Navigator.pop(
            ctx,
            filters.copyWith(transaction: tx),
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  Future<void> _openPricePanel(BuildContext context) async {
    final result = await showModalBottomSheet<DemandBoardFilterState>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickChoiceSheet(
        title: AppStrings.of(ctx).t('ช่วงราคา', 'Price range'),
        child: _PriceSortBody(
          initial: filters.priceSort,
          onApply: (sort) => Navigator.pop(
            ctx,
            filters.copyWith(priceSort: sort),
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  Future<void> _openPropertyPanel(BuildContext context) async {
    final result = await showModalBottomSheet<DemandBoardFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickChoiceSheet(
        title: AppStrings.of(ctx).demandFilterPropertyType,
        maxHeightFactor: 0.78,
        child: _PropertyTypeBody(
          initialSlugs: filters.propertySlugs,
          includeCommercial: filters.includeCommercial,
          onApply: (slugs, includeCommercial) => Navigator.pop(
            ctx,
            filters.copyWith(
              propertySlugs: slugs,
              includeCommercial: includeCommercial,
            ),
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _FilterLink extends StatelessWidget {
  const _FilterLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? LivingBkkBrand.brandRed : AppTheme.textPrimary.withOpacity(0.88);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChoiceSheet extends StatelessWidget {
  const _QuickChoiceSheet({
    required this.title,
    required this.child,
    this.maxHeightFactor = 0.42,
  });

  final String title;
  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: LivingBkkBrand.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        child: Text(s.demandFilterApply),
      ),
    );
  }
}

class _TransactionBody extends StatefulWidget {
  const _TransactionBody({
    required this.initial,
    required this.onApply,
  });

  final DemandBoardTransactionFilter initial;
  final ValueChanged<DemandBoardTransactionFilter> onApply;

  @override
  State<_TransactionBody> createState() => _TransactionBodyState();
}

class _TransactionBodyState extends State<_TransactionBody> {
  late DemandBoardTransactionFilter _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ChoiceTile(
                label: s.demandLookingSale,
                selected: _value == DemandBoardTransactionFilter.sale,
                onTap: () => setState(
                  () => _value = DemandBoardTransactionFilter.sale,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceTile(
                label: s.demandLookingRent,
                selected: _value == DemandBoardTransactionFilter.rent,
                onTap: () => setState(
                  () => _value = DemandBoardTransactionFilter.rent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(
              () => _value = DemandBoardTransactionFilter.all,
            ),
            child: Text(
              s.demandFilterAll,
              style: TextStyle(
                color: _value == DemandBoardTransactionFilter.all
                    ? LivingBkkBrand.brandRed
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ApplyButton(onTap: () => widget.onApply(_value)),
      ],
    );
  }
}

class _PriceSortBody extends StatefulWidget {
  const _PriceSortBody({
    required this.initial,
    required this.onApply,
  });

  final DemandBoardPriceSort initial;
  final ValueChanged<DemandBoardPriceSort> onApply;

  @override
  State<_PriceSortBody> createState() => _PriceSortBodyState();
}

class _PriceSortBodyState extends State<_PriceSortBody> {
  late DemandBoardPriceSort _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final options = <(DemandBoardPriceSort, String)>[
      (DemandBoardPriceSort.recent, s.demandFilterSortRecent),
      (DemandBoardPriceSort.lowToHigh, s.t('ราคาต่ำ → สูง', 'Low → high')),
      (DemandBoardPriceSort.highToLow, s.t('ราคาสูง → ต่ำ', 'High → low')),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (sort, label) in options) ...[
          _ChoiceTile(
            label: label,
            selected: _value == sort,
            onTap: () => setState(() => _value = sort),
            fullWidth: true,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        _ApplyButton(onTap: () => widget.onApply(_value)),
      ],
    );
  }
}

class _PropertyTypeBody extends StatefulWidget {
  const _PropertyTypeBody({
    required this.initialSlugs,
    required this.includeCommercial,
    required this.onApply,
  });

  final Set<String> initialSlugs;
  final bool includeCommercial;
  final void Function(Set<String> slugs, bool includeCommercial) onApply;

  @override
  State<_PropertyTypeBody> createState() => _PropertyTypeBodyState();
}

class _PropertyTypeBodyState extends State<_PropertyTypeBody> {
  late final Set<String> _slugs = Set<String>.from(widget.initialSlugs);
  late bool _includeCommercial = widget.includeCommercial;

  static const _residential = [
    'condo',
    'house',
    'land',
    'townhome',
    'home_office',
    'apartment',
    'pool_villa',
  ];

  static const _commercial = [
    'commercial',
    'office',
    'showroom',
    'business',
    'factory',
    'warehouse',
    'co_working',
  ];

  void _toggle(String slug) {
    setState(() {
      if (_slugs.contains(slug)) {
        _slugs.remove(slug);
      } else {
        _slugs.add(slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.demandFilterIncludeCommercial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: _includeCommercial,
              activeTrackColor: LivingBkkBrand.brandRed,
              onChanged: (v) => setState(() => _includeCommercial = v),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            children: [
              Text(
                s.demandFilterResidential,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slug in _residential)
                    _PillChip(
                      label: PropertyCatalog.bySlug(slug)?.label(s.isEnglish) ??
                          slug,
                      selected: _slugs.contains(slug),
                      onTap: () => _toggle(slug),
                    ),
                ],
              ),
              if (_includeCommercial) ...[
                const SizedBox(height: 16),
                Text(
                  s.demandFilterCommercial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slug in _commercial)
                      _PillChip(
                        label:
                            PropertyCatalog.bySlug(slug)?.label(s.isEnglish) ??
                                slug,
                        selected: _slugs.contains(slug),
                        onTap: () => _toggle(slug),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        _ApplyButton(onTap: () => widget.onApply(_slugs, _includeCommercial)),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? LivingBkkBrand.brandRedTint
          : LivingBkkBrand.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? LivingBkkBrand.brandRed : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          width: fullWidth ? double.infinity : null,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? LivingBkkBrand.brandRedDark
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LivingBkkBrand.brandRedTint : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? LivingBkkBrand.brandRed : AppTheme.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? LivingBkkBrand.brandRedDark
                  : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
