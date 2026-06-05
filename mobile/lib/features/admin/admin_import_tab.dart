import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../services/listing_import_repository.dart';
import '../../theme/app_theme.dart';

/// แถบงานนำเข้าทรัพย์จาก LI — วางลิงก์ · ดึงอัตโนมัติ · อนุมัติ
class AdminImportTab extends StatefulWidget {
  const AdminImportTab({super.key});

  @override
  State<AdminImportTab> createState() => _AdminImportTabState();
}

class _AdminImportTabState extends State<AdminImportTab> {
  static const _slotCount = 8;

  final _repo = ListingImportRepository.instance;
  final _slots = List.generate(_slotCount, (_) => TextEditingController());
  final _bulk = TextEditingController();

  List<ListingImportRow> _rows = [];
  bool _loading = true;
  bool _busy = false;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final c in _slots) {
      c.dispose();
    }
    _bulk.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _rows = await _repo.listImports(includeArchived: _showArchived);
    } catch (_) {
      _rows = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<String> _collectUrls() {
    final urls = <String>{};
    for (final c in _slots) {
      final t = c.text.trim();
      if (t.isNotEmpty) urls.add(t);
    }
    for (final line in _bulk.text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) urls.add(t);
    }
    return urls.toList();
  }

  Future<void> _fetchAll() async {
    final urls = _collectUrls();
    final s = context.s;
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportNeedUrl)),
      );
      return;
    }

    setState(() => _busy = true);
    var ok = 0;
    var fail = 0;
    for (final url in urls) {
      try {
        await _repo.fetchUrl(url);
        ok++;
      } catch (_) {
        fail++;
      }
    }
    for (final c in _slots) {
      c.clear();
    }
    _bulk.clear();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminImportBatchDone(ok, fail))),
    );
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _bulk.text = text;
    setState(() {});
  }

  Future<void> _approve(ListingImportRow row) async {
    setState(() => _busy = true);
    try {
      await _repo.approve(row.id);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminImportApproved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive(ListingImportRow row) async {
    setState(() => _busy = true);
    try {
      await _repo.archive(row.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry(ListingImportRow row) async {
    setState(() => _busy = true);
    try {
      await _repo.retry(row.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: AppTheme.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.adminImportIntro,
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pasteClipboard,
                        icon: const Icon(Icons.content_paste, size: 18),
                        label: Text(s.adminImportPaste),
                      ),
                      FilledButton.icon(
                        onPressed: _busy ? null : _fetchAll,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_download_outlined, size: 18),
                        label: Text(s.adminImportFetchAll),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.adminImportSlotsTitle,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...List.generate(_slotCount, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _slots[i],
                enabled: !_busy,
                decoration: InputDecoration(
                  hintText: s.adminImportUrlHint(i + 1),
                  prefixIcon: const Icon(Icons.link, size: 20),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _bulk,
            enabled: !_busy,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: s.adminImportBulkLabel,
              hintText: s.adminImportBulkHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.adminImportQueueTitle(_rows.length),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              FilterChip(
                label: Text(s.adminImportShowArchived),
                selected: _showArchived,
                onSelected: _busy
                    ? null
                    : (v) async {
                        setState(() => _showArchived = v);
                        await _refresh();
                      },
              ),
              IconButton(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.adminImportEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ..._rows.map((row) => _ImportRowCard(
                  row: row,
                  busy: _busy,
                  onApprove: () => _approve(row),
                  onArchive: () => _archive(row),
                  onRetry: () => _retry(row),
                )),
        ],
      ),
    );
  }
}

class _ImportRowCard extends StatelessWidget {
  const _ImportRowCard({
    required this.row,
    required this.busy,
    required this.onApprove,
    required this.onArchive,
    required this.onRetry,
  });

  final ListingImportRow row;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onArchive;
  final VoidCallback onRetry;

  Color _statusColor(String status) {
    switch (status) {
      case 'draft_ready':
        return AppTheme.primary;
      case 'approved':
        return AppTheme.accentSoft;
      case 'needs_fix':
      case 'failed':
        return AppTheme.error;
      case 'fetching':
      case 'queued':
        return AppTheme.accentMid;
      case 'archived':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final locale = s.isEnglish ? 'en' : 'th';
    final time = row.createdAt != null
        ? DateFormat('d MMM HH:mm', locale).format(row.createdAt!)
        : '';
    final price = row.pricePreview != null
        ? NumberFormat.currency(locale: locale, symbol: '฿', decimalDigits: 0)
            .format(row.pricePreview)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.titlePreview ?? row.sourceUrl,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.sourceUrl,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: s.adminImportStatus(row.status),
                  color: _statusColor(row.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (row.projectPreview != null)
                  _MiniChip(label: row.projectPreview!, icon: Icons.apartment),
                _MiniChip(label: price, icon: Icons.payments_outlined),
                _MiniChip(
                  label: s.adminImportImages(row.imageCount),
                  icon: Icons.photo_library_outlined,
                ),
                if (row.sourceExternalId != null)
                  _MiniChip(label: 'LI ${row.sourceExternalId}', icon: Icons.tag),
                if (time.isNotEmpty)
                  _MiniChip(label: time, icon: Icons.schedule),
              ],
            ),
            if (row.errorMessage != null && row.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                row.errorMessage!,
                style: TextStyle(fontSize: 12, color: AppTheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (row.canApprove)
                  FilledButton(
                    onPressed: busy ? null : onApprove,
                    child: Text(s.adminImportApprove),
                  ),
                if (row.canRetry)
                  OutlinedButton(
                    onPressed: busy ? null : onRetry,
                    child: Text(s.adminImportRetry),
                  ),
                if (!row.isArchived)
                  TextButton(
                    onPressed: busy ? null : onArchive,
                    child: Text(s.adminImportArchive),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// หน้าเต็มสำหรับ /admin/import บน desktop
class AdminImportPage extends StatelessWidget {
  const AdminImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminImportTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const AdminImportTab(),
    );
  }
}
