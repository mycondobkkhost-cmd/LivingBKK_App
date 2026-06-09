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
import '../../services/project_catalog.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/localized_content.dart';
import '../../utils/listing_browse_sorter.dart';
import '../../utils/listing_navigation.dart';
import '../../utils/nearby_projects.dart';
import '../../widgets/listing_grid.dart';
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
    ProjectCatalog.instance.load();
    _project = ProjectCatalog.instance.bySlug(widget.projectSlug) ??
        BangkokProjects.bySlug(widget.projectSlug) ??
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

    final currency = NumberFormat.currency(
      locale: en ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );

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
                  top: 0,
                  right: LiLayout.pagePadding,
                  bottom: LiLayout.pagePadding,
                  addHomeIndicator: false,
                ),
                children: [
                  if (p != null) ...[
                    _ProjectHeroHeader(
                      project: p,
                      meta: meta,
                      title: title,
                      unitCount: _units.length,
                      units: _units,
                      isEnglish: en,
                      currency: currency,
                      strings: s,
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
                      ListingGrid(
                        items: visible.take(4).toList(),
                        showCoAgentStrip: widget.isAgent,
                        onTapListing: _openUnit,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.browseRecentlyUpdated,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ListingGrid(
                        items: visible.skip(4).toList(),
                        showCoAgentStrip: widget.isAgent,
                        onTapListing: _openUnit,
                      ),
                    ] else
                      ListingGrid(
                        items: visible,
                        showCoAgentStrip: widget.isAgent,
                        onTapListing: _openUnit,
                      ),
                  ],
                  if (p != null) ...[
                    const SizedBox(height: 24),
                    _NearbyProjectsSection(
                      origin: p,
                      isAgent: widget.isAgent,
                      isEnglish: en,
                      strings: s,
                    ),
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

  void _openUnit(ListingPublic item) {
    ListingNavigation.openListing(
      context,
      listing: item,
      isAgent: widget.isAgent,
    );
  }
}

class _ProjectHeroHeader extends StatelessWidget {
  const _ProjectHeroHeader({
    required this.project,
    required this.meta,
    required this.title,
    required this.unitCount,
    required this.units,
    required this.isEnglish,
    required this.currency,
    required this.strings,
  });

  final BangkokProject project;
  final ProjectMeta meta;
  final String title;
  final int unitCount;
  final List<ListingPublic> units;
  final bool isEnglish;
  final NumberFormat currency;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final rentPrices = units
        .where((u) => u.listingType == 'rent')
        .map((u) => u.priceNet)
        .toList();
    final salePrices = units
        .where(
          (u) =>
              ListingTransactionTypes.matchesBrowseFilter('sale', u.listingType),
        )
        .map((u) => u.priceNet)
        .toList();
    final minRent =
        rentPrices.isEmpty ? null : rentPrices.reduce((a, b) => a < b ? a : b);
    final minSale =
        salePrices.isEmpty ? null : salePrices.reduce((a, b) => a < b ? a : b);
    final year = meta.yearBuilt + (isEnglish ? 0 : 543);
    final imageUrl = 'https://picsum.photos/seed/${project.slug}/800/400';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.primary),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (project.bts != null)
                    Text(
                      project.bts!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        strings.projectUnitsAvailable(unitCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (minRent != null)
                        Text(
                          strings.projectStatRentFrom(currency.format(minRent)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (minSale != null)
                        Text(
                          strings.projectStatSaleFrom(currency.format(minSale)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        '${project.district} · $year',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyProjectsSection extends StatelessWidget {
  const _NearbyProjectsSection({
    required this.origin,
    required this.isAgent,
    required this.isEnglish,
    required this.strings,
  });

  final BangkokProject origin;
  final bool isAgent;
  final bool isEnglish;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final hits = nearbyProjects(origin: origin);
    if (hits.isEmpty) return const SizedBox.shrink();

    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.projectNearbyTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(12),
          color: p.surface,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < hits.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppTheme.border),
                _NearbyProjectRow(
                  hit: hits[i],
                  isEnglish: isEnglish,
                  distanceLabel: strings.projectNearbyDistanceKm(hits[i].distanceKm),
                  onTap: () => ListingNavigation.openProject(
                    context,
                    projectName: hits[i].project.nameTh,
                    projectSlug: hits[i].project.slug,
                    isAgent: isAgent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NearbyProjectRow extends StatelessWidget {
  const _NearbyProjectRow({
    required this.hit,
    required this.isEnglish,
    required this.distanceLabel,
    required this.onTap,
  });

  final NearbyProjectHit hit;
  final bool isEnglish;
  final String distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final project = hit.project;
    final title = isEnglish ? project.nameEn : project.nameTh;
    final subtitle = project.bts ?? project.district;
    final imageUrl = 'https://picsum.photos/seed/${project.slug}/120/120';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.primaryLight,
                  child: Icon(Icons.apartment, color: AppTheme.primary, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              distanceLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
