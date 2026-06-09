import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../data/popular_areas.dart';
import '../../l10n/app_strings.dart';
import '../../data/bangkok_transit_lines.dart';
import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../models/search_filters.dart';
import '../../services/home_sections_builder.dart';
import '../../services/listing_activity_service.dart';
import '../../data/demo_listings_factory.dart';
import '../../services/listing_repository.dart';
import '../../services/preferred_stock_service.dart';
import '../../services/saved_search_service.dart';
import '../../services/search_service.dart';
import '../../utils/geo_distance.dart';
import '../../state/locale_controller.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/localized_content.dart';
import '../../utils/listing_navigation.dart';
import '../../features/notifications/notification_center_sheet.dart';
import '../../services/notification_center_repository.dart';
import '../../widgets/home/home_browse_layout.dart';
import '../../widgets/li_home_header.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/listing_grid.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/map_pin_radius_bar.dart';
import '../../widgets/search_filter_sheet.dart';
import '../../widgets/smart_search_bar.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../utils/page_safe_insets.dart';

class MapHomePage extends StatefulWidget {
  const MapHomePage({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.localeController,
    this.onOpenProfile,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final LocaleController localeController;
  final VoidCallback? onOpenProfile;

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  final _repo = ListingRepository();
  final _searchService = SearchService();
  final _sectionsBuilder = HomeSectionsBuilder();
  List<ListingPublic> _listings = [];
  List<HomeFeedSection> _sections = [];
  bool _loading = true;
  bool _mapView = false;
  bool _focusNearMeOnMap = false;
  bool _pinPlacementMode = false;
  HomeViewModeLi _viewMode = HomeViewModeLi.list;
  String? _selectedId;
  String? _selectedTransitSlug;
  double? _userLat;
  double? _userLng;

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.searchSession.filters.projectSlugs?.isNotEmpty ?? false) {
      widget.searchSession.setFilters(
        widget.searchSession.filters.copyWith(clearProjectSlugs: true),
      );
    }
    widget.searchSession.addListener(_scheduleLoad);
    widget.roleController.addListener(_scheduleLoad);
    ListingActivityService.instance.load();
    PreferredStockService.instance.load();
    SavedSearchService.instance.load();
    _loadUserLocation();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationCenterRepository.instance.refresh(
        role: widget.roleController,
        isEnglish: widget.localeController.isEnglish,
      );
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.searchSession.removeListener(_scheduleLoad);
    widget.roleController.removeListener(_scheduleLoad);
    super.dispose();
  }

  bool get _isAgentPerspective => widget.roleController.isAgent;

  SearchFilters get _filters => widget.searchSession.filters;

  int _loadGen = 0;

