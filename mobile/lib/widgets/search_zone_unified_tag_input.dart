import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_zone_catalog_entry.dart';
import '../services/project_catalog.dart';
import '../services/search_history_service.dart';
import '../services/search_zone_catalog.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../utils/listing_navigation.dart';
import 'search_zone_suggestion_list.dart';
import 'typewriter_hint_label.dart';

/// ค้นหาแท็กทำเล/รถไฟฟ้า/โครงการ/สถานศึกษา — ไม่มีแท็บหมวดหรือ checkbox
class SearchZoneUnifiedTagInput extends StatefulWidget {
  const SearchZoneUnifiedTagInput({
    super.key,
    required this.geoZoneSlugs,
    required this.transitSlugs,
    required this.projectSlugs,
    required this.educationSlugs,
    required this.onSelectionChanged,
    this.maxListHeight,
    this.onHistoryChanged,
    this.isAgent = false,
    this.onOpenProject,
  });

  final Set<String> geoZoneSlugs;
  final Set<String> transitSlugs;
  final Set<String> projectSlugs;
  final Set<String> educationSlugs;
  final void Function({
    required Set<String> geoZoneSlugs,
    required Set<String> transitSlugs,
    required Set<String> projectSlugs,
    required Set<String> educationSlugs,
  }) onSelectionChanged;
  final double? maxListHeight;
  final VoidCallback? onHistoryChanged;
  final bool isAgent;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;

  @override
  State<SearchZoneUnifiedTagInput> createState() =>
      _SearchZoneUnifiedTagInputState();
}

