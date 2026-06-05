import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import '../services/search_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'search_filter_sheet.dart';

enum SearchBarStyle { standard, livingInsider, airbnb }

class SmartSearchBar extends StatefulWidget {
  const SmartSearchBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.style = SearchBarStyle.standard,
    this.onMapSearch,
    this.onOpenFilters,
    this.onOpenProject,
  });

  final SearchFilters filters;
  final void Function(SearchFilters filters) onFiltersChanged;
  final SearchBarStyle style;
  final VoidCallback? onMapSearch;
  final VoidCallback? onOpenFilters;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _search = SearchService();
  Timer? _debounce;
  Timer? _parseDebounce;
  Timer? _queryApplyDebounce;
  List<SearchSuggestion> _suggestions = [];
  List<SearchPreviewItem> _preview = [];
  Map<String, dynamic> _parsedFilters = {};
  bool _showSuggestions = false;
  bool _showNlpPreview = false;
  bool _parsing = false;

  bool? _lastIsEnglish;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final en = AppStrings.of(context).isEnglish;
    if (_lastIsEnglish != null && _lastIsEnglish != en) {
      _refreshForLocale(en);
    }
    _lastIsEnglish = en;
  }

  Future<void> _refreshForLocale(bool isEnglish) async {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      final items = await _search.suggest(q, isEnglish: isEnglish);
      if (mounted) setState(() => _suggestions = items);
    }
    if (q.length >= 3) {
      final result = await _search.parseQuery(q, isEnglish: isEnglish);
      if (mounted) {
        setState(() {
          _parsedFilters = result.filters;
          _preview = result.preview;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.filters.query ?? '';
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted) {
        setState(() {
          _showSuggestions = false;
          _showNlpPreview = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SmartSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.query != widget.filters.query &&
        widget.filters.query != _controller.text &&
        !_focus.hasFocus) {
      _controller.text = widget.filters.query ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _parseDebounce?.cancel();
    _queryApplyDebounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply(SearchFilters next) {
    _search.invalidateCache();
    widget.onFiltersChanged(next);
  }

  Future<void> _runParse(String value) async {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      if (!mounted) return;
      setState(() {
        _showNlpPreview = false;
        _preview = [];
        _parsedFilters = {};
        _parsing = false;
      });
      return;
    }

    setState(() => _parsing = true);
    final isEnglish = AppStrings.of(context).isEnglish;
    final result = await _search.parseQuery(trimmed, isEnglish: isEnglish);
    if (!mounted) return;
    setState(() {
      _parsedFilters = result.filters;
      _preview = result.preview;
      _showNlpPreview = _focus.hasFocus && result.preview.isNotEmpty;
      _parsing = false;
    });
  }

  void _scheduleQueryApply(String value) {
    _queryApplyDebounce?.cancel();
    _queryApplyDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _apply(widget.filters.copyWith(
        query: value.trim().isEmpty ? null : value.trim(),
        clearQuery: value.trim().isEmpty,
      ));
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _parseDebounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _showSuggestions = false;
        _showNlpPreview = false;
        _suggestions = [];
        _preview = [];
      });
      _scheduleQueryApply(value);
      return;
    }

    _scheduleQueryApply(value);

    _parseDebounce = Timer(const Duration(milliseconds: 450), () {
      _runParse(value);
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final isEnglish = AppStrings.of(context).isEnglish;
      final items = await _search.suggest(value, isEnglish: isEnglish);
      if (!mounted) return;
      setState(() {
        _suggestions = items;
        _showSuggestions = _focus.hasFocus && items.isNotEmpty;
      });
    });
  }

  void _applyParsedFilters() {
    final next = _search.mergeParsed(
      current: widget.filters,
      parsed: _parsedFilters,
      queryText: _controller.text,
    );
    setState(() {
      _showNlpPreview = false;
      _showSuggestions = false;
    });
    _focus.unfocus();
    _apply(next);
  }

  void _clearParsed() {
    _controller.clear();
    setState(() {
      _showNlpPreview = false;
      _preview = [];
      _parsedFilters = {};
    });
    _apply(const SearchFilters());
  }

  void _onSuggestionTap(SearchSuggestion s) {
    if (s.kind == SearchSuggestionKind.project &&
        s.projectName != null &&
        widget.onOpenProject != null) {
      setState(() {
        _showSuggestions = false;
        _showNlpPreview = false;
      });
      _focus.unfocus();
      widget.onOpenProject!(s.projectName!, projectSlug: s.projectSlug);
      return;
    }

    var next = widget.filters.copyWith(query: _controller.text.trim());
    switch (s.kind) {
      case SearchSuggestionKind.project:
        if (s.projectName != null && widget.onOpenProject != null) {
          widget.onOpenProject!(s.projectName!, projectSlug: s.projectSlug);
          return;
        }
        next = next.copyWith(
          projectName: s.projectName,
          clearProject: s.projectName == null,
        );
        if (s.projectName != null) {
          _controller.text = s.projectName!;
        }
        break;
      case SearchSuggestionKind.location:
        next = next.copyWith(geoZoneSlugs: s.geoZoneSlugs);
        break;
      case SearchSuggestionKind.listing:
      case SearchSuggestionKind.hint:
        if (s.projectName != null) {
          next = next.copyWith(projectName: s.projectName);
          _controller.text = s.projectName!;
        }
        break;
    }
    setState(() {
      _showSuggestions = false;
      _showNlpPreview = false;
    });
    _focus.unfocus();
    _apply(next);
  }

  Future<void> _openFilters() async {
    final result = await showSearchFilterSheet(
      context,
      initial: widget.filters,
    );
    if (result != null) _apply(result);
  }

  InputDecoration _searchDecoration(AppStrings s) {
    final isLi = widget.style == SearchBarStyle.livingInsider;
    return InputDecoration(
      hintText: s.searchHintProjects,
      hintStyle: TextStyle(
        fontSize: isLi ? 14 : null,
        color: AppTheme.textSecondary.withOpacity(0.9),
      ),
      filled: true,
      fillColor: isLi ? LiLayout.searchFill : AppTheme.backgroundAlt,
      prefixIcon: Icon(
        Icons.search,
        color: isLi ? AppTheme.primary : AppTheme.textSecondary,
        size: isLi ? 22 : 24,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isLi ? 10 : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isLi ? AppTheme.radiusPill : AppTheme.radiusMd),
        borderSide: BorderSide(color: isLi ? AppTheme.border : AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isLi ? AppTheme.radiusPill : AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isLi ? AppTheme.radiusPill : AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      suffixIcon: _parsing
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    _apply(widget.filters.copyWith(clearQuery: true));
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                      _showNlpPreview = false;
                      _preview = [];
                    });
                  },
                )
              : null,
    );
  }

  InputDecoration _liInnerDecoration(AppStrings s) {
    return InputDecoration(
      hintText: s.searchHintProjects,
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondary.withOpacity(0.9),
      ),
      filled: false,
      prefixIcon: Icon(Icons.search, color: AppTheme.primary, size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      suffixIcon: _parsing
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    _apply(widget.filters.copyWith(clearQuery: true));
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                      _showNlpPreview = false;
                      _preview = [];
                    });
                  },
                )
              : null,
    );
  }

  Widget _buildAirbnbSearchBox(BuildContext context, AppStrings s) {
    final p = context.palette;
    return Container(
      decoration: LiLayout.searchBarDecorationFor(p),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
              onChanged: _onChanged,
              onTap: () {
                if (_suggestions.isNotEmpty) setState(() => _showSuggestions = true);
                if (_preview.isNotEmpty) setState(() => _showNlpPreview = true);
              },
              onSubmitted: (v) {
                _apply(widget.filters.copyWith(
                  query: v.trim().isEmpty ? null : v,
                  clearQuery: v.trim().isEmpty,
                ));
                setState(() {
                  _showSuggestions = false;
                  _showNlpPreview = false;
                });
              },
              decoration: InputDecoration(
                hintText: s.searchHintProjects,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: p.textSecondary.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                prefixIcon: Icon(Icons.search, color: p.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: _parsing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, size: 20, color: p.textSecondary),
                            onPressed: () {
                              _controller.clear();
                              _apply(widget.filters.copyWith(clearQuery: true));
                              setState(() {
                                _suggestions = [];
                                _showSuggestions = false;
                                _showNlpPreview = false;
                                _preview = [];
                              });
                            },
                          )
                        : null,
              ),
            ),
          ),
          if (widget.onMapSearch != null) ...[
            Container(width: 1, height: 28, color: p.divider),
            IconButton(
              tooltip: s.mapSearchShort,
              icon: Icon(Icons.map_outlined, color: p.primary, size: 22),
              onPressed: widget.onMapSearch,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiSearchBox(AppStrings s) {
    final p = context.palette;
    return IntrinsicHeight(
      child: Container(
        decoration: LiLayout.searchBarDecorationFor(p),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                onTap: () {
                  if (_suggestions.isNotEmpty) setState(() => _showSuggestions = true);
                  if (_preview.isNotEmpty) setState(() => _showNlpPreview = true);
                },
                onSubmitted: (v) {
                  _apply(widget.filters.copyWith(
                    query: v.trim().isEmpty ? null : v,
                    clearQuery: v.trim().isEmpty,
                  ));
                  setState(() {
                    _showSuggestions = false;
                    _showNlpPreview = false;
                  });
                },
                decoration: _liInnerDecoration(s),
              ),
            ),
            if (widget.onMapSearch != null) ...[
              Container(
                width: 1,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onMapSearch,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppTheme.radiusPill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: SizedBox(
                      width: 62,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: AppTheme.accentDeep,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.mapSearchLabel,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAirbnb = widget.style == SearchBarStyle.airbnb;
    final isLi = widget.style == SearchBarStyle.livingInsider || isAirbnb;
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLi)
          isAirbnb ? _buildAirbnbSearchBox(context, s) : _buildLiSearchBox(s)
        else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                onTap: () {
                  if (_suggestions.isNotEmpty) {
                    setState(() => _showSuggestions = true);
                  }
                  if (_preview.isNotEmpty) {
                    setState(() => _showNlpPreview = true);
                  }
                },
                onSubmitted: (v) {
                  _apply(widget.filters.copyWith(
                    query: v.trim().isEmpty ? null : v,
                    clearQuery: v.trim().isEmpty,
                  ));
                  setState(() {
                    _showSuggestions = false;
                    _showNlpPreview = false;
                  });
                },
                decoration: _searchDecoration(s),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: widget.filters.hasActiveFilters,
                label: const Text(''),
                child: const Icon(Icons.tune),
              ),
              tooltip: s.filters,
            ),
          ],
        ),
        if (_showNlpPreview) _buildNlpPreview(s),
        if (_showSuggestions) _buildSuggestions(),
      ],
    );
  }

  Widget _buildNlpPreview(AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.detectedFilters,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ..._preview.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(_iconForLabel(p.label, s), size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${s.filterPreviewLabel(p.label)}: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(p.value, style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _clearParsed, child: Text(s.clear)),
              const Spacer(),
              FilledButton(
                onPressed: _parsedFilters.isEmpty ? null : _applyParsedFilters,
                child: Text(s.useFilters),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForLabel(String label, AppStrings s) {
    final localized = s.filterPreviewLabel(label);
    if (localized == s.locationLabel) return Icons.place_outlined;
    if (localized == s.budgetLabel) return Icons.payments_outlined;
    if (localized == s.petsLabel) return Icons.pets;
    if (localized == s.filterLabelProject) return Icons.apartment;
    if (localized == s.filterLabelCoAgent) return Icons.handshake_outlined;
    if (localized == s.filterLabelInvestor || localized == s.filterLabelYield) {
      return Icons.trending_up;
    }
    return Icons.filter_alt_outlined;
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppTheme.cardTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          IconData icon;
          switch (s.kind) {
            case SearchSuggestionKind.project:
              icon = Icons.apartment;
              break;
            case SearchSuggestionKind.location:
              icon = Icons.train;
              break;
            case SearchSuggestionKind.listing:
              icon = Icons.home_work_outlined;
              break;
            case SearchSuggestionKind.hint:
              icon = Icons.search;
              break;
          }
          return ListTile(
            dense: true,
            leading: Icon(icon, color: AppTheme.primary),
            title: Text(
              s.title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(s.subtitle, style: TextStyle(fontSize: 12)),
            trailing: s.kind == SearchSuggestionKind.project
                ? Icon(Icons.chevron_right, color: AppTheme.primary, size: 20)
                : null,
            onTap: () => _onSuggestionTap(s),
          );
        },
      ),
    );
  }
}