  Future<void> _load() async {
    final gen = ++_loadGen;
    final firstLoad = _loading && _listings.isEmpty;
    if (firstLoad && mounted) setState(() => _loading = true);
    _searchService.invalidateCache();
    try {
      final filters = _filters;
      final list = await _repo.fetchPublished(
        filters: filters,
        coAgentEligibleOnly: _isAgentPerspective,
      );
      final nearMe = (_userLat != null && _userLng != null)
          ? sortByDistance(list, lat: _userLat!, lng: _userLng!)
          : <ListingPublic>[];
      final recent = ListingActivityService.instance.recentlyViewed(list);
      final preferred = _isAgentPerspective
          ? _sectionsBuilder.resolvePreferredStock(
              list,
              PreferredStockService.instance,
            )
          : <ListingPublic>[];
      final sections = _sectionsBuilder.build(
        all: list,
        sessionFilters: filters,
        isAgent: _isAgentPerspective,
        categorySlug: widget.searchSession.categorySlug,
        nearMe: nearMe,
        recentlyViewed: recent,
        preferredStock: preferred,
      );
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _listings = list;
        _sections = sections;
        _loading = false;
      });
      _checkSavedSearchAlerts(list);
    } catch (e) {
      if (!mounted || gen != _loadGen) return;
      final demo = DemoListingsFactory.cached;
      final nearMe = (_userLat != null && _userLng != null)
          ? sortByDistance(demo, lat: _userLat!, lng: _userLng!)
          : <ListingPublic>[];
      setState(() {
        _listings = demo;
        _sections = _sectionsBuilder.build(
          all: demo,
          sessionFilters: _filters,
          isAgent: _isAgentPerspective,
          categorySlug: widget.searchSession.categorySlug,
          nearMe: nearMe,
          recentlyViewed: ListingActivityService.instance.recentlyViewed(demo),
          preferredStock: _isAgentPerspective
              ? _sectionsBuilder.resolvePreferredStock(
                  demo,
                  PreferredStockService.instance,
                )
              : null,
        );
        _loading = false;
      });
      if (mounted) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.loadFailed)),
        );
      }
    }
  }

  Future<void> _checkSavedSearchAlerts(List<ListingPublic> list) async {
    final matches =
        await SavedSearchService.instance.checkNewMatches(listings: list);
    if (!mounted || matches.isEmpty) return;
    final s = AppStrings.of(context);
    final total = matches.fold<int>(0, (a, b) => a + b.matchCount);
    await SavedSearchService.instance
        .markListingsSeen(list.map((l) => l.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.savedSearchAlert(total)),
        action: SnackBarAction(
          label: s.viewAll,
          onPressed: () => context.push(
            '/saved-searches',
            extra: widget.searchSession,
          ),
        ),
      ),
    );
  }

  Future<void> _refreshNearMe() async {
    await _loadUserLocation();
    await _load();
  }

  void _openMapView() {
    setState(() {
      _mapView = true;
      _focusNearMeOnMap = true;
      _viewMode = HomeViewModeLi.map;
      _selectedId = null;
    });
    unawaited(_refreshNearMe());
  }

  List<ListingPublic> _mapSheetListings({ListingPublic? anchor}) {
    if (anchor != null && anchor.lat != null && anchor.lng != null) {
      return sortByProximityThenPrice(
        _listings,
        lat: anchor.lat!,
        lng: anchor.lng!,
        referencePrice: anchor.priceNet,
        excludeId: anchor.id,
      );
    }
    if (_userLat != null && _userLng != null) {
      return sortByProximityThenPrice(
        _listings,
        lat: _userLat!,
        lng: _userLng!,
      );
    }
    return _listings;
  }

  void _onFiltersChanged(SearchFilters filters) {
    widget.searchSession.setFilters(filters);
  }

  void _onPopularAreaTap(String slug) {
    final area = PopularAreas.bySlug(slug);
    final s = AppStrings.of(context);
    ListingNavigation.openArea(
      context,
      areaSlug: slug,
      title: area?.name(s.isEnglish) ?? slug,
      isAgent: _isAgentPerspective,
    );
  }

  void _onTransitLineTap(BangkokTransitLine line) {
    final s = AppStrings.of(context);
    ListingNavigation.openTransit(
      context,
      title: line.name(s.isEnglish),
      geoZoneSlugs: line.geoZoneSlugs,
      isAgent: _isAgentPerspective,
    );
  }

  void _openListing(ListingPublic item) {
    context.push(
      '/listing/${item.id}',
      extra: ListingRouteExtra(listing: item, isAgent: _isAgentPerspective),
    );
  }

  void _openSectionAll(HomeFeedSection section) {
    ListingNavigation.openSection(
      context,
      section: section,
      isAgent: _isAgentPerspective,
    );
  }

  void _openProjectFromSearch(String projectName, {String? projectSlug}) {
    ListingNavigation.openProject(
      context,
      projectName: projectName,
      projectSlug: projectSlug,
      isAgent: _isAgentPerspective,
    );
  }

  void _onPinPlaced(double lat, double lng) {
    final radius = _filters.radiusKm ?? kSearchPinRadiusDefaultKm;
    _onFiltersChanged(
      _filters.copyWith(
        pinLatitude: lat,
        pinLongitude: lng,
        radiusKm: radius,
      ),
    );
    setState(() => _pinPlacementMode = false);
  }

  Future<void> _openFilters() async {
    final result = await showSearchFilterSheet(
      context,
      initial: _filters,
    );
    if (result != null) _onFiltersChanged(result);
  }

  List<ListingPublic> _sameProject(ListingPublic item) {
    final slug = item.projectSlug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return _listings.where((l) => l.projectSlug == slug).toList();
    }
    final name = item.projectName?.trim();
    if (name == null || name.isEmpty) return [item];
    return _listings.where((l) => l.projectName == name).toList();
  }

  void _openProjectUnits(ListingPublic item) {
    ListingNavigation.openProjectUnits(
      context,
      projectName: item.projectName ?? item.localizedProjectName(AppStrings.of(context).isEnglish) ?? '',
      projectSlug: item.projectSlug,
      isAgent: _isAgentPerspective,
    );
  }

  ListingPublic? get _selected {
    if (_selectedId == null) return null;
    for (final l in _listings) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_mapView) return _buildMapView(context);
    return _buildBrowseView(context);
  }

  Widget _buildMapView(BuildContext context) {
    final s = AppStrings.of(context);
    final selected = _selected;
    final sheetListings = _mapSheetListings(anchor: selected);
    final topInset = PageSafeInsets.top(context);
    final mapTitle = '${s.mapSearchLabel} · ${sheetListings.length}';

    return AppMobileScaffold(
      safeBottomBody: false,
      backgroundColor: AppTheme.backgroundAlt,
      body: AdminMobileLayout.withInsets(
        context,
        Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListingsMap(
                    listings: _listings,
                    selectedId: _selectedId,
                    showPriceOnMarker: true,
                    fullBleed: true,
                    focusUserOnStart: _focusNearMeOnMap,
                    fabBottomPadding: selected != null ? 200 : 160,
                    pinLatitude: _filters.pinLatitude,
                    pinLongitude: _filters.pinLongitude,
                    radiusKm: _filters.radiusKm,
                    pinPlacementMode: _pinPlacementMode,
                    onPinPlaced: _onPinPlaced,
                    onListingTap: (l) => setState(() => _selectedId = l.id),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Material(
              elevation: 2,
              color: AppTheme.headerTint,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setState(() {
                              _mapView = false;
                              _focusNearMeOnMap = false;
                              _viewMode = HomeViewModeLi.list;
                              _selectedId = null;
                            }),
                            tooltip: s.backToBrowse,
                          ),
                          Expanded(
                            child: Text(
                              mapTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _focusNearMeOnMap = true);
                              unawaited(_refreshNearMe());
                            },
                            tooltip: s.searchNearByTitle,
                            icon: const Icon(Icons.near_me_outlined, size: 22),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LiLayout.pagePadding,
                        0,
                        LiLayout.pagePadding,
                        4,
                      ),
                      child: SmartSearchBar(
                        filters: _filters,
                        onFiltersChanged: _onFiltersChanged,
                        style: SearchBarStyle.livingInsider,
                        onMapSearch: null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LiLayout.pagePadding,
                        0,
                        LiLayout.pagePadding,
                        8,
                      ),
                      child: MapPinRadiusBar(
                        filters: _filters,
                        pinPlacementMode: _pinPlacementMode,
                        onPinPlacementModeChanged: (v) =>
                            setState(() => _pinPlacementMode = v),
                        onFiltersChanged: _onFiltersChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_loading && _listings.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: selected != null ? 0.32 : 0.22,
              minChildSize: 0.14,
              maxChildSize: 0.62,
              builder: (context, scrollController) {
                return Material(
                  elevation: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (selected != null) ...[
                        ListingCard(
                          listing: selected,
                          style: ListingCardStyle.list,
                          showCoAgentStrip: _isAgentPerspective,
                          onTap: () => _openListing(selected),
                        ),
                        Builder(
                          builder: (context) {
                            final units = _sameProject(selected);
                            if (units.length <= 1) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 12),
                              child: OutlinedButton.icon(
                                onPressed: () => _openProjectUnits(selected),
                                icon: const Icon(Icons.apartment_outlined, size: 18),
                                label: Text(
                                  s.seeProjectUnits(
                                    units.length - 1,
                                    selected.projectName ?? s.t('โครงการนี้', 'this project'),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(color: AppTheme.primary),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 20),
                        Text(
                          s.t('ทรัพย์ใกล้เคียง', 'Nearby listings'),
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ListingGrid(
                        items: sheetListings.take(25).toList(),
                        horizontalPadding: 12,
                        showCoAgentStrip: _isAgentPerspective,
                        onTapListing: (item) {
                          setState(() => _selectedId = item.id);
                          _openListing(item);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        ),
        bleedBottom: true,
      ),
    );
  }

  Widget _buildBrowseView(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.roleController,
        widget.searchSession,
      ]),
      builder: (context, _) {
        final filters = _filters;

        return AppMobileScaffold(
          backgroundColor: AppTheme.surfaceWarm,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: HomeBrowseLayout(
                    roleController: widget.roleController,
                    searchSession: widget.searchSession,
                    localeController: widget.localeController,
                    filters: filters,
                    listings: _listings,
                    sections: _sections,
                    isAgentPerspective: _isAgentPerspective,
                    onFiltersChanged: _onFiltersChanged,
                    onOpenFilters: _openFilters,
                    onOpenProfile: widget.onOpenProfile,
                    onOpenMapSearch: _openMapView,
                    onOpenNotifications: () => NotificationCenterSheet.show(
                      context,
                      roleController: widget.roleController,
                      localeController: widget.localeController,
                    ),
                    onTapListing: _openListing,
                    onViewAllSection: _openSectionAll,
                    onOpenProject: _openProjectFromSearch,
                    onAreaTap: _onPopularAreaTap,
                    onTransitLineTap: _onTransitLineTap,
                    selectedAreaSlug: null,
                    selectedTransitSlug: null,
                  ),
                ),
                if (_loading)
                  const Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
