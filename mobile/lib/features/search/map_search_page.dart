import 'package:flutter/material.dart';
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
import '../../widgets/listing_card.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/search_filter_sheet.dart';
import '../../widgets/smart_search_bar.dart';
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

  @override
  void initState() {
    super.initState();
    widget.searchSession.addListener(_load);
    widget.roleController.addListener(_load);
    _load();
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

  void _openListing(ListingPublic item) {
    context.push(
      '/listing/${item.id}',
      extra: ListingRouteExtra(listing: item, isAgent: _isAgent),
    );
  }

  Future<void> _openFilters() async {
    final result = await showSearchFilterSheet(
      context,
      initial: _effectiveFilters(),
    );
    if (result != null) widget.searchSession.setFilters(result);
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
        return AppMobileScaffold(
          backgroundColor: AppTheme.backgroundAlt,
          body: Stack(
            children: [
              Positioned.fill(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListingsMap(
                        listings: _listings,
                        selectedId: _selectedId,
                        showPriceOnMarker: true,
                        onListingTap: (l) {
                          setState(() => _selectedId = l.id);
                          _openListing(l);
                        },
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Material(
                  elevation: 2,
                  color: Colors.white,
                  child: SafeArea(
                    bottom: false,
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
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              Text(
                                s.mapListingCount(_listings.length),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _openFilters,
                                icon: const Icon(Icons.tune, size: 18),
                                label: Text(s.filters, style: TextStyle(fontSize: 12)),
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
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: _listings.length.clamp(0, 20),
                        itemBuilder: (context, i) {
                          final item = _listings[i];
                          return ListingCard(
                            listing: item,
                            style: ListingCardStyle.list,
                            showCoAgentStrip: _isAgent,
                            onTap: () => _openListing(item),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
