import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../models/search_filters.dart';
import '../../services/listing_repository.dart';
import '../../services/search_service.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../widgets/home_search_strip.dart';
import '../../widgets/listing_grid.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/map_pin_radius_bar.dart';
import '../../widgets/smart_search_bar.dart';
import '../../utils/geo_distance.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/app_mobile_scaffold.dart';

/// แท็บแผนที่ — ค้นหาทรัพย์บนแผนที่โดยเฉพาะ
class MapSearchPage extends StatefulWidget {
  const MapSearchPage({
    super.key,
    required this.roleController,
    required this.searchSession,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final _repo = ListingRepository();
  final _searchService = SearchService();
  List<ListingPublic> _listings = [];
  bool _loading = true;
  String? _selectedId;
  bool _focusNearMeOnMap = true;
  bool _pinPlacementMode = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    widget.searchSession.addListener(_load);
    widget.roleController.addListener(_load);
    unawaited(_bootstrapNearMe());
  }

  Future<void> _bootstrapNearMe() async {
    await _loadUserLocation();
    await _load();
  }

  @override
  void dispose() {
    widget.searchSession.removeListener(_load);
    widget.roleController.removeListener(_load);
    super.dispose();
  }

  bool get _isAgent => widget.roleController.isAgent;

  SearchFilters _effectiveFilters() {
    var f = widget.searchSession.filters;
    final slug = widget.searchSession.categorySlug;
    if (slug != null) {
      final cat = PropertyCatalog.bySlug(slug);
      if (cat != null) {
        f = f.copyWith(propertyType: cat.slug);
      }
    } else {
      f = f.copyWith(clearPropertyType: true);
    }
    return f;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    _searchService.invalidateCache();
    try {
      final list = await _repo.fetchPublished(
        filters: _effectiveFilters(),
        coAgentEligibleOnly: _isAgent,
      );
      setState(() {
        _listings = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  ListingPublic? get _selected {
    if (_selectedId == null) return null;
    for (final l in _listings) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  List<ListingPublic> _sheetListings({ListingPublic? anchor}) {
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

  void _openListing(ListingPublic item) {
    context.push(
      '/listing/${item.id}',
      extra: ListingRouteExtra(listing: item, isAgent: _isAgent),
    );
  }

  void _onPinPlaced(double lat, double lng) {
    final f = widget.searchSession.filters;
    final radius = f.radiusKm ?? kSearchPinRadiusDefaultKm;
    widget.searchSession.setFilters(
      f.copyWith(
        pinLatitude: lat,
        pinLongitude: lng,
        radiusKm: radius,
      ),
    );
    setState(() => _pinPlacementMode = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.searchSession,
        widget.roleController,
      ]),
      builder: (context, _) {
        final s = AppStrings.of(context);
        final topInset = PageSafeInsets.top(context);
        final selected = _selected;
        final filters = widget.searchSession.filters;
        final sheetListings = _sheetListings(anchor: selected);
        final headerTitle = s.mapListingCount(sheetListings.length);

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
                        fabBottomPadding: 160,
                        pinLatitude: filters.pinLatitude,
                        pinLongitude: filters.pinLongitude,
                        radiusKm: filters.radiusKm,
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
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            LiLayout.pagePadding,
                            6,
                            LiLayout.pagePadding,
                            0,
                          ),
                          child: SmartSearchBar(
                            filters: widget.searchSession.filters,
                            onFiltersChanged: widget.searchSession.setFilters,
                            style: SearchBarStyle.livingInsider,
                          ),
                        ),
                        HomeSearchStrip(
                          session: widget.searchSession,
                          onCategoryTap: (_) => _load(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            LiLayout.pagePadding,
                            0,
                            LiLayout.pagePadding,
                            4,
                          ),
                          child: MapPinRadiusBar(
                            filters: filters,
                            pinPlacementMode: _pinPlacementMode,
                            onPinPlacementModeChanged: (v) =>
                                setState(() => _pinPlacementMode = v),
                            onFiltersChanged: widget.searchSession.setFilters,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  headerTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => _focusNearMeOnMap = true);
                                  unawaited(_bootstrapNearMe());
                                },
                                tooltip: s.searchNearByTitle,
                                icon: const Icon(Icons.near_me_outlined, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_loading && _listings.isNotEmpty)
                DraggableScrollableSheet(
                  initialChildSize: 0.22,
                  minChildSize: 0.14,
                  maxChildSize: 0.55,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ListingGrid(
                        scrollController: scrollController,
                        items: sheetListings.take(20).toList(),
                        horizontalPadding: 12,
                        shrinkWrap: false,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          24 + PageSafeInsets.bottom(context),
                        ),
                        showCoAgentStrip: _isAgent,
                        onTapListing: _openListing,
                      ),
                    );
                  },
                ),
            ],
            ),
            bleedBottom: true,
          ),
        );
      },
    );
  }
}
