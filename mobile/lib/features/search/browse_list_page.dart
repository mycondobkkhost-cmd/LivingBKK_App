import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/shell_tab_navigation.dart';

import '../../data/demo_category_listings.dart';
import '../../data/demo_listings_factory.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/browse_list_route_extra.dart';
import '../../models/listing_public.dart';
import '../../models/listing_transaction_types.dart';
import '../../models/search_filters.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/browse_scoped_search.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../utils/listing_browse_sorter.dart';
import '../../utils/listing_navigation.dart';
import '../../widgets/browse_listing_list.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/map_pin_radius_bar.dart';
import '../../widgets/search_filter_chips.dart';
import '../../widgets/search_filter_sheet.dart';
import '../../widgets/smart_search_bar.dart';
import 'search_discovery_page.dart';

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
  final _sortMenuKey = GlobalKey();
  final _categoryMenuKey = GlobalKey();
  List<ListingPublic> _all = [];
  bool _loading = true;

  late SearchFilters _searchFilters;
  _BrowsePriceSort _sort = _BrowsePriceSort.recommended;
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchFilters = BrowseScopedSearch.initial(widget.extra);
    _searchExpanded = _searchFilters.hasPinRadius ||
        _searchFilters.hasZoneFilters ||
        (_searchFilters.query?.trim().isNotEmpty ?? false);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<ListingPublic> list;
      if (widget.extra.mode == BrowseListMode.section &&
          widget.extra.presetItems != null) {
        list = widget.extra.presetItems!;
      } else if (widget.extra.mode == BrowseListMode.category) {
        list = _categorySeedListings();
        try {
          final remote = await _repo.fetchPublished();
          list = _mergeListings(list, remote);
        } catch (_) {}
      } else {
        list = await _repo.fetchPublished();
      }
      list = _augmentCategorySamples(list);
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = widget.extra.mode == BrowseListMode.category
            ? _categorySeedListings()
            : _augmentCategorySamples(DemoListingsFactory.cached);
        _loading = false;
      });
    }
  }

  List<ListingPublic> _categorySeedListings() =>
      DemoCategoryListings.forSlug(widget.extra.categorySlug);

  List<ListingPublic> _mergeListings(
    List<ListingPublic> primary,
    List<ListingPublic> extra,
  ) {
    final ids = primary.map((l) => l.id).toSet();
    return [
      ...primary,
      ...extra.where((l) => !ids.contains(l.id)),
    ];
  }

  bool _isCategoryDemo(ListingPublic l) =>
      l.id.startsWith('demo-cat-') ||
      l.projectSlug?.startsWith('demo-cat-') == true;

  bool _matchesBrowseFilters(ListingPublic l, SearchFilters f) {
    if (!BrowseScopedSearch.matchesQuery(l, f.query)) return false;

    if (widget.extra.mode == BrowseListMode.category && _isCategoryDemo(l)) {
      if (f.listingType != null &&
          !ListingTransactionTypes.matchesBrowseFilter(
            f.listingType,
            l.listingType,
          )) {
        return false;
      }
      if (f.hasZoneFilters ||
          f.hasPinRadius ||
          f.projectName != null ||
          f.minPrice != null ||
          f.maxPrice != null ||
          f.bedrooms != null ||
          f.coAgentEligibleOnly == true ||
          f.petAllowed == true ||
          f.investorCategory != null) {
        return f.matchesListing(l);
      }
      return true;
    }
    return f.matchesListing(l);
  }

  /// เติมตัวอย่างหมวดหมู่เมื่อเปิดจากเมนูหน้าแรก
  List<ListingPublic> _augmentCategorySamples(List<ListingPublic> source) {
    if (widget.extra.mode != BrowseListMode.category) return source;
    final slug = widget.extra.categorySlug;
    if (slug == null || slug.isEmpty) return source;

    final samples = DemoCategoryListings.forSlug(slug);
    if (samples.isEmpty) return source.isEmpty ? DemoListingsFactory.cached : source;

    final ids = source.map((l) => l.id).toSet();
    final merged = [
      ...source,
      ...samples.where((l) => !ids.contains(l.id)),
    ];
    return merged.isEmpty ? samples : merged;
  }

  void _onSearchFiltersChanged(SearchFilters next) {
    setState(() {
      _searchFilters = BrowseScopedSearch.enforce(next, widget.extra);
      if (_searchFilters.hasPinRadius || _searchFilters.hasZoneFilters) {
        _searchExpanded = true;
      }
    });
  }

  _BrowseTxFilter get _tx {
    final lt = _searchFilters.listingType;
    if (lt == 'rent') return _BrowseTxFilter.rent;
    if (lt != null && ListingTransactionTypes.isSaleFamily(lt)) {
      return _BrowseTxFilter.sale;
    }
    return _BrowseTxFilter.all;
  }

  void _setTx(_BrowseTxFilter tx) {
    final next = switch (tx) {
      _BrowseTxFilter.rent => _searchFilters.copyWith(
          listingType: 'rent',
          clearInvestor: true,
        ),
      _BrowseTxFilter.sale => _searchFilters.copyWith(
          listingType: 'sale',
          clearInvestor: true,
        ),
      _BrowseTxFilter.all => _searchFilters.copyWith(
          clearListingType: true,
          clearInvestor: true,
        ),
    };
    _onSearchFiltersChanged(next);
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

  List<ListingPublic> get _modeScoped {
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
      final slug = widget.extra.categorySlug;
      final cat = PropertyCatalog.bySlug(slug);
      if (cat != null) {
        if (cat.dbValue == 'other') {
          list = list
              .where((l) => l.projectSlug == 'demo-cat-$slug')
              .toList();
        } else {
          list = list.where((l) {
            if (l.propertyType == cat.dbValue) return true;
            if (slug == 'townhome' && l.propertyType == 'townhome') return true;
            return l.projectSlug == 'demo-cat-$slug';
          }).toList();
        }
      }
    } else if (widget.extra.mode == BrowseListMode.area ||
        widget.extra.mode == BrowseListMode.transit ||
        widget.extra.mode == BrowseListMode.tag) {
      list = list.where(_matchesGeo).toList();
    }

    return list;
  }

  List<ListingPublic> get _filtered {
    final f = _searchFilters;
    var list =
        _modeScoped.where((l) => _matchesBrowseFilters(l, f)).toList();

    if (list.isEmpty && widget.extra.mode == BrowseListMode.category) {
      list = _categorySeedListings()
          .where((l) => _matchesBrowseFilters(l, f))
          .toList();
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

  Set<String> _exclusiveHighlightIds(List<ListingPublic> items) {
    if (_sort != _BrowsePriceSort.recommended) return const {};
    final ids = <String>{};
    for (final l in items) {
      if (!l.isFeedExclusive) continue;
      ids.add(l.id);
      if (ids.length >= 4) break;
    }
    return ids;
  }

  Future<void> _openFilters() async {
    final result = await showSearchFilterSheet(
      context,
      initial: _searchFilters,
      lockPropertyType: BrowseScopedSearch.lockedPropertyType(widget.extra),
    );
    if (result != null) _onSearchFiltersChanged(result);
  }

  Future<void> _openMapPin() async {
    setState(() => _searchExpanded = true);
    final result = await Navigator.of(context).push<SearchFilters>(
      MaterialPageRoute<SearchFilters>(
        fullscreenDialog: true,
        builder: (ctx) => _BrowseMapPinPage(
          filters: _searchFilters,
          listings: _modeScoped,
        ),
      ),
    );
    if (result != null) _onSearchFiltersChanged(result);
  }

  Widget _searchBarShell(BuildContext context, {required Widget child}) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: child,
      ),
    );
  }

  Widget _buildCompactSearchPanel(BuildContext context, AppStrings s) {
    return _searchBarShell(
      context,
      child: SmartSearchBar(
        filters: _searchFilters,
        onFiltersChanged: _onSearchFiltersChanged,
        style: SearchBarStyle.airbnb,
        dense: true,
        showFilterChips: false,
        onMapSearch: _openMapPin,
        onOpenFilters: _openFilters,
        onOpenProject: (projectName, {projectSlug}) {
          ListingNavigation.openProject(
            context,
            projectName: projectName,
            projectSlug: projectSlug,
            isAgent: widget.extra.isAgent,
          );
        },
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, AppStrings s) {
    final p = context.palette;
    return _searchBarShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.inputFill,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: p.border),
            ),
            child: SmartSearchBar(
              filters: _searchFilters,
              onFiltersChanged: _onSearchFiltersChanged,
              style: SearchBarStyle.airbnb,
              dense: true,
              onMapSearch: _openMapPin,
              onOpenFilters: _openFilters,
              onOpenProject: (projectName, {projectSlug}) {
                ListingNavigation.openProject(
                  context,
                  projectName: projectName,
                  projectSlug: projectSlug,
                  isAgent: widget.extra.isAgent,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          MapPinRadiusBar(
              filters: _searchFilters,
              pinPlacementMode: false,
              onPinPlacementModeChanged: (v) {
                if (v) _openMapPin();
              },
              onFiltersChanged: _onSearchFiltersChanged,
            ),
            SearchFilterChips(
              filters: _searchFilters,
              onFiltersChanged: _onSearchFiltersChanged,
              padding: const EdgeInsets.only(top: 8),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: p.primary,
                ),
                onPressed: _openSearchDiscovery,
                icon: Icon(Icons.explore_outlined, size: 16, color: p.primary),
                label: Text(
                  s.t('ค้นหาขั้นสูง', 'Advanced search'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildBrowseToolBar(BuildContext context, AppStrings s) {
    final p = context.palette;
    final hasFilters = _searchFilters.hasActiveFilters;
    Widget toolBtn({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      String? subtitle,
      bool showDot = false,
      Key? buttonKey,
    }) {
      return Expanded(
        child: OutlinedButton(
          key: buttonKey,
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: p.textPrimary,
            side: BorderSide(color: p.border),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: p.primary),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 14,
                          color: p.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (showDot)
                Positioned(
                  top: -2,
                  right: -6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        toolBtn(
          buttonKey: _sortMenuKey,
          icon: Icons.swap_vert_rounded,
          label: s.t('เรียงตาม', 'Sort'),
          subtitle: _sortLabel(s),
          onTap: () => _openSortMenu(context, s),
        ),
        const SizedBox(width: 8),
        toolBtn(
          icon: Icons.tune_rounded,
          label: s.filters,
          onTap: _openFilters,
          showDot: hasFilters,
        ),
        const SizedBox(width: 8),
        toolBtn(
          icon: Icons.map_outlined,
          label: s.mapSearchShort,
          onTap: _openMapPin,
        ),
      ],
    );
  }

  void _openSearchDiscovery() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => SearchDiscoveryPage(
          filters: _searchFilters,
          isAgent: widget.extra.isAgent,
          onFiltersChanged: _onSearchFiltersChanged,
          onOpenProject: (projectName, {projectSlug}) {
            ListingNavigation.openProject(
              context,
              projectName: projectName,
              projectSlug: projectSlug,
              isAgent: widget.extra.isAgent,
            );
          },
          onMapSearch: _openMapPin,
        ),
      ),
    );
  }

  Future<void> _openCategoryMenu(BuildContext context, AppStrings s) async {
    final slug = widget.extra.categorySlug;
    if (slug == null || slug.isEmpty) return;

    final box = _categoryMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        bottomRight.dy + 4,
        overlay.size.width - bottomRight.dx,
        overlay.size.height - bottomRight.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        for (final cat in PropertyCatalog.categories)
          _categoryMenuItem(s, cat.slug, cat.label(s.isEnglish)),
      ],
    );

    if (selected == null || selected == slug || !context.mounted) return;
    context.replace('/browse/category/$selected');
  }

  PopupMenuItem<String> _categoryMenuItem(
    AppStrings s,
    String slug,
    String label,
  ) {
    final current = widget.extra.categorySlug;
    final selected = current == slug;
    final p = context.palette;
    return PopupMenuItem<String>(
      value: slug,
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: selected
                ? Icon(Icons.check_rounded, size: 18, color: p.primary)
                : null,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildCategoryTitle(BuildContext context, AppStrings s) {
    final slug = widget.extra.categorySlug;
    if (widget.extra.mode != BrowseListMode.category ||
        slug == null ||
        slug.isEmpty) {
      return null;
    }

    final label =
        PropertyCatalog.bySlug(slug)?.label(s.isEnglish) ?? widget.extra.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: _categoryMenuKey,
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openCategoryMenu(context, s),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 1),
              const Icon(
                Icons.expand_more_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final items = _filtered;
    final highlightIds = _exclusiveHighlightIds(items);
    final total = items.length;
    final categoryTitle = _buildCategoryTitle(context, s);

    return ConsumerPageShell(
      title: widget.extra.title,
      titleWidget: categoryTitle,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          ShellTabNavigation.goToTab(context, 0);
        }
      },
      actions: [
        ConsumerHeaderIconButton(
          icon: Icons.tune_rounded,
          onTap: _openFilters,
        ),
      ],
      headerBottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          LiLayout.pagePadding,
          0,
          LiLayout.pagePadding,
          4,
        ),
        child: _searchExpanded
            ? _buildSearchPanel(context, s)
            : _buildCompactSearchPanel(context, s),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: PageSafeInsets.padLTRB(
                  context,
                  left: LiLayout.pagePadding,
                  top: LiLayout.pagePadding,
                  right: LiLayout.pagePadding,
                  bottom: LiLayout.pagePadding,
                  addHomeIndicator: false,
                ),
                children: [
                  _buildBrowseToolBar(context, s),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_searchFilters.hasActiveFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _chip(
                              s.t('เคลียร์ข้อมูล', 'Clear'),
                              false,
                              () {
                                setState(() {
                                  _searchExpanded = false;
                                  _searchFilters = BrowseScopedSearch.initial(
                                    widget.extra,
                                  );
                                });
                              },
                            ),
                          ),
                        _chip(
                          s.rent,
                          _tx == _BrowseTxFilter.rent,
                          () => _setTx(_BrowseTxFilter.rent),
                        ),
                        _chip(
                          s.listingTypeSale,
                          _tx == _BrowseTxFilter.sale,
                          () => _setTx(_BrowseTxFilter.sale),
                        ),
                        _chip(
                          s.demandFilterAll,
                          _tx == _BrowseTxFilter.all,
                          () => _setTx(_BrowseTxFilter.all),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.browseResultsCount(total),
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          s.noListings,
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    BrowseListingList(
                      items: items,
                      browseFilter: _searchFilters.listingType,
                      highlightRecommendedIds: highlightIds,
                      onTapListing: (item) => ListingNavigation.openListing(
                        context,
                        listing: item,
                        isAgent: widget.extra.isAgent,
                      ),
                    ),
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

  Future<void> _openSortMenu(BuildContext context, AppStrings s) async {
    final box = _sortMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final selected = await showMenu<_BrowsePriceSort>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        bottomRight.dy + 4,
        overlay.size.width - bottomRight.dx,
        overlay.size.height - bottomRight.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        _sortMenuItem(s, _BrowsePriceSort.recommended, s.sortRecommended),
        _sortMenuItem(s, _BrowsePriceSort.highToLow, s.sortPriceHighToLow),
        _sortMenuItem(s, _BrowsePriceSort.lowToHigh, s.sortPriceLowToHigh),
      ],
    );

    if (selected != null && selected != _sort) {
      setState(() => _sort = selected);
    }
  }

  PopupMenuItem<_BrowsePriceSort> _sortMenuItem(
    AppStrings s,
    _BrowsePriceSort value,
    String label,
  ) {
    final selected = _sort == value;
    final p = context.palette;
    return PopupMenuItem<_BrowsePriceSort>(
      value: value,
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: selected
                ? Icon(Icons.check_rounded, size: 18, color: p.primary)
                : null,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? p.primary : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    bool active,
    VoidCallback onTap, {
    bool showArrow = false,
    bool isSort = false,
  }) {
    final p = context.palette;
    final fg = active ? p.onPrimary : p.textPrimary;
    final bg = active ? p.primary : p.surface;
    final borderColor = isSort
        ? p.textSecondary.withOpacity(0.45)
        : (active ? p.primary : p.border);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.swap_vert, size: 14, color: fg),
            ],
          ],
        ),
        showCheckmark: false,
        selected: active,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: bg,
        selectedColor: p.primary,
        side: BorderSide(color: borderColor, width: active ? 1.5 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _BrowseMapPinPage extends StatefulWidget {
  const _BrowseMapPinPage({
    required this.filters,
    required this.listings,
  });

  final SearchFilters filters;
  final List<ListingPublic> listings;

  @override
  State<_BrowseMapPinPage> createState() => _BrowseMapPinPageState();
}

class _BrowseMapPinPageState extends State<_BrowseMapPinPage> {
  late SearchFilters _filters;
  bool _pinPlacementMode = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
    _pinPlacementMode = !_filters.hasPinRadius;
  }

  void _onPinPlaced(double lat, double lng) {
    final radius = _filters.radiusKm ?? kSearchPinRadiusDefaultKm;
    setState(() {
      _filters = _filters.copyWith(
        pinLatitude: lat,
        pinLongitude: lng,
        radiusKm: radius,
      );
      _pinPlacementMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AppMobileScaffold(
      safeBottomBody: false,
      appBar: AppBar(
        title: Text(s.mapSearchLabel),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _filters),
            child: Text(s.applyFilters),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListingsMap(
              listings: widget.listings,
              fullBleed: true,
              focusUserOnStart: true,
              showPriceOnMarker: true,
              pinLatitude: _filters.pinLatitude,
              pinLongitude: _filters.pinLongitude,
              radiusKm: _filters.radiusKm,
              pinPlacementMode: _pinPlacementMode,
              onPinPlaced: _onPinPlaced,
            ),
          ),
          Material(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 12),
              child: MapPinRadiusBar(
                filters: _filters,
                pinPlacementMode: _pinPlacementMode,
                onPinPlacementModeChanged: (v) =>
                    setState(() => _pinPlacementMode = v),
                onFiltersChanged: (next) => setState(() => _filters = next),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
