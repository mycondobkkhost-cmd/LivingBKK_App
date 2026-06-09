import 'package:flutter/material.dart';

import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/demand_board_filter_state.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet ตัวกรองบอร์ด — อ้างอิง Inquiry filter (Matching MyStock)
class DemandBoardFilterSheet extends StatefulWidget {
  const DemandBoardFilterSheet({
    super.key,
    required this.initial,
    required this.myStockCount,
  });

  final DemandBoardFilterState initial;
  final int myStockCount;

  static Future<DemandBoardFilterState?> show(
    BuildContext context, {
    required DemandBoardFilterState initial,
    required int myStockCount,
  }) {
    return showModalBottomSheet<DemandBoardFilterState>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: DemandBoardFilterSheet(
          initial: initial,
          myStockCount: myStockCount,
        ),
      ),
    );
  }

  @override
  State<DemandBoardFilterSheet> createState() => _DemandBoardFilterSheetState();
}

class _DemandBoardFilterSheetState extends State<DemandBoardFilterSheet> {
  late bool _matchMyStock;
  late DemandBoardSeekerFilter _seeker;
  late DemandBoardTransactionFilter _tx;
  late Set<String> _propertySlugs;
  late bool _includeCommercial;
  late DemandBoardOfferAcceptFilter _offerAccept;
  late DemandBoardPriceSort _priceSort;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _matchMyStock = i.matchMyStock;
    _seeker = i.seekerStatus;
    _tx = i.transaction;
    _propertySlugs = Set<String>.from(i.propertySlugs);
    _includeCommercial = i.includeCommercial;
    _offerAccept = i.offerAcceptance;
    _priceSort = i.priceSort;
  }

  DemandBoardFilterState _buildResult() {
    return DemandBoardFilterState(
      matchMyStock: _matchMyStock,
      seekerStatus: _seeker,
      transaction: _tx,
      propertySlugs: Set<String>.from(_propertySlugs),
      includeCommercial: _includeCommercial,
      offerAcceptance: _offerAccept,
      priceSort: _priceSort,
    );
  }

  void _clear() {
    setState(() {
      _matchMyStock = false;
      _seeker = DemandBoardSeekerFilter.all;
      _tx = DemandBoardTransactionFilter.all;
      _propertySlugs = {};
      _includeCommercial = true;
      _offerAccept = DemandBoardOfferAcceptFilter.all;
      _priceSort = DemandBoardPriceSort.recent;
    });
  }

  void _toggleSlug(String slug) {
    setState(() {
      if (_propertySlugs.contains(slug)) {
        _propertySlugs.remove(slug);
      } else {
        _propertySlugs.add(slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canMyStock = widget.myStockCount > 0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      s.demandFilterSheetTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  _Section(
                    icon: Icons.sync_alt_rounded,
                    title: s.demandFilterMatchMyStock,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                canMyStock
                                    ? s.demandFilterMatchMyStockHint(
                                        widget.myStockCount,
                                      )
                                    : s.demandFilterMatchMyStockEmpty,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _matchMyStock && canMyStock,
                              onChanged: canMyStock
                                  ? (v) => setState(() => _matchMyStock = v)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    icon: Icons.person_outline,
                    title: s.demandFilterSeekerStatus,
                    child: _DualChoice(
                      left: s.demandSeekerSelf,
                      right: s.demandSeekerAgent,
                      leftSelected:
                          _seeker == DemandBoardSeekerFilter.customerDirect,
                      rightSelected:
                          _seeker == DemandBoardSeekerFilter.agentSourced,
                      onLeft: () => setState(
                        () => _seeker = _seeker ==
                                DemandBoardSeekerFilter.customerDirect
                            ? DemandBoardSeekerFilter.all
                            : DemandBoardSeekerFilter.customerDirect,
                      ),
                      onRight: () => setState(
                        () => _seeker = _seeker ==
                                DemandBoardSeekerFilter.agentSourced
                            ? DemandBoardSeekerFilter.all
                            : DemandBoardSeekerFilter.agentSourced,
                      ),
                    ),
                  ),
                  _Section(
                    icon: Icons.sell_outlined,
                    title: s.demandFilterAnnouncementType,
                    child: _DualChoice(
                      left: s.demandLookingSale,
                      right: s.demandLookingRent,
                      leftSelected: _tx == DemandBoardTransactionFilter.sale,
                      rightSelected: _tx == DemandBoardTransactionFilter.rent,
                      onLeft: () => setState(
                        () => _tx = _tx == DemandBoardTransactionFilter.sale
                            ? DemandBoardTransactionFilter.all
                            : DemandBoardTransactionFilter.sale,
                      ),
                      onRight: () => setState(
                        () => _tx = _tx == DemandBoardTransactionFilter.rent
                            ? DemandBoardTransactionFilter.all
                            : DemandBoardTransactionFilter.rent,
                      ),
                    ),
                  ),
                  _Section(
                    icon: Icons.apartment_outlined,
                    title: s.demandFilterPropertyOptional,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.demandFilterIncludeCommercial,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Switch.adaptive(
                              value: _includeCommercial,
                              onChanged: (v) =>
                                  setState(() => _includeCommercial = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.demandFilterResidential,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: s.demandFilterCondo,
                              selected: _propertySlugs.contains('condo'),
                              onTap: () => _toggleSlug('condo'),
                            ),
                            _Chip(
                              label: s.demandFilterHouse,
                              selected: _propertySlugs.contains('house'),
                              onTap: () => _toggleSlug('house'),
                            ),
                            _Chip(
                              label: s.demandFilterLand,
                              selected: _propertySlugs.contains('land'),
                              onTap: () => _toggleSlug('land'),
                            ),
                          ],
                        ),
                        if (_includeCommercial) ...[
                          const SizedBox(height: 12),
                          Text(
                            s.demandFilterCommercial,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final slug
                                  in DemandBoardFilterState.commercialSlugs)
                                _Chip(
                                  label: PropertyCatalogLabel.slug(slug, s),
                                  selected: _propertySlugs.contains(slug),
                                  onTap: () => _toggleSlug(slug),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _Section(
                    icon: Icons.handshake_outlined,
                    title: s.demandFilterOfferAcceptance,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: s.demandOfferAcceptOwnerOnly,
                          selected:
                              _offerAccept == DemandBoardOfferAcceptFilter.ownerOnly,
                          onTap: () => setState(
                            () => _offerAccept = _offerAccept ==
                                    DemandBoardOfferAcceptFilter.ownerOnly
                                ? DemandBoardOfferAcceptFilter.all
                                : DemandBoardOfferAcceptFilter.ownerOnly,
                          ),
                        ),
                        _Chip(
                          label: s.demandOfferAcceptOwnerAndCoAgent,
                          selected: _offerAccept ==
                              DemandBoardOfferAcceptFilter.ownerAndCoAgent,
                          onTap: () => setState(
                            () => _offerAccept = _offerAccept ==
                                    DemandBoardOfferAcceptFilter.ownerAndCoAgent
                                ? DemandBoardOfferAcceptFilter.all
                                : DemandBoardOfferAcceptFilter.ownerAndCoAgent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    icon: Icons.sort,
                    title: s.sortByPrice,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _Chip(
                          label: s.demandFilterSortRecent,
                          selected: _priceSort == DemandBoardPriceSort.recent,
                          onTap: () => setState(
                            () => _priceSort = DemandBoardPriceSort.recent,
                          ),
                        ),
                        _Chip(
                          label: s.sortPriceHighToLow,
                          selected:
                              _priceSort == DemandBoardPriceSort.highToLow,
                          onTap: () => setState(
                            () => _priceSort = DemandBoardPriceSort.highToLow,
                          ),
                        ),
                        _Chip(
                          label: s.sortPriceLowToHigh,
                          selected:
                              _priceSort == DemandBoardPriceSort.lowToHigh,
                          onTap: () => setState(
                            () => _priceSort = DemandBoardPriceSort.lowToHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _clear,
                      child: Text(s.demandFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, _buildResult()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.cta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(s.demandFilterApply),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ป้ายหมวดจาก PropertyCatalog
abstract final class PropertyCatalogLabel {
  static String slug(String slug, AppStrings s) {
    return PropertyCatalog.bySlug(slug)?.label(s.isEnglish) ?? slug;
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DualChoice extends StatelessWidget {
  const _DualChoice({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceTile(
            label: left,
            selected: leftSelected,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChoiceTile(
            label: right,
            selected: rightSelected,
            onTap: onRight,
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
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
      color: selected ? AppTheme.cta.withOpacity(0.12) : AppTheme.cardTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppTheme.cta : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.cta : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      color: selected ? AppTheme.cta.withOpacity(0.14) : AppTheme.backgroundAlt,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppTheme.cta : AppTheme.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.cta : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
