import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/bangkok_project_meta.dart';
import '../../data/bangkok_projects.dart';
import '../../data/demo_listings_factory.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../models/listing_transaction_types.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/localized_content.dart';
import '../../utils/listing_browse_sorter.dart';
import '../../utils/listing_navigation.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/listings_map.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

enum _ProjectTx { all, rent, sale }

enum _ProjectSort { recommended, highToLow, lowToHigh }

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectSlug, this.isAgent = false});

  final String projectSlug;
  final bool isAgent;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _repo = ListingRepository();
  BangkokProject? _project;
  List<ListingPublic> _units = [];
  bool _loading = true;
  _ProjectTx _tx = _ProjectTx.all;
  _ProjectSort _sort = _ProjectSort.recommended;

  @override
  void initState() {
    super.initState();
    _project = BangkokProjects.bySlug(widget.projectSlug) ??
        BangkokProjectMeta.findProject(widget.projectSlug);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _repo.fetchPublished();
      _units = _filterUnits(all);
    } catch (_) {
      _units = _filterUnits(DemoListingsFactory.cached);
    }
    if (_project == null && _units.isNotEmpty) {
      _project = BangkokProjectMeta.findProject(_units.first.projectName);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<ListingPublic> _filterUnits(List<ListingPublic> all) {
    return all.where((l) {
      if (l.projectSlug == widget.projectSlug) return true;
      final p = _project;
      if (p != null && l.projectName == p.nameTh) return true;
      return false;
    }).toList();
  }

  List<ListingPublic> get _visible {
    var list = List<ListingPublic>.from(_units);
    if (_tx == _ProjectTx.rent) {
      list = list.where((l) => l.listingType == 'rent').toList();
    } else if (_tx == _ProjectTx.sale) {
      list = list
          .where((l) => ListingTransactionTypes.matchesBrowseFilter('sale', l.listingType))
          .toList();
    }
    switch (_sort) {
      case _ProjectSort.recommended:
        return ListingBrowseSorter.browseOrder(list);
      case _ProjectSort.highToLow:
        list.sort((a, b) => b.priceNet.compareTo(a.priceNet));
        return list;
      case _ProjectSort.lowToHigh:
        list.sort((a, b) => a.priceNet.compareTo(b.priceNet));
        return list;
    }
  }

  void _openTagBrowse(String label, List<String> geoSlugs) {
    ListingNavigation.openTag(
      context,
      tagLabel: label,
      geoZoneSlugs: geoSlugs,
      isAgent: widget.isAgent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = _project;
    final meta = BangkokProjectMeta.forProject(p?.nameTh);
    final en = s.isEnglish;
    final title = p?.displayBilingual ?? widget.projectSlug;
    final visible = _visible;

    return ConsumerPageShell(
      title: title,
      onBack: () => context.pop(),
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
                  if (p != null) ...[
                    if (p.bts != null)
                      Text(
                        p.bts!,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${p.district} · ${meta.yearBuilt + (en ? 0 : 543)}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (p.bts != null)
                          ActionChip(
                            label: Text(p.bts!),
                            onPressed: () {
                              final slug = p.geoZoneId ?? p.slug;
                              _openTagBrowse(p.bts!, [slug]);
                            },
                          ),
                        ActionChip(
                          label: Text(p.district),
                          onPressed: () {
                            _openTagBrowse(
                              p.district,
                              p.geoZoneId != null ? [p.geoZoneId!] : [],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: visible.isNotEmpty
                            ? ListingsMap(listings: visible.take(20).toList())
                            : Container(color: AppTheme.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    s.projectUnitsAvailable(visible.length),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(s.rent),
                          selected: _tx == _ProjectTx.rent,
                          onSelected: (_) => setState(() => _tx = _ProjectTx.rent),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: Text(s.listingTypeSale),
                          selected: _tx == _ProjectTx.sale,
                          onSelected: (_) => setState(() => _tx = _ProjectTx.sale),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: Text(s.demandFilterAll),
                          selected: _tx == _ProjectTx.all,
                          onSelected: (_) => setState(() => _tx = _ProjectTx.all),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_sortLabel(s)),
                              const Icon(Icons.swap_vert, size: 14),
                            ],
                          ),
                          selected: true,
                          onSelected: (_) => setState(() {
                            _sort = switch (_sort) {
                              _ProjectSort.recommended => _ProjectSort.highToLow,
                              _ProjectSort.highToLow => _ProjectSort.lowToHigh,
                              _ProjectSort.lowToHigh => _ProjectSort.recommended,
                            };
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text(s.noListings)),
                    )
                  else ...[
                    if (_sort == _ProjectSort.recommended && visible.length > 4) ...[
                      Text(
                        s.browseRecommendedTop,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ...visible.take(4).map(_unitCard),
                      const SizedBox(height: 12),
                      Text(
                        s.browseRecentlyUpdated,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ...visible.skip(4).map(_unitCard),
                    ] else
                      ...visible.map(_unitCard),
                  ],
                ],
              ),
            ),
    );
  }

  String _sortLabel(AppStrings s) {
    switch (_sort) {
      case _ProjectSort.highToLow:
        return s.sortPriceHighToLow;
      case _ProjectSort.lowToHigh:
        return s.sortPriceLowToHigh;
      case _ProjectSort.recommended:
        return s.sortRecommended;
    }
  }

  Widget _unitCard(ListingPublic item) {
    final s = AppStrings.of(context);
    final currency = NumberFormat.currency(
      locale: s.isEnglish ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListingCard(
        listing: item,
        style: ListingCardStyle.feed,
        showCoAgentStrip: widget.isAgent,
        onTap: () => ListingNavigation.openListing(
          context,
          listing: item,
          isAgent: widget.isAgent,
        ),
      ),
    );
  }
}
