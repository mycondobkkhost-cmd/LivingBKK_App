import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_listings_factory.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/browse_list_route_extra.dart';
import '../../models/listing_public.dart';
import '../../models/listing_transaction_types.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/listing_browse_sorter.dart';
import '../../utils/listing_navigation.dart';
import '../../widgets/listing_card.dart';

enum _BrowseTxFilter { all, rent, sale }

enum _BrowsePriceSort { recommended, highToLow, lowToHigh }

class BrowseListPage extends StatefulWidget {
  const BrowseListPage({super.key, required this.extra});

  final BrowseListRouteExtra extra;

  @override
  State<BrowseListPage> createState() => _BrowseListPageState();
}

class _BrowseListPageState extends State<BrowseListPage> {
  final _repo = ListingRepository();
  List<ListingPublic> _all = [];
  bool _loading = true;

  _BrowseTxFilter _tx = _BrowseTxFilter.all;
  String? _propertySlug;
  double? _minPrice;
  double? _maxPrice;
  double? _minArea;
  double? _maxArea;
  _BrowsePriceSort _sort = _BrowsePriceSort.recommended;

  @override
  void initState() {
    super.initState();
    _propertySlug = widget.extra.categorySlug;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<ListingPublic> list;
      if (widget.extra.mode == BrowseListMode.section &&
          widget.extra.presetItems != null) {
        list = widget.extra.presetItems!;
      } else {
        list = await _repo.fetchPublished();
      }
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = DemoListingsFactory.cached;
        _loading = false;
      });
    }
  }

  bool _matchesGeo(ListingPublic l) {
    final slugs = widget.extra.geoZoneSlugs;
    final tagLabel = widget.extra.tagLabel?.toLowerCase();
    if (tagLabel != null && tagLabel.isNotEmpty) {
      final hay =
          '${l.district ?? ''} ${l.projectName ?? ''} ${l.title} ${l.geoZoneSlug ?? ''} ${l.listingCode}'
              .toLowerCase();
      if (hay.contains(tagLabel)) return true;
    }
    if (slugs == null || slugs.isEmpty) return tagLabel == null;
    if (l.geoZoneSlug != null && slugs.contains(l.geoZoneSlug)) return true;
    final hay =
        '${l.district ?? ''} ${l.projectName ?? ''} ${l.title}'.toLowerCase();
    return slugs.any((s) => hay.contains(s.replaceAll('-', ' ')));
  }

  List<ListingPublic> get _filtered {
    var list = List<ListingPublic>.from(_all);

    if (widget.extra.mode == BrowseListMode.project) {
      final name = widget.extra.projectName;
      final slug = widget.extra.projectSlug;
      list = list.where((l) {
        if (slug != null && slug.isNotEmpty && l.projectSlug == slug) return true;
        if (name != null && l.projectName == name) return true;
        if (name != null &&
            (l.projectName?.contains(name) == true ||
                name.contains(l.projectName ?? ''))) {
          return true;
        }
        return false;
      }).toList();
    } else if (widget.extra.mode == BrowseListMode.category) {
      final db = PropertyCatalog.dbValueForSlug(widget.extra.categorySlug);
      if (db != null) {
        list = list.where((l) => l.propertyType == db).toList();
      }
    } else if (widget.extra.mode == BrowseListMode.area ||
        widget.extra.mode == BrowseListMode.transit ||
        widget.extra.mode == BrowseListMode.tag) {
      list = list.where(_matchesGeo).toList();
    }

    if (_propertySlug != null) {
      final db = PropertyCatalog.dbValueForSlug(_propertySlug);
      if (db != null) {
        list = list.where((l) => l.propertyType == db).toList();
      }
    }

    if (_tx == _BrowseTxFilter.rent) {
      list = list.where((l) => l.listingType == 'rent').toList();
    } else if (_tx == _BrowseTxFilter.sale) {
      list = list
          .where((l) => ListingTransactionTypes.matchesBrowseFilter('sale', l.listingType))
          .toList();
    }

    if (_minPrice != null) {
      list = list.where((l) => l.priceNet >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      list = list.where((l) => l.priceNet <= _maxPrice!).toList();
    }
    if (_minArea != null) {
      list = list.where((l) => (l.areaSqm ?? 0) >= _minArea!).toList();
    }
    if (_maxArea != null) {
      list = list.where((l) => (l.areaSqm ?? double.infinity) <= _maxArea!).toList();
    }

    switch (_sort) {
      case _BrowsePriceSort.recommended:
        return ListingBrowseSorter.browseOrder(list);
      case _BrowsePriceSort.highToLow:
        list.sort((a, b) => b.priceNet.compareTo(a.priceNet));
        return list;
      case _BrowsePriceSort.lowToHigh:
        list.sort((a, b) => a.priceNet.compareTo(b.priceNet));
        return list;
    }
  }

  ({List<ListingPublic> recommended, List<ListingPublic> rest}) get _sections {
    final items = _filtered;
    if (_sort != _BrowsePriceSort.recommended || items.length <= 4) {
      return (recommended: const [], rest: items);
    }
    final top = items.take(4).toList();
    final rest = items.skip(4).toList();
    return (recommended: top, rest: rest);
  }

  Future<void> _openFilters() async {
    final s = AppStrings.of(context);
    final minPC = TextEditingController(text: _minPrice?.toInt().toString() ?? '');
    final maxPC = TextEditingController(text: _maxPrice?.toInt().toString() ?? '');
    final minAC = TextEditingController(text: _minArea?.toInt().toString() ?? '');
    final maxAC = TextEditingController(text: _maxArea?.toInt().toString() ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.budgetLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.t('ราคาต่ำสุด', 'Min price')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxPC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.t('ราคาสูงสุด', 'Max price')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s.areaSqmLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minAC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.t('ต่ำสุด', 'Min')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxAC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.t('สูงสุด', 'Max')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _minPrice = double.tryParse(minPC.text.replaceAll(',', ''));
                    _maxPrice = double.tryParse(maxPC.text.replaceAll(',', ''));
                    _minArea = double.tryParse(minAC.text.replaceAll(',', ''));
                    _maxArea = double.tryParse(maxAC.text.replaceAll(',', ''));
                  });
                  Navigator.pop(ctx);
                },
                child: Text(s.applyFilters),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final sections = _sections;
    final total = _filtered.length;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(widget.extra.title),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(LiLayout.pagePadding),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                          s.rent,
                          _tx == _BrowseTxFilter.rent,
                          () => setState(() => _tx = _BrowseTxFilter.rent),
                        ),
                        _chip(
                          s.listingTypeSale,
                          _tx == _BrowseTxFilter.sale,
                          () => setState(() => _tx = _BrowseTxFilter.sale),
                        ),
                        _chip(
                          s.demandFilterAll,
                          _tx == _BrowseTxFilter.all,
                          () => setState(() => _tx = _BrowseTxFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _sortLabel(s),
                          true,
                          _cycleSort,
                          showArrow: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.browseResultsCount(total),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (sections.recommended.isNotEmpty) ...[
                    Text(
                      s.browseRecommendedTop,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    ...sections.recommended.map((item) => _card(item)),
                    const SizedBox(height: 16),
                    Text(
                      s.browseRecentlyUpdated,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sections.rest.isEmpty && sections.recommended.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          s.noListings,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...sections.rest.map((item) => _card(item)),
                ],
              ),
            ),
    );
  }

  String _sortLabel(AppStrings s) {
    switch (_sort) {
      case _BrowsePriceSort.highToLow:
        return s.sortPriceHighToLow;
      case _BrowsePriceSort.lowToHigh:
        return s.sortPriceLowToHigh;
      case _BrowsePriceSort.recommended:
        return s.sortRecommended;
    }
  }

  void _cycleSort() {
    setState(() {
      _sort = switch (_sort) {
        _BrowsePriceSort.recommended => _BrowsePriceSort.highToLow,
        _BrowsePriceSort.highToLow => _BrowsePriceSort.lowToHigh,
        _BrowsePriceSort.lowToHigh => _BrowsePriceSort.recommended,
      };
    });
  }

  Widget _chip(
    String label,
    bool active,
    VoidCallback onTap, {
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            if (showArrow) ...[
              const SizedBox(width: 2),
              const Icon(Icons.swap_vert, size: 14),
            ],
          ],
        ),
        selected: active,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _card(ListingPublic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListingCard(
        listing: item,
        style: ListingCardStyle.feed,
        showCoAgentStrip: widget.extra.isAgent,
        onTap: () => ListingNavigation.openListing(
          context,
          listing: item,
          isAgent: widget.extra.isAgent,
        ),
      ),
    );
  }
}
