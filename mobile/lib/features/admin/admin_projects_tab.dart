import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/property_project_admin.dart';
import '../../services/project_repository.dart';
import '../../theme/app_theme.dart';

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
    if (!url.contains('propertyhub.in.th/projects/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminProjectsPropertyHubOnly)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _repo.importPropertyHubUrl(url);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
      builder: (ctx) => _ProjectEditorSheet(existing: existing),
    );
    if (saved == null) return;
    setState(() => _busy = true);
    try {
      if (existing == null) {
        await _repo.create(saved);
      } else {
        await _repo.update(existing.id, saved);
      }
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminProjectsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            Text(
              s.adminProjectsIntro,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            if (!Env.isConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.adminProjectsNeedSupabase,
                  style: TextStyle(fontSize: 12, color: AppTheme.accentMid),
                ),
              ),
            const SizedBox(height: 14),
            Text(s.adminProjectsImportTitle, style: TextStyle(fontWeight: FontWeight.w800)),
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
            Text(s.adminProjectsBulkTitle, style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              s.adminProjectsBulkHint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
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
              Text(_bulkStatus!, style: TextStyle(fontSize: 12, color: AppTheme.primary)),
            ],
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
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _busy ? null : () => _openEditor(),
            icon: const Icon(Icons.add),
            label: Text(s.adminProjectsAdd),
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
      color: project.isActive ? AppTheme.cardTint : AppTheme.surfaceWarm,
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
  const _ProjectEditorSheet({this.existing});

  final PropertyProjectRow? existing;

  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
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
  late String _propertyType;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _slug = TextEditingController(text: e?.slug ?? '');
    _nameTh = TextEditingController(text: e?.nameTh ?? '');
    _nameEn = TextEditingController(text: e?.nameEn ?? '');
    _district = TextEditingController(text: e?.district ?? '');
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
    _propertyType = e?.propertyType ?? 'condo';
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  List<String> _splitList(String raw) =>
      raw.split(RegExp(r'[,|/]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

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

    final row = PropertyProjectRow(
      id: widget.existing?.id ?? '',
      slug: _slug.text.trim(),
      nameTh: _nameTh.text.trim(),
      nameEn: _nameEn.text.trim(),
      district: _district.text.trim().isEmpty ? 'กรุงเทพฯ' : _district.text.trim(),
      btsStation: _bts.text.trim().isEmpty ? null : _bts.text.trim(),
      propertyType: _propertyType,
      lat: lat,
      lng: lng,
      isActive: widget.existing?.isActive ?? true,
      aliases: _splitList(_aliases.text),
      yearBuilt: int.tryParse(_year.text.trim()),
      facilities: _splitList(_facilities.text),
      sourcePlatform: widget.existing?.sourcePlatform ?? 'manual',
      sourceUrl: widget.existing?.sourceUrl,
      descriptionTh: _descTh.text.trim().isEmpty ? null : _descTh.text.trim(),
      adminNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.pop(context, row);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null ? s.adminProjectsAdd : s.adminProjectsEdit,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
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
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: InputDecoration(
                labelText: s.propertyTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'condo', child: Text('Condo')),
                DropdownMenuItem(value: 'house', child: Text('House')),
                DropdownMenuItem(value: 'townhouse', child: Text('Townhouse')),
                DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _propertyType = v ?? 'condo'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Lat',
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
                      labelText: 'Lng',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            FilledButton(onPressed: _save, child: Text(s.save)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
