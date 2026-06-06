import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/bangkok_transit_lines.dart';
import '../../data/bangkok_projects.dart';
import '../../data/popular_areas.dart';
import '../../l10n/app_strings.dart';
import '../../models/browse_list_route_extra.dart';
import '../../models/search_filters.dart';
import '../../models/search_suggestion.dart';
import '../../services/project_catalog.dart';
import '../../services/search_history_service.dart';
import '../../services/search_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../utils/geo_zone_match.dart';
import '../../utils/listing_navigation.dart';
import '../../utils/localized_content.dart';

enum _SearchCategoryTab { location, transit, project }

/// หน้าค้นหาแบบ LivingInsider — ประวัติ / เทรนด์ / หมวด / ทำleaฮิต
class SearchDiscoveryPage extends StatefulWidget {
  const SearchDiscoveryPage({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.isAgent = false,
    this.onOpenProject,
    this.onMapSearch,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final bool isAgent;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final VoidCallback? onMapSearch;

  @override
  State<SearchDiscoveryPage> createState() => _SearchDiscoveryPageState();
}

class _SearchDiscoveryPageState extends State<SearchDiscoveryPage> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _resultsScroll = ScrollController();
  final _search = SearchService();
  final _keyBtsMrt = GlobalKey();
  final _keyLocation = GlobalKey();
  final _keyRoad = GlobalKey();
  final _keyProject = GlobalKey();
  _SearchCategoryTab _tab = _SearchCategoryTab.location;
  SearchResultTab _liveTab = SearchResultTab.transit;
  List<String> _history = [];
  List<SearchSuggestion> _liveResults = [];
  Timer? _debounce;
  bool _searching = false;
  int _searchGen = 0;

  @override
  void initState() {
    super.initState();
    _query.text = widget.filters.query ?? '';
    ProjectCatalog.instance.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
      _focus.requestFocus();
      final q = _query.text.trim();
      if (q.isNotEmpty) _runLiveSearch(q);
    });
  }

  Future<void> _loadHistory() async {
    final en = AppStrings.of(context).isEnglish;
    final h = await SearchHistoryService.instance.history(isEnglish: en);
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _resultsScroll.dispose();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  bool _hasSection(SearchResultSection sec) {
    return _liveResults.any(
      (r) => r.section == sec && r.kind != SearchSuggestionKind.hint,
    );
  }

  void _jumpToLiveTab(SearchResultTab tab) {
    setState(() => _liveTab = tab);
    final key = switch (tab) {
      SearchResultTab.transit =>
        _hasSection(SearchResultSection.btsMrt) ? _keyBtsMrt : _keyRoad,
      SearchResultTab.location => _keyLocation,
      SearchResultTab.project => _keyProject,
    };
    _scrollToKey(key);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final text = _query.text.trim();
    if (text.isEmpty) {
      setState(() {
        _liveResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () => _runLiveSearch(text));
  }

  Future<void> _runLiveSearch(String text) async {
    final gen = ++_searchGen;
    final en = AppStrings.of(context).isEnglish;
    final items = await _search.suggest(text, isEnglish: en);
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _liveResults = items;
      _searching = false;
    });
  }

  void _onSuggestionTap(SearchSuggestion item) {
    switch (item.kind) {
      case SearchSuggestionKind.project:
        context.pop();
        if (widget.onOpenProject != null && item.projectName != null) {
          widget.onOpenProject!(item.projectName!, projectSlug: item.projectSlug);
        } else if (item.projectName != null) {
          ListingNavigation.openProjectUnits(
            context,
            projectName: item.projectName!,
            projectSlug: item.projectSlug,
            isAgent: widget.isAgent,
          );
        }
        return;
      case SearchSuggestionKind.location:
        context.pop();
        if (item.geoZoneSlugs != null && item.geoZoneSlugs!.isNotEmpty) {
          ListingNavigation.openTransit(
            context,
            title: item.title,
            geoZoneSlugs: item.geoZoneSlugs!,
            isAgent: widget.isAgent,
          );
        }
        return;
      case SearchSuggestionKind.listing:
        if (item.projectName != null) {
          context.pop();
          ListingNavigation.openProjectUnits(
            context,
            projectName: item.projectName!,
            projectSlug: item.projectSlug,
            isAgent: widget.isAgent,
          );
        }
        return;
      case SearchSuggestionKind.hint:
        _pickQuery(item.projectName ?? _query.text.trim());
        return;
    }
  }

  int get _liveProjectCount =>
      _liveResults.where((r) => r.tab == SearchResultTab.project).length;

  static const _sectionOrder = [
    SearchResultSection.btsMrt,
    SearchResultSection.location,
    SearchResultSection.road,
    SearchResultSection.shopping,
    SearchResultSection.hospital,
    SearchResultSection.education,
    SearchResultSection.project,
  ];

  String _sectionTitle(AppStrings s, SearchResultSection sec, int count) {
    switch (sec) {
      case SearchResultSection.btsMrt:
        return 'BTS/MRT';
      case SearchResultSection.location:
        return s.t('ทำเล', 'Location');
      case SearchResultSection.road:
        return s.t('ซอย/ถนน', 'Soi/Road');
      case SearchResultSection.shopping:
        return s.t('แหล่งช้อปปิ้ง', 'Shopping');
      case SearchResultSection.hospital:
        return s.t('โรงพยาบาล', 'Hospitals');
      case SearchResultSection.education:
        return s.t('สถานศึกษา', 'Schools');
      case SearchResultSection.project:
        return '${s.t('โครงการ', 'Projects')} ($count)';
    }
  }

  GlobalKey? _sectionAnchorKey(SearchResultSection sec) {
    return switch (sec) {
      SearchResultSection.btsMrt => _keyBtsMrt,
      SearchResultSection.location => _keyLocation,
      SearchResultSection.road => _keyRoad,
      SearchResultSection.project => _keyProject,
      _ => null,
    };
  }

  static const _nestSections = {
    SearchResultSection.btsMrt,
    SearchResultSection.location,
    SearchResultSection.road,
  };

  String _projectDedupeKey(SearchSuggestion p) =>
      p.projectSlug ?? p.projectName ?? p.title;

  bool _projectMatchesZones(SearchSuggestion project, List<String> zones) {
    if (zones.isEmpty) return false;
    if (project.projectSlug != null && project.projectSlug!.isNotEmpty) {
      for (final bp in ProjectCatalog.instance.projects) {
        if (bp.slug != project.projectSlug) continue;
        return listingMatchesGeoZones(
          slugs: zones,
          district: bp.district,
          projectName: bp.nameTh,
          title: bp.nameEn,
        );
      }
    }
    final hay = [
      project.title.toLowerCase(),
      project.projectName?.toLowerCase(),
    ].whereType<String>().join(' ');
    return zones.any((z) => _slugMatchesClient(z, hay));
  }

  bool _slugMatchesClient(String slug, String hay) {
    const hints = <String, List<String>>{
      'thonglor': ['ทองหล่อ', 'thong', 'ทรู', 'thonglor'],
      'asok': ['อโศก', 'asok'],
      'bangna': ['บางนา', 'bang na', 'bangna'],
      'sukhumvit': ['สุขุมวิท', 'sukhumvit'],
      'ari': ['อารีย์', 'ari'],
      'silom': ['สีลม', 'silom', 'สาทร'],
      'ladprao': ['ลาดพร้าว', 'ladprao'],
      'huai-khwang': ['ห้วยขวาง', 'huai khwang'],
      'rama-9': ['พระราม 9', 'rama 9'],
    };
    final keys = hints[slug] ?? [slug.replaceAll('-', ' ')];
    return keys.any(hay.contains);
  }

  List<String> _zonesForSection(
    SearchResultSection sec,
    List<SearchSuggestion> parents,
  ) {
    final zones = <String>{};
    for (final parent in parents) {
      if (parent.section != sec) continue;
      zones.addAll(parent.geoZoneSlugs ?? const []);
    }
    return zones.toList();
  }

  /// แสดงผลทั้งหมด — โครงการซ้อนใต้ BTS/ทำเล/ซอย ไม่แยกหมวดล่าง
  List<Widget> _phLiveResults(AppStrings s, AppPalette p) {
    final all =
        _liveResults.where((r) => r.kind != SearchSuggestionKind.hint).toList();
    if (all.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(s.projectSearchNoResults, style: TextStyle(color: p.textSecondary)),
        ),
      ];
    }

    final projects =
        all.where((r) => r.kind == SearchSuggestionKind.project).toList();
    final parents =
        all.where((r) => r.kind != SearchSuggestionKind.project).toList();

    final nestedKeys = <String>{};
    var projectAnchorUsed = false;
    final tiles = <Widget>[];

    for (final sec in _sectionOrder) {
      if (sec == SearchResultSection.project) continue;

      final group = parents.where((p) => p.section == sec).toList();
      final sectionZones = _zonesForSection(sec, group);
      final zoneProjects = projects
          .where((proj) => _projectMatchesZones(proj, sectionZones))
          .toList();

      if (group.isEmpty && zoneProjects.isEmpty) continue;

      final anchor = _sectionAnchorKey(sec);
      final header = Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          _sectionTitle(s, sec, group.length),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.textSecondary,
          ),
        ),
      );
      tiles.add(anchor != null ? KeyedSubtree(key: anchor, child: header) : header);

      for (final item in group) {
        tiles.add(
          _PhResultTile(
            item: item,
            isEnglish: s.isEnglish,
            onTap: () => _onSuggestionTap(item),
          ),
        );
      }

      if (zoneProjects.isNotEmpty && _nestSections.contains(sec)) {
        for (final proj in zoneProjects) {
          nestedKeys.add(_projectDedupeKey(proj));
        }
        final subsetHeader = Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4, left: 4),
          child: Text(
            s.t('โครงการในพื้นที่', 'Projects in this area'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
        );
        if (!projectAnchorUsed) {
          tiles.add(KeyedSubtree(key: _keyProject, child: subsetHeader));
          projectAnchorUsed = true;
        } else {
          tiles.add(subsetHeader);
        }
        for (final proj in zoneProjects) {
          tiles.add(
            _PhResultTile(
              item: proj,
              isEnglish: s.isEnglish,
              nested: true,
              onTap: () => _onSuggestionTap(proj),
            ),
          );
        }
      }
    }

    final orphans =
        projects.where((p) => !nestedKeys.contains(_projectDedupeKey(p))).toList();
    if (orphans.isNotEmpty) {
      final anchor = _sectionAnchorKey(SearchResultSection.project);
      final header = Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          _sectionTitle(s, SearchResultSection.project, orphans.length),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.textSecondary,
          ),
        ),
      );
      tiles.add(
        anchor != null && !projectAnchorUsed
            ? KeyedSubtree(key: anchor, child: header)
            : header,
      );
      for (final proj in orphans) {
        tiles.add(
          _PhResultTile(
            item: proj,
            isEnglish: s.isEnglish,
            onTap: () => _onSuggestionTap(proj),
          ),
        );
      }
    }

    return tiles;
  }

  void _apply(SearchFilters next, {String? queryText}) {
    if (queryText != null && queryText.trim().length >= 2) {
      SearchHistoryService.instance.addQuery(queryText.trim());
    }
    widget.onFiltersChanged(next);
  }

  void _pickQuery(String text) {
    _query.text = text;
    _apply(
      widget.filters.copyWith(query: text, clearQuery: text.isEmpty),
      queryText: text,
    );
    context.pop();
  }

  void _openArea(PopularArea area) {
    context.pop();
    ListingNavigation.openArea(
      context,
      areaSlug: area.slug,
      title: area.name(AppStrings.of(context).isEnglish),
      isAgent: widget.isAgent,
    );
  }

  void _openTransit(BangkokTransitLine line) {
    context.pop();
    ListingNavigation.openTransit(
      context,
      title: line.name(AppStrings.of(context).isEnglish),
      geoZoneSlugs: line.geoZoneSlugs,
      isAgent: widget.isAgent,
    );
  }

  void _openAllAreas() {
    final s = AppStrings.of(context);
    context.pop();
    ListingNavigation.openBrowse(
      context,
      BrowseListRouteExtra(
        title: s.searchPopularAreasTitle,
        mode: BrowseListMode.area,
        geoZoneSlugs: PopularAreas.all.map((a) => a.slug).toList(),
        isAgent: widget.isAgent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return ConsumerPageShell(
      title: s.navHome,
      onBack: () => context.pop(),
      headerBottom: ConsumerHeaderSearchField(
        controller: _query,
        focusNode: _focus,
        hint: s.searchDiscoveryHint,
        onChanged: (_) => _onQueryChanged(),
        onSubmitted: (v) => _pickQuery(v.trim()),
      ),
      body: ListView(
        controller: _resultsScroll,
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: 8,
          right: LiLayout.pagePadding,
          bottom: 24,
          addHomeIndicator: false,
        ),
        children: [
          if (_query.text.trim().length >= 2) ...[
            _PhSearchTabs(
              selected: _liveTab,
              projectCount: _liveProjectCount,
              s: s,
              p: p,
              onChanged: _jumpToLiveTab,
            ),
            const SizedBox(height: 8),
            if (_searching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(s.projectSearchLoading, style: TextStyle(color: p.textSecondary)),
                  ],
                ),
              )
            else if (_liveResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(s.projectSearchNoResults, style: TextStyle(color: p.textSecondary)),
              )
            else
              ..._phLiveResults(s, p),
            const SizedBox(height: 16),
          ] else ...[
            if (_history.isNotEmpty) ...[
              _sectionHeader(
                s.searchHistoryTitle,
                trailing: TextButton.icon(
                  onPressed: () async {
                    await SearchHistoryService.instance.clearHistory();
                    await _loadHistory();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(s.searchClearAll, style: const TextStyle(fontSize: 12)),
                ),
              ),
              ..._history.map(
                (q) => _QueryTile(
                  icon: Icons.history,
                  title: q,
                  onTap: () => _pickQuery(q),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _sectionHeader(s.searchTrendsTitle),
            ...SearchHistoryService.instance.trends(isEnglish: s.isEnglish).map(
                  (q) => _QueryTile(
                    icon: Icons.trending_up,
                    title: q,
                    onTap: () => _pickQuery(q),
                  ),
                ),
            const SizedBox(height: 20),
            _sectionHeader(s.searchByCategoryTitle),
            _NearByCard(
              title: s.searchNearByTitle,
              subtitle: s.searchNearBySubtitle,
              onTap: widget.onMapSearch,
            ),
            const SizedBox(height: 12),
            _CategoryTabs(
              selected: _tab,
              s: s,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 12),
            if (_tab == _SearchCategoryTab.location) ...[
            _sectionHeader(
              s.searchPopularAreasTitle,
              trailing: TextButton(
                onPressed: _openAllAreas,
                child: Text(s.viewAll, style: TextStyle(color: p.primary)),
              ),
            ),
            ...PopularAreas.all.take(8).map(
                  (area) => _AreaListTile(
                    area: area,
                    isEnglish: s.isEnglish,
                    onTap: () => _openArea(area),
                  ),
                ),
          ] else if (_tab == _SearchCategoryTab.transit) ...[
            ...BangkokTransitLines.all.map(
              (line) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: line.color.withOpacity(0.2),
                  child: Icon(Icons.train, color: line.color, size: 20),
                ),
                title: Text(line.name(s.isEnglish), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(line.stations(s.isEnglish), style: TextStyle(fontSize: 12, color: p.textSecondary)),
                onTap: () => _openTransit(line),
              ),
            ),
            ] else ...[
              ...BangkokProjects.all.take(12).map(
                    (project) => ListTile(
                      leading: Icon(Icons.apartment, color: p.primary),
                      title: Text(project.displayBilingual, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        project.bts ?? project.district,
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      onTap: () {
                        context.pop();
                        if (widget.onOpenProject != null) {
                          widget.onOpenProject!(project.nameTh, projectSlug: project.slug);
                        } else {
                          ListingNavigation.openProjectUnits(
                            context,
                            projectName: project.nameTh,
                            projectSlug: project.slug,
                            isAgent: widget.isAgent,
                          );
                        }
                      },
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _PhSearchTabs extends StatelessWidget {
  const _PhSearchTabs({
    required this.selected,
    required this.projectCount,
    required this.s,
    required this.p,
    required this.onChanged,
  });

  final SearchResultTab selected;
  final int projectCount;
  final AppStrings s;
  final AppPalette p;
  final ValueChanged<SearchResultTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('BTS/MRT', SearchResultTab.transit),
        _tab(s.searchTabLocation, SearchResultTab.location),
        _tab(
          '${s.searchTabProject}${projectCount > 0 ? ' ($projectCount)' : ''}',
          SearchResultTab.project,
        ),
      ],
    );
  }

  Widget _tab(String label, SearchResultTab tab) {
    final active = selected == tab;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? p.primary : p.textSecondary,
                ),
              ),
            ),
            Container(
              height: 2,
              color: active ? p.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhResultTile extends StatelessWidget {
  const _PhResultTile({
    required this.item,
    required this.isEnglish,
    required this.onTap,
    this.nested = false,
  });

  final SearchSuggestion item;
  final bool isEnglish;
  final VoidCallback onTap;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isProject = item.kind == SearchSuggestionKind.project;

    Widget leading;
    if (isProject) {
      leading = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.border.withOpacity(0.5)),
        ),
        child: Icon(Icons.apartment, color: p.primary, size: 22),
      );
    } else {
      IconData icon;
      switch (item.section) {
        case SearchResultSection.btsMrt:
          icon = Icons.train;
          break;
        case SearchResultSection.road:
          icon = Icons.add_road;
          break;
        case SearchResultSection.shopping:
          icon = Icons.shopping_bag_outlined;
          break;
        case SearchResultSection.hospital:
          icon = Icons.local_hospital_outlined;
          break;
        case SearchResultSection.education:
          icon = Icons.school_outlined;
          break;
        default:
          icon = Icons.place;
      }
      leading = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1A73E8), size: 22),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(nested ? 20 : 0, 8, 0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            if (isProject && item.propertyTypeLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                '${item.propertyTypeLabel}...',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueryTile extends StatelessWidget {
  const _QueryTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

class _NearByCard extends StatelessWidget {
  const _NearByCard({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F8F0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.map_outlined, size: 48, color: AppTheme.primary.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selected,
    required this.s,
    required this.onChanged,
  });

  final _SearchCategoryTab selected;
  final AppStrings s;
  final ValueChanged<_SearchCategoryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(s.searchTabLocation, _SearchCategoryTab.location),
          const SizedBox(width: 8),
          _chip(s.searchTabTransit, _SearchCategoryTab.transit),
          const SizedBox(width: 8),
          _chip(s.searchTabProject, _SearchCategoryTab.project),
        ],
      ),
    );
  }

  Widget _chip(String label, _SearchCategoryTab tab) {
    final active = selected == tab;
    return FilterChip(
      selected: active,
      showCheckmark: false,
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      selectedColor: const Color(0xFFD1FAE5),
      side: BorderSide(color: active ? const Color(0xFF059669) : AppTheme.border),
      onSelected: (_) => onChanged(tab),
    );
  }
}

class _AreaListTile extends StatelessWidget {
  const _AreaListTile({
    required this.area,
    required this.isEnglish,
    required this.onTap,
  });

  final PopularArea area;
  final bool isEnglish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(area.imageUrl),
        radius: 22,
      ),
      title: Text(area.name(isEnglish), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(area.subtitle(isEnglish), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      onTap: onTap,
    );
  }
}