class _SearchZoneUnifiedTagInputState extends State<SearchZoneUnifiedTagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<SearchZoneCatalogEntry> _suggestions = [];
  bool _catalogReady = false;
  bool _searchingOnline = false;
  Timer? _debounce;
  int _searchGen = 0;

  /// โครงการไม่ใช่แท็กที่เลือก — ไม่รวม projectSlugs
  Set<String> get _tagExcludeIds => {
        ...widget.geoZoneSlugs,
        ...widget.transitSlugs,
        ...widget.educationSlugs,
      };

  @override
  void initState() {
    super.initState();
    ProjectCatalog.instance.load();
    SearchZoneCatalog.instance.load().then((_) {
      if (mounted) setState(() => _catalogReady = true);
    });
    SearchZoneCatalog.instance.addListener(_onCatalogChanged);
    _controller.addListener(_onQueryChanged);
    _focus.addListener(_onFocusVisualChanged);
  }

  void _onFocusVisualChanged() => setState(() {});

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    SearchZoneCatalog.instance.removeListener(_onCatalogChanged);
    _controller.removeListener(_onQueryChanged);
    _focus.removeListener(_onFocusVisualChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    if (!_catalogReady) {
      setState(() {});
      return;
    }
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _searchingOnline = false;
      });
      return;
    }
    final gen = ++_searchGen;
    final local = SearchZoneCatalog.instance.search(
      q,
      excludeIds: _tagExcludeIds,
      limit: 15,
    );
    setState(() {
      _suggestions = local;
      _searchingOnline = q.length >= 2;
    });
    if (q.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final merged = await SearchZoneCatalog.instance.searchWithProjects(
        q,
        excludeIds: _tagExcludeIds,
        limit: 15,
      );
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _suggestions = merged;
        _searchingOnline = false;
      });
    });
  }

  void _emit({
    Set<String>? geoZoneSlugs,
    Set<String>? transitSlugs,
    Set<String>? projectSlugs,
    Set<String>? educationSlugs,
  }) {
    widget.onSelectionChanged(
      geoZoneSlugs: geoZoneSlugs ?? widget.geoZoneSlugs,
      transitSlugs: transitSlugs ?? widget.transitSlugs,
      projectSlugs: projectSlugs ?? const {},
      educationSlugs: educationSlugs ?? widget.educationSlugs,
    );
  }

  Future<void> _openProject(SearchZoneCatalogEntry entry) async {
    final s = AppStrings.of(context);
    final slug = entry.projectSlug ?? entry.id;
    final displayLabel = entry.label(s.isEnglish);
    await SearchHistoryService.instance.addProjectSlug(slug, displayLabel);
    if (!mounted) return;
    widget.onHistoryChanged?.call();
    _controller.clear();
    setState(() => _suggestions = []);
    _focus.unfocus();
    if (widget.onOpenProject != null) {
      widget.onOpenProject!(entry.titleTh, projectSlug: slug);
    } else {
      ListingNavigation.openProject(
        context,
        projectName: entry.titleTh,
        projectSlug: slug,
        isAgent: widget.isAgent,
      );
    }
  }

  void _addTagEntry(SearchZoneCatalogEntry entry) {
    final s = AppStrings.of(context);
    SearchHistoryService.instance.addQuery(entry.label(s.isEnglish));
    widget.onHistoryChanged?.call();
    switch (entry.category) {
      case 'location':
        _emit(geoZoneSlugs: {...widget.geoZoneSlugs, entry.id});
      case 'transit':
        _emit(transitSlugs: {...widget.transitSlugs, entry.id});
      case 'project':
        _openProject(entry);
        return;
      case 'education':
        _emit(educationSlugs: {...widget.educationSlugs, entry.id});
    }
    _controller.clear();
    setState(() => _suggestions = []);
    _focus.requestFocus();
  }

  void _onEntryTap(SearchZoneCatalogEntry entry) {
    if (entry.category == 'project') {
      _openProject(entry);
    } else {
      _addTagEntry(entry);
    }
  }

  void _removeEntry(SearchZoneCatalogEntry entry) {
    switch (entry.category) {
      case 'location':
        final next = Set<String>.from(widget.geoZoneSlugs)..remove(entry.id);
        _emit(geoZoneSlugs: next);
      case 'transit':
        final next = Set<String>.from(widget.transitSlugs)..remove(entry.id);
        _emit(transitSlugs: next);
      case 'project':
        break;
      case 'education':
        final next = Set<String>.from(widget.educationSlugs)..remove(entry.id);
        _emit(educationSlugs: next);
    }
  }

  List<SearchZoneCatalogEntry> get _selectedEntries {
    final catalog = SearchZoneCatalog.instance;
    final out = <SearchZoneCatalogEntry>[];
    for (final id in widget.geoZoneSlugs) {
      final e = catalog.byId(id);
      if (e != null) out.add(e);
    }
    for (final id in widget.transitSlugs) {
      final e = catalog.byId(id);
      if (e != null) out.add(e);
    }
    for (final id in widget.educationSlugs) {
      final e = catalog.byId(id);
      if (e != null) out.add(e);
    }
    return out;
  }

  SearchZoneCatalogEntry? get _firstProjectSuggestion {
    for (final e in _suggestions) {
      if (e.category == 'project') return e;
    }
    return null;
  }

  void _seeAllProjects() {
    final first = _firstProjectSuggestion;
    if (first != null) _openProject(first);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final selected = _selectedEntries;
    final popular = _catalogReady && _controller.text.trim().isEmpty
        ? SearchZoneCatalog.instance.popularEntries(
            excludeIds: _tagExcludeIds,
          )
        : const <SearchZoneCatalogEntry>[];

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((entry) {
              return InputChip(
                label: Text(
                  entry.label(s.isEnglish),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeEntry(entry),
                backgroundColor: AppTheme.primaryLight,
                side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        wrapWithTypewriterHint(
          controller: _controller,
          focusNode: _focus,
          hintStyle: TextStyle(
            fontSize: 14,
            color: p.textSecondary.withOpacity(0.85),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            decoration: InputDecoration(
              hintText: typewriterFieldHintText(s, _controller, _focus),
              hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.85)),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (_suggestions.isEmpty) return;
              final first = _suggestions.first;
              if (first.category == 'project') {
                _openProject(first);
              } else {
                _addTagEntry(first);
              }
            },
          ),
        ),
        if (!_catalogReady)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_controller.text.trim().isNotEmpty &&
            _suggestions.isEmpty &&
            !_searchingOnline)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              s.projectSearchNoResults,
              style: TextStyle(fontSize: 13, color: p.textSecondary),
            ),
          )
        else if (_searchingOnline)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SearchZoneSuggestionList(
            suggestions: _suggestions,
            query: _controller.text.trim(),
            onSelectTag: _addTagEntry,
            onOpenProject: _openProject,
            onSeeAllProjects:
                _firstProjectSuggestion != null ? _seeAllProjects : null,
          ),
        ] else if (popular.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              s.searchZonePopularTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popular.map((entry) {
              return ActionChip(
                label: Text(
                  entry.label(s.isEnglish),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _onEntryTap(entry),
                backgroundColor: p.surface,
                side: BorderSide(color: AppTheme.border),
              );
            }).toList(),
          ),
        ],
      ],
    );

    final maxH = widget.maxListHeight;
    if (maxH != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(child: body),
      );
    }

    return body;
  }
}
