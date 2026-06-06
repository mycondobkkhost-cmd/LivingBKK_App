import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/property_project_admin.dart';
import '../../services/project_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/project_import_url.dart';
import '../../utils/project_location_tags.dart';
import '../../widgets/admin_mobile_layout.dart';

/// แอดมินจัดการทะเบียนโครงการ — เพิ่ม/แก้/ดึงจาก LI โดยไม่ต้องโค้ด
class AdminProjectsTab extends StatefulWidget {
  const AdminProjectsTab({super.key});

  @override
  State<AdminProjectsTab> createState() => _AdminProjectsTabState();
}

class _AdminProjectsTabState extends State<AdminProjectsTab> {
  final _repo = ProjectRepository.instance;
  final _search = TextEditingController();
  final _importUrl = TextEditingController();

  List<PropertyProjectRow> _all = [];
  List<String> _discoveredSlugs = [];
  String? _bulkStatus;
  String? _importHint;
  bool _loading = true;
  bool _busy = false;
  bool _showInactive = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    _importUrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _importHint = await _repo.importBlockReason();
      _all = await _repo.listAll(includeInactive: _showInactive);
    } catch (_) {
      _all = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<PropertyProjectRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((p) {
      final hay = [
        p.nameTh,
        p.nameEn,
        p.district,
        p.slug,
        p.btsStation,
        ...p.aliases,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _importFromUrl() async {
    final url = _importUrl.text.trim();
    final s = context.s;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsNeedUrl)),
      );
      return;
    }
    if (ProjectImportUrl.detect(url) == ProjectImportSource.unknown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsImportUnsupported)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _repo.importFromAnyUrl(url);
      _importUrl.clear();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.updated
                ? s.adminProjectsImportUpdated(result.project.nameTh)
                : s.adminProjectsImportCreated(result.project.nameTh),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProjectRepository.friendlyImportError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discoverPropertyHub() async {
    final s = context.s;
    setState(() {
      _busy = true;
      _bulkStatus = s.adminProjectsDiscovering;
    });
    try {
      final slugs = await _repo.discoverPropertyHubSlugs();
      if (!mounted) return;
      setState(() {
        _discoveredSlugs = slugs;
        _bulkStatus = s.adminProjectsDiscovered(slugs.length);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _bulkStatus = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetAndResyncCatalog() async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminProjectsResetConfirmTitle),
        content: Text(s.adminProjectsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.adminProjectsResetCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminProjectsResetConfirmBtn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _bulkStatus = s.adminProjectsResetTitle;
      _discoveredSlugs = [];
    });
    try {
      final purge = await _repo.purgeAllProjects();
      final deleted = (purge['projects_deleted'] as num?)?.toInt() ?? 0;
      final unlinked = (purge['listings_unlinked'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsResetDone(deleted, unlinked))),
      );
      await _syncAllFromPropertyHub();
    } catch (e) {
      if (!mounted) return;
      setState(() => _bulkStatus = '$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProjectRepository.friendlyImportError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// กดปุ่มเดียว: ค้นหาชื่อทั้งหมด → ดึงรายละเอียดทีละชุดจนจบ
  Future<void> _syncAllFromPropertyHub() async {
    await _discoverPropertyHub();
    if (!mounted || _discoveredSlugs.isEmpty) return;
    await _batchImportPropertyHub();
  }

  Future<void> _batchImportPropertyHub() async {
    final s = context.s;
    if (_discoveredSlugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsDiscoverFirst)),
      );
      return;
    }
    setState(() {
      _busy = true;
      _bulkStatus = s.adminProjectsImportingBatch;
    });
    try {
      var offset = 0;
      var totalOk = 0;
      var totalFail = 0;
      while (offset < _discoveredSlugs.length) {
        const batchSize = 20;
        final end = offset + batchSize;
        final batch = _discoveredSlugs.sublist(
          offset,
          end > _discoveredSlugs.length ? _discoveredSlugs.length : end,
        );
        if (batch.isEmpty) break;
        final data = await _repo.batchImportPropertyHub(slugs: batch, limit: batchSize);
        totalOk += (data['ok'] as num?)?.toInt() ?? 0;
        totalFail += (data['fail'] as num?)?.toInt() ?? 0;
        offset += batch.length;
        if (!mounted) return;
        setState(() {
          _bulkStatus = s.adminProjectsBatchProgress(offset, _discoveredSlugs.length, totalOk, totalFail);
        });
        if ((data['remaining'] as num?)?.toInt() == 0 && offset >= _discoveredSlugs.length) break;
      }
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsBatchDone(totalOk, totalFail))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bulkStatus = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteImportUrl() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _importUrl.text = text;
    setState(() {});
  }

  Future<void> _openEditor({PropertyProjectRow? existing}) async {
    final saved = await showModalBottomSheet<PropertyProjectRow>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, scrollController) => _ProjectEditorSheet(
          existing: existing,
          scrollController: scrollController,
        ),
      ),
    );
    if (saved == null) return;
    setState(() => _busy = true);
    try {
      if (existing != null) {
        await _repo.update(existing.id, saved);
      } else if (saved.id.isNotEmpty) {
        await _repo.update(saved.id, saved);
      } else {
        await _repo.create(saved);
      }
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminProjectsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('ต้องเชื่อม Supabase')
          ? context.s.adminProjectsNeedSupabase
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(PropertyProjectRow row) async {
    setState(() => _busy = true);
    try {
      await _repo.setActive(row.id, !row.isActive);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filtered = _filtered;

    return Stack(
      children: [
        ListView(
          padding: AdminMobileLayout.scrollPadding(context, fabClearance: 72),
          children: [
            AdminHint(s.adminProjectsIntro),
            if (_importHint != null) ...[
              const SizedBox(height: 8),
              AdminNote(_importHint!),
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.adminProjectsManualTitle, style: AdminTheme.title),
                    const SizedBox(height: 6),
                    AdminHint(s.adminProjectsManualHint),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _openEditor(),
                      icon: const Icon(Icons.edit_note_outlined),
                      label: Text(s.adminProjectsManualBtn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.adminProjectsImportTitle, style: AdminTheme.title),
            const SizedBox(height: 8),
            TextField(
              controller: _importUrl,
              decoration: InputDecoration(
                labelText: s.adminProjectsImportUrlLabel,
                hintText: s.adminProjectsImportUrlHintAny,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteImportUrl,
                  tooltip: s.adminImportPaste,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _importFromUrl,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(s.adminProjectsImportBtn),
            ),
            const Divider(height: 28),
            Text(s.adminProjectsBulkTitle, style: AdminTheme.title),
            const SizedBox(height: 6),
            AdminHint(s.adminProjectsBulkHint),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _busy ? null : _syncAllFromPropertyHub,
              icon: const Icon(Icons.cloud_sync_outlined),
              label: Text(s.adminProjectsSyncAllBtn),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _discoverPropertyHub,
                  icon: const Icon(Icons.travel_explore),
                  label: Text(s.adminProjectsDiscoverBtn),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _discoveredSlugs.isEmpty ? null : _batchImportPropertyHub,
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(s.adminProjectsBulkImportBtn),
                ),
              ],
            ),
            if (_bulkStatus != null) ...[
              const SizedBox(height: 8),
              Text(_bulkStatus!, style: AdminTheme.status),
            ],
            const SizedBox(height: 14),
            Text(s.adminProjectsResetTitle, style: AdminTheme.title),
            const SizedBox(height: 6),
            AdminHint(s.adminProjectsResetHint),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _resetAndResyncCatalog,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(s.adminProjectsResetBtn),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.adminProjectsSearchHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(s.adminProjectsShowInactive),
                  selected: _showInactive,
                  onSelected: (v) {
                    setState(() => _showInactive = v);
                    _refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.adminProjectsCount(filtered.length, _all.length),
              style: AdminTheme.caption,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text(s.adminProjectsEmpty)),
              )
            else
              ...filtered.map((p) => _ProjectCard(
                    project: p,
                    onEdit: () => _openEditor(existing: p),
                    onToggleActive: () => _toggleActive(p),
                  )),
          ],
        ),
        if (_busy)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        AdminMobileLayout.stickyFooter(
          context,
          child: Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton.extended(
              onPressed: _busy ? null : () => _openEditor(),
              icon: const Icon(Icons.add),
              label: Text(s.adminProjectsAdd),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onToggleActive,
  });

  final PropertyProjectRow project;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: project.isActive ? AdminTheme.surface : AdminTheme.surfaceMuted,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: project.isActive
              ? AppTheme.primaryLight
              : AppTheme.textSecondary.withOpacity(0.15),
          child: Icon(
            Icons.apartment,
            color: project.isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
        title: Text(
          project.nameTh,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: project.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${project.nameEn} · ${project.district}',
              style: TextStyle(fontSize: 12),
            ),
            if (project.btsStation != null)
              Text(project.btsStation!, style: TextStyle(fontSize: 11)),
            Text(
              '${project.slug} · ${project.sourcePlatform}',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'toggle') onToggleActive();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(s.edit)),
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                project.isActive ? s.adminProjectsDeactivate : s.adminProjectsActivate,
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _ProjectEditorSheet extends StatefulWidget {
  const _ProjectEditorSheet({
    this.existing,
    required this.scrollController,
  });

  final PropertyProjectRow? existing;
  final ScrollController scrollController;

  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
  final _repo = ProjectRepository.instance;
  late final TextEditingController _slug;
  late final TextEditingController _nameTh;
  late final TextEditingController _nameEn;
  late final TextEditingController _district;
  late final TextEditingController _bts;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _aliases;
  late final TextEditingController _year;
  late final TextEditingController _facilities;
  late final TextEditingController _descTh;
  late final TextEditingController _notes;
  late final TextEditingController _sourceUrl;
  late String _propertyType;
  bool _slugTouched = false;
  bool _prefilling = false;
  String? _prefilledId;
  List<String> _selectedTags = [];
  List<ProjectTag> _suggestedTags = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _slug = TextEditingController(text: e?.slug ?? '');
    _nameTh = TextEditingController(text: e?.nameTh ?? '');
    _nameEn = TextEditingController(text: e?.nameEn ?? '');
    _district = TextEditingController(text: e?.district ?? '');
    _selectedTags = List<String>.from(e?.nearbyTransit ?? const []);
    _bts = TextEditingController(text: e?.btsStation ?? '');
    _lat = TextEditingController(text: e?.lat.toStringAsFixed(6) ?? '13.736700');
    _lng = TextEditingController(text: e?.lng.toStringAsFixed(6) ?? '100.560800');
    _aliases = TextEditingController(text: e?.aliases.join(', ') ?? '');
    _year = TextEditingController(text: e?.yearBuilt?.toString() ?? '');
    _facilities = TextEditingController(
      text: e?.facilities.join(', ') ?? 'สระว่ายน้ำ, ฟิตเนส, ที่จอดรถ',
    );
    _descTh = TextEditingController(text: e?.descriptionTh ?? '');
    _notes = TextEditingController(text: e?.adminNotes ?? '');
    _sourceUrl = TextEditingController(text: e?.sourceUrl ?? '');
    _propertyType = e?.propertyType ?? 'condo';
    _slugTouched = e?.slug.isNotEmpty == true;
    _nameEn.addListener(_maybeAutoSlug);
    _slug.addListener(() {
      if (_slug.text.trim().isNotEmpty) _slugTouched = true;
    });
    if (e != null && _selectedTags.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recomputeTagSuggestions();
      });
    }
  }

  void _maybeAutoSlug() {
    if (_slugTouched || widget.existing != null) return;
    final auto = ProjectImportUrl.slugify(_nameEn.text);
    if (auto.isNotEmpty) _slug.text = auto;
  }

  @override
  void dispose() {
    _nameEn.removeListener(_maybeAutoSlug);
    _slug.dispose();
    _nameTh.dispose();
    _nameEn.dispose();
    _district.dispose();
    _bts.dispose();
    _lat.dispose();
    _lng.dispose();
    _aliases.dispose();
    _year.dispose();
    _facilities.dispose();
    _descTh.dispose();
    _notes.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  void _recomputeTagSuggestions({bool applyAuto = false}) {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) return;
    final detection = ProjectLocationTags.detect(
      lat: lat,
      lng: lng,
      district: _district.text.trim(),
      htmlOrDesc: _descTh.text,
      existingBts: _bts.text,
      alreadySelected: _selectedTags,
    );
    setState(() {
      if (applyAuto && _selectedTags.isEmpty) {
        _selectedTags = ProjectLocationTags.labelsFromTags(detection.autoSelected);
        if (_bts.text.trim().isEmpty) {
          final bts = ProjectLocationTags.formatBtsField(_selectedTags);
          if (bts != null) _bts.text = bts;
        }
      }
      _suggestedTags = detection.suggestions;
    });
  }

  void _applyDraft(PropertyProjectRow draft) {
    final enriched = _repo.enrichTransit(draft);
    _nameTh.text = enriched.nameTh;
    _nameEn.text = enriched.nameEn;
    if (enriched.slug.isNotEmpty) _slug.text = enriched.slug;
    _district.text = enriched.district;
    _selectedTags = [];
    _bts.text = '';
    _lat.text = draft.lat.toStringAsFixed(6);
    _lng.text = draft.lng.toStringAsFixed(6);
    _aliases.text = enriched.aliases.join(', ');
    _year.text = enriched.yearBuilt?.toString() ?? '';
    if (enriched.facilities.isNotEmpty) {
      _facilities.text = enriched.facilities.join(', ');
    }
    _descTh.text = enriched.descriptionTh ?? '';
    _propertyType = enriched.propertyType;
    if (enriched.sourceUrl != null) _sourceUrl.text = enriched.sourceUrl!;
    _recomputeTagSuggestions(applyAuto: true);
  }

  void _addTag(String label) {
    final t = label.trim();
    if (t.isEmpty || _selectedTags.contains(t)) return;
    setState(() {
      _selectedTags = [..._selectedTags, t];
      _suggestedTags = _suggestedTags.where((s) => s.label != t).toList();
      if (ProjectLocationTags.transitOnlyLabels([t]).isNotEmpty) {
        _bts.text = ProjectLocationTags.formatBtsField(_selectedTags) ?? _bts.text;
      }
    });
  }

  void _removeTag(String label) {
    setState(() {
      _selectedTags = _selectedTags.where((t) => t != label).toList();
      _recomputeTagSuggestions();
      _bts.text = ProjectLocationTags.formatBtsField(_selectedTags) ?? '';
    });
  }

  Future<void> _prefillFromSourceUrl() async {
    final url = _sourceUrl.text.trim();
    final s = context.s;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsNeedUrl)),
      );
      return;
    }
    if (ProjectImportUrl.detect(url) == ProjectImportSource.unknown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsImportUnsupported)),
      );
      return;
    }
    setState(() => _prefilling = true);
    try {
      final draft = await _repo.previewFromUrl(url);
      _prefilledId = draft.id.isNotEmpty ? draft.id : null;
      _applyDraft(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsPrefillDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProjectRepository.friendlyImportError(e))),
      );
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
  }

  List<String> _splitList(String raw) =>
      raw.split(RegExp(r'[,|/]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  void _refreshNearbyTransit() {
    _recomputeTagSuggestions(applyAuto: _selectedTags.isEmpty);
  }

  void _save() {
    final s = context.s;
    if (_nameTh.text.trim().isEmpty || _nameEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsNameRequired)),
      );
      return;
    }
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsCoordsInvalid)),
      );
      return;
    }

    final sourceUrl = _sourceUrl.text.trim();
    final labels = _selectedTags.isNotEmpty
        ? ProjectLocationTags.mergeSelectedLabels(_selectedTags)
        : ProjectLocationTags.labelsFromTags(
            ProjectLocationTags.detect(
              lat: lat,
              lng: lng,
              district: _district.text.trim(),
              htmlOrDesc: _descTh.text,
              existingBts: _bts.text,
            ).autoSelected,
          );
    final row = PropertyProjectRow(
      id: widget.existing?.id ?? _prefilledId ?? '',
      slug: _slug.text.trim(),
      nameTh: _nameTh.text.trim(),
      nameEn: _nameEn.text.trim(),
      district: _district.text.trim().isEmpty ? 'กรุงเทพฯ' : _district.text.trim(),
      btsStation: _bts.text.trim().isEmpty
          ? ProjectLocationTags.formatBtsField(labels)
          : _bts.text.trim(),
      nearbyTransit: labels,
      propertyType: _propertyType,
      lat: lat,
      lng: lng,
      isActive: widget.existing?.isActive ?? true,
      aliases: _splitList(_aliases.text),
      yearBuilt: int.tryParse(_year.text.trim()),
      facilities: _splitList(_facilities.text),
      sourcePlatform: widget.existing?.sourcePlatform ??
          (sourceUrl.isEmpty
              ? 'manual'
              : switch (ProjectImportUrl.detect(sourceUrl)) {
                  ProjectImportSource.propertyHub => 'propertyhub',
                  ProjectImportSource.livingInsider => 'livinginsider',
                  ProjectImportSource.unknown => 'manual',
                }),
      sourceUrl: sourceUrl.isEmpty ? widget.existing?.sourceUrl : sourceUrl,
      descriptionTh: _descTh.text.trim().isEmpty ? null : _descTh.text.trim(),
      adminNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.pop(context, row);
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );

  Color _tagColor(ProjectTagKind kind) => switch (kind) {
        ProjectTagKind.transit => const Color(0xFFEDE9FE),
        ProjectTagKind.zone => const Color(0xFFECFDF5),
        ProjectTagKind.district => const Color(0xFFFFF7ED),
      };

  Widget _tagChip({
    required String label,
    required ProjectTagKind kind,
    required bool selected,
    VoidCallback? onTap,
    VoidCallback? onDeleted,
  }) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: _tagColor(kind),
      selected: selected,
      onPressed: onTap,
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 16) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final projectTypes = [
      ('condo', 'คอนโด'),
      ('house', 'บ้าน'),
      ('townhouse', 'ทาวน์เฮ้าส์'),
      ('apartment', 'อพาร์ทเมนต์'),
      ('other', 'อื่นๆ'),
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.existing == null ? s.adminProjectsAdd : s.adminProjectsEdit,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                if (widget.existing == null) ...[
                  TextField(
                    controller: _sourceUrl,
                    decoration: InputDecoration(
                      labelText: s.adminProjectsSourceUrl,
                      hintText: s.adminProjectsSourceUrlHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: _prefilling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_outlined),
                        onPressed: _prefilling ? null : _prefillFromSourceUrl,
                        tooltip: s.adminProjectsPrefillBtn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _prefilling ? null : _prefillFromSourceUrl,
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                    label: Text(s.adminProjectsPrefillBtn),
                  ),
                  const SizedBox(height: 14),
                ],
                _sectionTitle(s.adminProjectsFormSectionBasic),
                TextField(
                  controller: _nameTh,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsNameTh,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameEn,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsNameEn,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _slug,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsSlug,
                    hintText: s.adminProjectsSlugHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: projectTypes.any((e) => e.$1 == _propertyType)
                      ? _propertyType
                      : 'condo',
                  decoration: InputDecoration(
                    labelText: s.propertyTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in projectTypes)
                      DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                  ],
                  onChanged: (v) => setState(() => _propertyType = v ?? 'condo'),
                ),
                const SizedBox(height: 14),
                _sectionTitle(s.adminProjectsFormSectionLocation),
                TextField(
                  controller: _district,
                  decoration: InputDecoration(
                    labelText: s.districtField,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bts,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsBts,
                    hintText: s.adminProjectsBtsHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.adminProjectsTagsSelected,
                  style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w600, color: AdminTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_selectedTags.isEmpty)
                      Text(s.adminProjectsTagsEmpty, style: AdminTheme.caption),
                    for (final label in _selectedTags)
                      _tagChip(
                        label: label,
                        kind: label.startsWith(ProjectLocationTags.zonePrefix)
                            ? ProjectTagKind.zone
                            : label.startsWith(ProjectLocationTags.districtPrefix)
                                ? ProjectTagKind.district
                                : ProjectTagKind.transit,
                        selected: true,
                        onDeleted: () => _removeTag(label),
                      ),
                  ],
                ),
                if (_suggestedTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    s.adminProjectsTagsSuggest,
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w600, color: AdminTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _suggestedTags)
                        _tagChip(
                          label: tag.label,
                          kind: tag.kind,
                          selected: false,
                          onTap: () => _addTag(tag.label),
                        ),
                    ],
                  ),
                ],
                Text(
                  s.adminProjectsNearbyTransitHint,
                  style: AdminTheme.caption,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: s.adminLatLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: s.adminLngLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _refreshNearbyTransit,
                    icon: const Icon(Icons.directions_transit_outlined, size: 18),
                    label: Text(s.adminProjectsRefreshTransit),
                  ),
                ),
                const SizedBox(height: 14),
                _sectionTitle(s.adminProjectsFormSectionExtra),
                TextField(
                  controller: _aliases,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsAliases,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.yearBuiltLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _facilities,
                  decoration: InputDecoration(
                    labelText: s.commonFacilities,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descTh,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: s.adminProjectsDesc,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  decoration: InputDecoration(
                    labelText: s.adminNotesLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          FilledButton(onPressed: _save, child: Text(s.save)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
