import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_listings_factory.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/listing_browse_sorter.dart';
import '../../widgets/listing_grid.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

enum _SavedSort { recent, recommended, priceHigh, priceLow }

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  _SavedSort _sort = _SavedSort.recent;
  bool _manageMode = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_refresh);
    FavoritesService.instance.load();
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<ListingPublic> _resolveSaved() {
    final order = FavoritesService.instance.orderedIds;
    final byId = {
      for (final l in DemoListingsFactory.cached) l.id: l,
    };
    return [
      for (final id in order)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  List<ListingPublic> _sorted(List<ListingPublic> items) {
    switch (_sort) {
      case _SavedSort.recent:
        return List<ListingPublic>.from(items.reversed);
      case _SavedSort.recommended:
        return ListingBrowseSorter.browseOrder(items);
      case _SavedSort.priceHigh:
        final list = List<ListingPublic>.from(items)
          ..sort((a, b) => b.priceNet.compareTo(a.priceNet));
        return list;
      case _SavedSort.priceLow:
        final list = List<ListingPublic>.from(items)
          ..sort((a, b) => a.priceNet.compareTo(b.priceNet));
        return list;
    }
  }

  void _exitManageMode() {
    setState(() {
      _manageMode = false;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll(List<ListingPublic> saved) {
    setState(() {
      if (_selected.length == saved.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(saved.map((l) => l.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final s = AppStrings.of(context);
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.savedListingsDeleteSelected(count)),
        content: Text(s.savedListingsDeleteConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FavoritesService.instance.removeMany(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedListingsRemoved)),
    );
    _exitManageMode();
  }

  String _sortLabel(AppStrings s) {
    switch (_sort) {
      case _SavedSort.recent:
        return s.savedListingsSortRecent;
      case _SavedSort.recommended:
        return s.sortRecommended;
      case _SavedSort.priceHigh:
        return s.sortPriceHighToLow;
      case _SavedSort.priceLow:
        return s.sortPriceLowToHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final saved = _sorted(_resolveSaved());

    return ConsumerPageShell(
      title: _manageMode && _selected.isNotEmpty
          ? '${s.savedListingsTitle} (${_selected.length})'
          : s.savedListingsTitle,
      onBack: () => context.pop(),
      safeBottomBody: false,
      actions: saved.isEmpty
          ? const []
          : _manageMode
              ? [
                  ConsumerHeaderTextButton(
                    label: _selected.length == saved.length
                        ? s.savedListingsDeselectAll
                        : s.savedListingsSelectAll,
                    onTap: () => _toggleSelectAll(saved),
                  ),
                  ConsumerHeaderTextButton(
                    label: s.cancel,
                    onTap: _exitManageMode,
                  ),
                ]
              : [
                  ConsumerHeaderTextButton(
                    label: s.savedListingsManage,
                    onTap: () => setState(() => _manageMode = true),
                  ),
                ],
      headerBottom: saved.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                LiLayout.pagePadding,
                0,
                LiLayout.pagePadding,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_sortLabel(s)),
                      const Icon(Icons.swap_vert, size: 14),
                    ],
                  ),
                  selected: true,
                  onSelected: (_) async {
                    final picked = await showModalBottomSheet<_SavedSort>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final mode in _SavedSort.values)
                              ListTile(
                                title: Text(_sortLabelFor(s, mode)),
                                trailing: _sort == mode
                                    ? Icon(Icons.check, color: AppTheme.primary)
                                    : null,
                                onTap: () => Navigator.pop(ctx, mode),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (picked != null) setState(() => _sort = picked);
                  },
                ),
              ),
            ),
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: AppTheme.primary.withOpacity(0.7)),
                    const SizedBox(height: 16),
                    Text(
                      s.savedListingsEmpty,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.savedListingsHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: ListingGrid(
                  items: saved,
                  shrinkWrap: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  selectionMode: _manageMode,
                  selectedIds: _selected,
                  onToggleSelect: _toggleSelect,
                  showFavorite: !_manageMode,
                  padding: PageSafeInsets.padLTRB(
                    context,
                    left: LiLayout.pagePadding,
                    top: LiLayout.pagePadding,
                    right: LiLayout.pagePadding,
                    bottom: _manageMode && _selected.isNotEmpty ? 88 : 16,
                    addHomeIndicator: false,
                  ),
                  onTapListing: (item) => context.push(
                    '/listing/${item.id}',
                    extra: ListingRouteExtra(listing: item),
                  ),
                  ),
                ),
                if (_manageMode && _selected.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      elevation: 8,
                      color: Colors.white,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: LivingBkkBrand.accentOrange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _deleteSelected,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(s.savedListingsDeleteSelected(
                                  _selected.length)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _sortLabelFor(AppStrings s, _SavedSort mode) {
    switch (mode) {
      case _SavedSort.recent:
        return s.savedListingsSortRecent;
      case _SavedSort.recommended:
        return s.sortRecommended;
      case _SavedSort.priceHigh:
        return s.sortPriceHighToLow;
      case _SavedSort.priceLow:
        return s.sortPriceLowToHigh;
    }
  }
}
