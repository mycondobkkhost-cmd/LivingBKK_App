import 'dart:async';

import 'package:flutter/material.dart';

import '../data/bangkok_projects.dart';
import '../l10n/app_strings.dart';
import '../models/search_suggestion.dart';
import '../services/project_catalog.dart';
import '../services/search_display_catalog.dart';
import '../services/search_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import '../utils/localized_content.dart';

/// เลือกโครงการ/ทำเล — ช่องค้นหาเดียวกับหน้าหลัก + ตัวเลือกกรอกเองเมื่อนอกโครงการ
class ProjectPickerField extends StatefulWidget {
  const ProjectPickerField({
    super.key,
    required this.selected,
    required this.manualMode,
    required this.standaloneMode,
    required this.onProjectSelected,
    required this.onAreaSelected,
    required this.onEnterManual,
    required this.onClear,
  });

  final BangkokProject? selected;
  final bool manualMode;
  final bool standaloneMode;
  final ValueChanged<BangkokProject> onProjectSelected;
  final void Function(String areaName, String districtHint) onAreaSelected;
  final VoidCallback onEnterManual;
  final VoidCallback onClear;

  @override
  State<ProjectPickerField> createState() => _ProjectPickerFieldState();
}

class _ProjectPickerFieldState extends State<ProjectPickerField> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _search = SearchService();
  Timer? _debounce;
  List<SearchSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    ProjectCatalog.instance.load();
    SearchDisplayCatalog.instance.load();
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
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

  BangkokProject? _resolveProject(SearchSuggestion s) {
    final slug = s.projectSlug;
    if (slug != null && slug.isNotEmpty) {
      for (final p in ProjectCatalog.instance.projects) {
        if (p.slug == slug) return p;
      }
      return BangkokProjects.bySlug(slug);
    }
    final name = s.projectName ?? s.titleTh;
    if (name != null && name.isNotEmpty) {
      for (final p in ProjectCatalog.instance.projects) {
        if (p.nameTh == name || p.nameEn == name) return p;
      }
    }
    return null;
  }

  void _onSuggestionTap(SearchSuggestion s) {
    if (s.kind == SearchSuggestionKind.project) {
      final project = _resolveProject(s);
      if (project != null) {
        widget.onProjectSelected(project);
        _query.clear();
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        _focus.unfocus();
        return;
      }
    }
    final area = s.projectName ?? s.titleTh ?? s.title;
    final district = s.subtitle.trim().isNotEmpty ? s.subtitle : area;
    widget.onAreaSelected(area, district);
    _query.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return ListenableBuilder(
      listenable: ProjectCatalog.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.projectPickerLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              s.createListingLocationSearchHint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            if (ProjectCatalog.instance.loadedFromCloud) ...[
              const SizedBox(height: 4),
              Text(
                s.projectCatalogLoaded(ProjectCatalog.instance.projects.length),
                style: TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.selected != null && !widget.manualMode) ...[
              _SelectedProjectCard(project: widget.selected!, onClear: widget.onClear),
            ] else if (widget.manualMode) ...[
              _ManualModeBanner(
                standalone: widget.standaloneMode,
                onBack: widget.onClear,
              ),
            ] else ...[
              _HomeStyleSearchBox(
                controller: _query,
                focusNode: _focus,
                palette: p,
                hint: s.searchHintProjects,
                onChanged: _onChanged,
                onTap: () {
                  if (_suggestions.isNotEmpty) {
                    setState(() => _showSuggestions = true);
                  }
                },
                onClear: () {
                  _query.clear();
                  setState(() {
                    _suggestions = [];
                    _showSuggestions = false;
                  });
                },
              ),
              if (_showSuggestions) _SuggestionPanel(
                suggestions: _suggestions,
                onTap: _onSuggestionTap,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onEnterManual,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: Text(s.createListingLocationManualEntry),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HomeStyleSearchBox extends StatelessWidget {
  const _HomeStyleSearchBox({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.hint,
    required this.onChanged,
    required this.onTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppPalette palette;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        decoration: LiLayout.searchBarDecorationFor(palette),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.9),
            ),
            filled: false,
            prefixIcon: Icon(Icons.search, color: palette.primary, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.suggestions,
    required this.onTap,
  });

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onTap;

  @override
  Widget build(BuildContext context) {
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
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = suggestions[i];
          final icon = switch (item.kind) {
            SearchSuggestionKind.project => Icons.apartment,
            SearchSuggestionKind.location => Icons.train,
            SearchSuggestionKind.listing => Icons.home_work_outlined,
            SearchSuggestionKind.hint => Icons.search,
          };
          return ListTile(
            dense: true,
            leading: Icon(icon, color: AppTheme.primary),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: item.kind == SearchSuggestionKind.project
                ? Icon(Icons.chevron_right, color: AppTheme.primary, size: 20)
                : null,
            onTap: () => onTap(item),
          );
        },
      ),
    );
  }
}

class _ManualModeBanner extends StatelessWidget {
  const _ManualModeBanner({
    required this.standalone,
    required this.onBack,
  });

  final bool standalone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      color: AppTheme.accentMidLight,
      child: ListTile(
        leading: const Icon(Icons.edit_location_alt_outlined),
        title: Text(s.createListingLocationManualTitle),
        subtitle: Text(
          standalone
              ? s.createListingNoProjectHint
              : s.createListingLocationManualHint,
        ),
        trailing: TextButton(
          onPressed: onBack,
          child: Text(s.t('ค้นหาใหม่', 'Search again')),
        ),
      ),
    );
  }
}

class _SelectedProjectCard extends StatelessWidget {
  const _SelectedProjectCard({required this.project, required this.onClear});

  final BangkokProject project;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      color: AppTheme.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.displayBilingual,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClear,
                  tooltip: s.clear,
                ),
              ],
            ),
            Text(
              project.nameEn,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(Icons.place_outlined, project.district),
                if (project.bts != null) _chip(Icons.train_outlined, project.bts!),
                _chip(Icons.pin_drop_outlined, s.projectPinFromCatalog),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
