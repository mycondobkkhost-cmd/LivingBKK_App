import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../services/listing_import_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../utils/listing_import_url.dart';
import 'admin_import_review_sheet.dart';

/// แถบงานนำเข้าทรัพย์จาก LI — ลิงก์เดียว · ดึง · ตรวจแก้ · เผยแพร่
class AdminImportTab extends StatefulWidget {
  const AdminImportTab({super.key});

  @override
  State<AdminImportTab> createState() => _AdminImportTabState();
}

class _AdminImportTabState extends State<AdminImportTab> {
  final _repo = ListingImportRepository.instance;
  final _url = TextEditingController();

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
    _url.dispose();
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

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _url.text = text;
    setState(() {});
  }

  Future<void> _openReview(String importId) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, scrollController) => AdminImportReviewSheet(
          importId: importId,
          scrollController: scrollController,
          onChanged: _refresh,
          onSwitchImport: (otherId) async {
            Navigator.of(ctx).pop();
            await _openReview(otherId);
          },
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _fetchOne() async {
    final s = context.s;
    final url = ListingImportUrl.normalize(_url.text);
    final source = ListingImportUrl.detect(url);
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportNeedUrl)),
      );
      return;
    }
    if (source == ListingImportSource.invalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportUnsupportedUrl)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final row = await _repo.fetchUrl(url);
      _url.clear();
      await _refresh();
      if (!mounted) return;
      final detail = await _repo.getImportDetail(row.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail.projectNotInRegistry
                ? s.adminImportFetchedProjectMissing
                : s.adminImportFetchedFor(s.adminImportSourceLabel(row.sourcePlatform)),
          ),
          duration: Duration(seconds: detail.projectNotInRegistry ? 5 : 3),
        ),
      );
      await _openReview(row.id);
    } on ListingImportFetchException catch (e) {
      await _refresh();
      if (!mounted) return;
      final dup = e.duplicateOf;
      final dupLabel = dup?.listingCode ??
          dup?.titlePreview ??
          dup?.sourceExternalId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dupLabel != null
                ? '${e.message} · ${s.adminImportDuplicateOf(dupLabel)}'
                : e.message,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      if (e.importId != null) {
        await _openReview(e.importId!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingImportRepository.friendlyError(e))),
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
          Container(
            decoration: AdminTheme.card(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminNote(s.adminImportIntro),
                const SizedBox(height: 12),
                TextField(
                  controller: _url,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: s.adminImportSingleUrlLabel,
                    hintText: s.adminImportBulkHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      onPressed: _busy ? null : _fetchOne,
                      tooltip: s.adminImportFetchOne,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                      onPressed: _busy ? null : _fetchOne,
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: Text(s.adminImportFetchOne),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.adminImportQueueTitle(_rows.length),
                  style: AdminTheme.section.copyWith(fontSize: 16),
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
                style: AdminTheme.hint,
              ),
            )
          else
            ..._rows.map((row) => _ImportRowCard(
                  row: row,
                  busy: _busy,
                  onReview: () => _openReview(row.id),
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
    required this.onReview,
  });

  final ListingImportRow row;
  final bool busy;
  final VoidCallback onReview;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onReview,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: AdminTheme.card(
              alert: row.status == 'failed' || row.status == 'needs_fix',
            ),
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
                            style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.sourceUrl,
                            style: AdminTheme.caption,
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
                    _MiniChip(
                      label: s.adminImportSourceLabel(row.sourcePlatform),
                      icon: Icons.public,
                    ),
                    if (row.sourceExternalId != null)
                      _MiniChip(label: row.sourceExternalId!, icon: Icons.tag),
                    if (time.isNotEmpty)
                      _MiniChip(label: time, icon: Icons.schedule),
                  ],
                ),
                if (row.isDuplicateFailure && row.duplicateOf != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.adminImportDuplicateOf(
                      row.duplicateOf!.listingCode ??
                          row.duplicateOf!.titlePreview ??
                          row.duplicateOf!.sourceExternalId ??
                          row.duplicateOf!.importId,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ],
                if (row.errorMessage != null && row.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(row.errorMessage!, style: TextStyle(fontSize: 12, color: AppTheme.error)),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: busy ? null : onReview,
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: Text(
                      row.canReview ? s.adminImportReviewOpen : s.adminImportView,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
        Text(label, style: const TextStyle(fontSize: 12)),
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
    return AdminMobileLayout.scaffold(
      context: context,
      appBar: AdminMobileLayout.appBar(
        context: context,
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
