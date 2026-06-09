import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/bangkok_projects.dart';
import '../../l10n/app_strings.dart';
import '../../models/search_filters.dart';
import '../../services/search_history_service.dart';
import '../../services/search_zone_catalog.dart';
import '../../theme/app_theme.dart';
import '../../utils/listing_navigation.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../widgets/search_filter_chips.dart';
import '../../widgets/search_zone_unified_tag_input.dart';

/// หน้าค้นหา — แท็กทำเล/สถานี/โครงการ + ประวัติ/เทรนด์ (ไม่มีหมวดติ๊ก)
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
  final _scroll = ScrollController();
  Set<String> _selLocation = {};
  Set<String> _selTransit = {};
  Set<String> _selProject = {};
  Set<String> _selEducation = {};
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _syncSelectionsFromFilters();
    SearchZoneCatalog.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncSelectionsFromFilters() {
    _selLocation = {...?widget.filters.geoZoneSlugs};
    _selTransit = {...?widget.filters.transitSlugs};
    _selProject = {};
    _selEducation = {...?widget.filters.educationSlugs};
  }

  int get _pendingZoneCount =>
      _selLocation.length + _selTransit.length + _selEducation.length;

  SearchFilters _draftFilters() => SearchFilters(
        geoZoneSlugs: _selLocation.isEmpty ? null : _selLocation.toList(),
        transitSlugs: _selTransit.isEmpty ? null : _selTransit.toList(),
        educationSlugs: _selEducation.isEmpty ? null : _selEducation.toList(),
        pinLatitude: widget.filters.pinLatitude,
        pinLongitude: widget.filters.pinLongitude,
        radiusKm: widget.filters.radiusKm,
      );

  void _onZoneSelectionChanged({
    required Set<String> geoZoneSlugs,
    required Set<String> transitSlugs,
    required Set<String> projectSlugs,
    required Set<String> educationSlugs,
  }) {
    setState(() {
      _selLocation = geoZoneSlugs;
      _selTransit = transitSlugs;
      _selProject = {};
      _selEducation = educationSlugs;
    });
  }

  void _onDraftChipsChanged(SearchFilters next) {
    setState(() {
      _selLocation = {...?next.geoZoneSlugs};
      _selTransit = {...?next.transitSlugs};
      _selProject = {};
      _selEducation = {...?next.educationSlugs};
    });
  }

  void _defaultOpenProject(String projectName, {String? projectSlug}) {
    ListingNavigation.openProject(
      context,
      projectName: projectName,
      projectSlug: projectSlug,
      isAgent: widget.isAgent,
    );
    context.pop();
  }

  void _openProject(String projectName, {String? projectSlug}) {
    (widget.onOpenProject ?? _defaultOpenProject)(
      projectName,
      projectSlug: projectSlug,
    );
  }

  void _onNearByTap() {
    final action = widget.onMapSearch;
    if (action == null) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _applyZoneSelections() {
    widget.onFiltersChanged(
      widget.filters.copyWith(
        geoZoneSlugs: _selLocation.isEmpty ? null : _selLocation.toList(),
        transitSlugs: _selTransit.isEmpty ? null : _selTransit.toList(),
        educationSlugs: _selEducation.isEmpty ? null : _selEducation.toList(),
        clearGeoZones: _selLocation.isEmpty,
        clearTransit: _selTransit.isEmpty,
        clearProjectSlugs: true,
        clearEducation: _selEducation.isEmpty,
      ),
    );
    context.pop();
  }

  Future<void> _loadHistory() async {
    final en = AppStrings.of(context).isEnglish;
    final h = await SearchHistoryService.instance.history(isEnglish: en);
    if (mounted) setState(() => _history = h);
  }

  Future<void> _pickQuery(String text) async {
    final trimmed = text.trim();
    if (trimmed.length < 2) return;

    final slug = SearchHistoryService.instance.resolveSlugFromLabel(trimmed);
    if (slug != null) {
      final project = BangkokProjects.bySlug(slug);
      if (project != null) {
        final en = AppStrings.of(context).isEnglish;
        final label = en ? project.nameEn : project.nameTh;
        await SearchHistoryService.instance.addProjectSlug(slug, label);
        await _loadHistory();
        if (!mounted) return;
        _openProject(project.nameTh, projectSlug: slug);
        return;
      }
    }

    await SearchHistoryService.instance.addQuery(trimmed);
    widget.onFiltersChanged(
      widget.filters.copyWith(query: text, clearQuery: text.isEmpty),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final draft = _draftFilters();

    return ConsumerPageShell(
      title: s.navHome,
      onBack: () => context.pop(),
      body: ListView(
        controller: _scroll,
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: 12,
          right: LiLayout.pagePadding,
          bottom: 24,
          addHomeIndicator: false,
        ),
        children: [
          if (draft.hasPinRadius) ...[
            SearchFilterChips(
              filters: draft,
              onFiltersChanged: _onDraftChipsChanged,
              padding: const EdgeInsets.only(bottom: 8),
            ),
          ],
          SearchZoneUnifiedTagInput(
            geoZoneSlugs: _selLocation,
            transitSlugs: _selTransit,
            projectSlugs: _selProject,
            educationSlugs: _selEducation,
            onSelectionChanged: _onZoneSelectionChanged,
            onHistoryChanged: _loadHistory,
            isAgent: widget.isAgent,
            onOpenProject: _openProject,
          ),
          const SizedBox(height: 16),
          _NearByCard(
            title: s.searchNearByTitle,
            subtitle: s.searchNearBySubtitle,
            onTap: widget.onMapSearch != null ? _onNearByTap : null,
          ),
          if (_pendingZoneCount > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _applyZoneSelections,
                child: Text(s.searchApplyZoneFilters(_pendingZoneCount)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionHeader(
            s.searchYourHistoryTitle,
            trailing: _history.isNotEmpty
                ? TextButton.icon(
                    onPressed: () async {
                      await SearchHistoryService.instance.clearHistory();
                      await _loadHistory();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(s.searchClearAll, style: const TextStyle(fontSize: 12)),
                  )
                : null,
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                s.searchHistoryEmpty,
                style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
              ),
            )
          else
            ..._history.take(SearchHistoryService.displayLimit).map(
                  (q) => _QueryTile(
                    icon: Icons.history,
                    title: q,
                    onTap: () => _pickQuery(q),
                  ),
                ),
          const SizedBox(height: 16),
          _sectionHeader(s.searchTrendsTitle),
          ...SearchHistoryService.instance.trends(isEnglish: s.isEnglish).map(
                (q) => _QueryTile(
                  icon: Icons.trending_up,
                  title: q,
                  onTap: () => _pickQuery(q),
                ),
              ),
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
