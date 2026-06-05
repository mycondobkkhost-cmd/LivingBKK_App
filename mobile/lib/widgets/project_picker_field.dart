import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/bangkok_projects.dart';
import '../../l10n/app_strings.dart';
import '../../services/project_catalog.dart';
import '../../theme/app_theme.dart';
import '../../utils/localized_content.dart';

/// เลือกโครงการแบบ LI — ชื่อมาตรฐาน + ปักหมุดจากแคตตาล็อก (ไม่ใช้ GPS มือถือ)
class ProjectPickerField extends StatefulWidget {
  const ProjectPickerField({
    super.key,
    required this.selected,
    required this.customMode,
    required this.onProjectSelected,
    required this.onEnableCustom,
    required this.onNoProject,
    required this.onClear,
    this.standaloneMode = false,
  });

  final BangkokProject? selected;
  final bool customMode;
  final bool standaloneMode;
  final ValueChanged<BangkokProject> onProjectSelected;
  final VoidCallback onEnableCustom;
  final VoidCallback onNoProject;
  final VoidCallback onClear;

  @override
  State<ProjectPickerField> createState() => _ProjectPickerFieldState();
}

class _ProjectPickerFieldState extends State<ProjectPickerField> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<BangkokProject> _suggestions = [];
  bool _searching = false;
  int _searchGen = 0;

  @override
  void initState() {
    super.initState();
    ProjectCatalog.instance.load();
    _query.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onTextChanged);
    _query.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _query.text;
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () => _runSearch(text));
  }

  Future<void> _runSearch(String text) async {
    final gen = ++_searchGen;
    final hits = await ProjectCatalog.instance.searchOnline(text);
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _suggestions = hits;
      _searching = false;
    });
  }

  void _pick(BangkokProject p) {
    widget.onProjectSelected(p);
    _query.clear();
    setState(() {
      _suggestions = [];
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final q = _query.text.trim();
    final showPanel = !widget.customMode &&
        widget.selected == null &&
        !widget.standaloneMode &&
        q.length >= 2;

    return ListenableBuilder(
      listenable: ProjectCatalog.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.projectPickerLabel,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              s.projectPickerHint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            if (ProjectCatalog.instance.loadedFromCloud) ...[
              const SizedBox(height: 4),
              Text(
                s.projectCatalogLoaded(ProjectCatalog.instance.projects.length),
                style: TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
            ],
            const SizedBox(height: 10),
            if (widget.standaloneMode)
              Card(
                color: AppTheme.accentMidLight,
                child: ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(s.createListingNoProject),
                  subtitle: Text(s.createListingNoProjectHint),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClear,
                  ),
                ),
              )
            else if (widget.selected != null && !widget.customMode) ...[
              _SelectedProjectCard(project: widget.selected!, onClear: widget.onClear),
              const SizedBox(height: 8),
            ] else if (!widget.customMode) ...[
              TextField(
                controller: _query,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: s.projectSearchPlaceholder,
                  prefixIcon: const Icon(Icons.apartment_outlined),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _query.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _query.clear();
                                widget.onClear();
                              },
                            ),
                ),
              ),
              if (showPanel && _searching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.projectSearchLoading,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                )
              else if (showPanel && _suggestions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 6),
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = _suggestions[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            p.displayBilingual,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${p.nameEn} · ${p.district}${p.bts != null ? ' · ${p.bts}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () => _pick(p),
                        );
                      },
                    ),
                  ),
                )
              else if (showPanel && !_searching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.projectSearchNoResults,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
            ],
            if (widget.customMode)
              Card(
                color: AppTheme.accentMidLight,
                child: ListTile(
                  leading: const Icon(Icons.edit_location_alt_outlined),
                  title: Text(s.projectCustomMode),
                  subtitle: Text(s.projectCustomHint),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClear,
                  ),
                ),
              ),
            if (!widget.customMode && !widget.standaloneMode && widget.selected == null) ...[
              TextButton.icon(
                onPressed: widget.onEnableCustom,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(s.projectNotInList),
              ),
              TextButton.icon(
                onPressed: widget.onNoProject,
                icon: const Icon(Icons.home_work_outlined, size: 18),
                label: Text(s.createListingNoProject),
              ),
            ],
          ],
        );
      },
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClear,
                  tooltip: s.clear,
                ),
              ],
            ),
            Text(project.nameEn, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
      label: Text(label, style: TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
