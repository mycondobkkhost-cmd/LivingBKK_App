import 'package:flutter/material.dart';

import '../data/property_catalog.dart';
import '../l10n/app_strings.dart';
import '../models/listing_transaction_types.dart';
import '../models/search_filters.dart';
import '../theme/app_theme.dart';
import '../utils/price_slider_scale.dart';

Future<SearchFilters?> showSearchFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _SearchFilterSheetBody(initial: initial),
  );
}

class _SearchFilterSheetBody extends StatefulWidget {
  const _SearchFilterSheetBody({required this.initial});

  final SearchFilters initial;

  @override
  State<_SearchFilterSheetBody> createState() => _SearchFilterSheetBodyState();
}

class _SearchFilterSheetBodyState extends State<_SearchFilterSheetBody> {
  late String? _listingType;
  late String? _propertyType;
  late int? _bedrooms;
  late double _minPos;
  late double _maxPos;
  late bool _petAllowed;
  late String? _investorCategory;
  late double _minYield;

  bool get _isSale => ListingTransactionTypes.isSaleFamily(_listingType);

  double get _minPrice => _isSale
      ? PriceSliderScale.salePositionToBaht(_minPos)
      : PriceSliderScale.rentPositionToBaht(_minPos);

  double get _maxPrice => _isSale
      ? PriceSliderScale.salePositionToBaht(_maxPos)
      : PriceSliderScale.rentPositionToBaht(_maxPos);

  @override
  void initState() {
    super.initState();
    _listingType = widget.initial.listingType;
    _propertyType = widget.initial.propertyType;
    _bedrooms = widget.initial.bedrooms;
    _petAllowed = widget.initial.petAllowed ?? false;
    _investorCategory = widget.initial.investorCategory;
    _minYield = widget.initial.minYield ?? 0;

    final minB = widget.initial.minPrice ?? 0;
    final maxB = widget.initial.maxPrice ??
        (_isSale ? PriceSliderScale.defaultSaleMax : PriceSliderScale.defaultRentMax);
    _syncPositionsFromBaht(minB, maxB);
  }

  void _syncPositionsFromBaht(double minB, double maxB) {
    if (_isSale) {
      _minPos = PriceSliderScale.saleBahtToPosition(minB);
      _maxPos = PriceSliderScale.saleBahtToPosition(maxB);
    } else {
      _minPos = PriceSliderScale.rentBahtToPosition(minB);
      _maxPos = PriceSliderScale.rentBahtToPosition(maxB);
    }
  }

  void _onListingTypeChanged(String? type) {
    setState(() {
      _listingType = type;
      if (!_isSale) _investorCategory = null;
      _syncPositionsFromBaht(
        0,
        _isSale ? PriceSliderScale.defaultSaleMax : PriceSliderScale.defaultRentMax,
      );
    });
  }

  SearchFilters _build() {
    final cap = _isSale ? PriceSliderScale.saleCap : PriceSliderScale.rentCap;
    return SearchFilters(
      query: widget.initial.query,
      listingType: _listingType,
      propertyType: _propertyType,
      minPrice: _minPrice > 0 ? _minPrice : null,
      maxPrice: _maxPrice < cap - 1 ? _maxPrice : null,
      bedrooms: _bedrooms,
      projectName: widget.initial.projectName,
      geoZoneSlugs: widget.initial.geoZoneSlugs,
      petAllowed: _petAllowed ? true : null,
      investorCategory: _isSale ? _investorCategory : null,
      minYield: _isSale && _minYield > 0 ? _minYield : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final minFmt = PriceSliderScale.formatBaht(_minPrice, isSale: _isSale);
    final maxFmt = PriceSliderScale.formatBaht(_maxPrice, isSale: _isSale);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.filterTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(s.filterTransactionType, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _typeChip(s.filterRentSeek, 'rent', _listingType == 'rent'),
                _typeChip(s.filterBuySeek, 'sale', _listingType == 'sale'),
                _typeChip(s.listingTypeSaleInstallment, 'sale_installment',
                    _listingType == 'sale_installment'),
              ],
            ),
            const SizedBox(height: 16),
            Text(s.filterPropertyType, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: InputDecoration(
                hintText: s.allCategories,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(s.allCategories),
                ),
                ...PropertyCatalog.categories.map(
                  (c) => DropdownMenuItem(
                    value: c.slug,
                    child: Text(c.label(s.isEnglish)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _propertyType = v),
            ),
            const SizedBox(height: 16),
            Text(s.filterBedrooms, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _bedChip(s.filterStudio, 0),
                _bedChip(s.bedCount(1), 1),
                _bedChip(s.bedCount(2), 2),
                _bedChip(s.filterBed3Plus, 3),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isSale
                  ? s.salePriceRange(minFmt, maxFmt)
                  : s.rentPriceRange(minFmt, maxFmt),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_isSale)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.filterPriceHintSale,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            RangeSlider(
              values: RangeValues(_minPos, _maxPos),
              min: 0,
              max: 1,
              divisions: 100,
              activeColor: AppTheme.primary,
              labels: RangeLabels(minFmt, maxFmt),
              onChanged: (v) => setState(() {
                _minPos = v.start;
                _maxPos = v.end;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.filterPetAllowed),
              value: _petAllowed,
              onChanged: (v) => setState(() => _petAllowed = v),
            ),
            if (_isSale) ...[
              const SizedBox(height: 12),
              Text(
                s.filterInvestor,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(s.filterWithTenant),
                    selected: _investorCategory == 'with_tenant',
                    onSelected: (_) => setState(() {
                      _investorCategory = _investorCategory == 'with_tenant'
                          ? null
                          : 'with_tenant';
                    }),
                    selectedColor: AppTheme.primaryLight,
                  ),
                  FilterChip(
                    label: Text(s.filterBmv),
                    selected: _investorCategory == 'bmv',
                    onSelected: (_) => setState(() {
                      _investorCategory =
                          _investorCategory == 'bmv' ? null : 'bmv';
                    }),
                    selectedColor: AppTheme.primaryLight,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.minYieldLabel(
                  _minYield > 0 ? '${_minYield.toStringAsFixed(1)}%' : s.filterNoYield,
                ),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _minYield,
                min: 0,
                max: 12,
                divisions: 12,
                label: _minYield > 0 ? '${_minYield.toStringAsFixed(0)}%' : '—',
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _minYield = v),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _listingType = null;
                      _propertyType = null;
                      _bedrooms = null;
                      _petAllowed = false;
                      _investorCategory = null;
                      _minYield = 0;
                      _syncPositionsFromBaht(
                        0,
                        _isSale
                            ? PriceSliderScale.defaultSaleMax
                            : PriceSliderScale.defaultRentMax,
                      );
                    });
                  },
                  child: Text(s.clearFilters),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _build()),
                  child: Text(s.useFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _onListingTypeChanged(selected ? null : value),
      selectedColor: AppTheme.primaryLight,
    );
  }

  Widget _bedChip(String label, int value) {
    final selected = _bedrooms == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _bedrooms = selected ? null : value;
      }),
      selectedColor: AppTheme.primaryLight,
    );
  }
}
