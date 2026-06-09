import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/registry_asset_metadata.dart';
import '../../models/vault_asset.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../services/availability_hidden_registry_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../utils/admin_listing_nav.dart';
import '../../utils/admin_reference_nav.dart';
import 'admin_registry_ops_panel.dart';

bool _registryRowMatches(VaultAssetSummary item, String q) {
  final code = item.displayCode.toLowerCase();
  final title = (item.titlePreview ?? '').toLowerCase();
  final platform = (item.sourcePlatform ?? '').toLowerCase();
  final id = item.entityId.toLowerCase();
  final type = item.entityType.toLowerCase();
  return code.contains(q) ||
      title.contains(q) ||
      platform.contains(q) ||
      id.contains(q) ||
      type.contains(q);
}

String _registryRowId(VaultAssetSummary item) =>
    item.listingId ?? item.entityId;

/// ค้นหาในตาราง — รหัส / หัวข้อ / แหล่ง / entity id
/// คลังหลักซ่อนรายการในคลังพิเศษ · ค้นหายังครอบคลุมคลังซ่อน
List<VaultAssetSummary> filterAssetRegistry(
  List<VaultAssetSummary> items,
  String query, {
  List<VaultAssetSummary> hiddenPool = const [],
}) {
  final hidden = AvailabilityHiddenRegistryService.instance;
  final q = query.trim().toLowerCase();

  if (q.isEmpty) {
    return items
        .where((item) => !hidden.isHidden(_registryRowId(item)))
        .toList();
  }

  final seen = <String>{};
  final out = <VaultAssetSummary>[];
  void add(VaultAssetSummary item) {
    final id = _registryRowId(item);
    if (seen.add(id)) out.add(item);
  }

  for (final item in items) {
    if (_registryRowMatches(item, q)) add(item);
  }
  for (final item in hiddenPool) {
    if (_registryRowMatches(item, q)) add(item);
  }
  return out;
}

extension VaultAssetSummaryDisplay on VaultAssetSummary {
  String entityLabel(AppStrings s) => switch (entityType) {
        'listing_import' => s.adminVaultFilterImport,
        'listing' => s.adminVaultFilterListing,
        'profile' => s.adminVaultFilterProfile,
        _ => entityType,
      };
}

DateTime? _resolveLastEditedAt(VaultAssetSummary item) {
  final ops = RegistryAssetOpsService.instance;
  final adminEdit = ops.lastAdminEditAt(
    entityType: item.entityType,
    entityId: item.entityId,
  );
  final synced = item.updatedAt;
  if (adminEdit == null) return synced;
  if (synced == null) return adminEdit;
  return adminEdit.isAfter(synced) ? adminEdit : synced;
}

/// ตารางคลังทรัพย์แบบ sheet — ลำดับ · รหัส · ประเภท · วันที่ · แก้ไข · แหล่ง · หัวข้อ
class AdminAssetRegistryTable extends StatelessWidget {
  const AdminAssetRegistryTable({
    super.key,
    required this.items,
    required this.onRowTap,
    this.emptyMessage,
  });

  final List<VaultAssetSummary> items;
  final ValueChanged<VaultAssetSummary> onRowTap;
  final String? emptyMessage;

  static const _colSeq = 44.0;
  static const _colCode = 128.0;
  static const _colType = 72.0;
  static const _colDate = 92.0;
  static const _colLastEdit = 92.0;
  static const _colSource = 100.0;
  static const _colTitle = 200.0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage ?? s.adminRegistryEmpty,
            textAlign: TextAlign.center,
            style: AdminTheme.hint,
          ),
        ),
      );
    }

    final dateFmt = DateFormat('d MMM yy HH:mm');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 52,
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    headingRowColor: MaterialStateProperty.all(
                      LivingBkkBrand.purplePrimary.withOpacity(0.06),
                    ),
                    columns: [
                      DataColumn(label: _head(s.adminRegistryColSeq)),
                      DataColumn(label: _head(s.adminRegistryColCode)),
                      DataColumn(label: _head(s.adminRegistryColType)),
                      DataColumn(label: _head(s.adminRegistryColDate)),
                      DataColumn(label: _head(s.adminRegistryColLastEdit)),
                      DataColumn(label: _head(s.adminRegistryColSource)),
                      DataColumn(label: _head(s.adminRegistryColTitle)),
                    ],
                    rows: [
                      for (var i = 0; i < items.length; i++)
                        _row(
                          context: context,
                          index: i + 1,
                          item: items[i],
                          dateFmt: dateFmt,
                          onTap: () => onRowTap(items[i]),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _head(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    );
  }

  DataRow _row({
    required BuildContext context,
    required int index,
    required VaultAssetSummary item,
    required DateFormat dateFmt,
    required VoidCallback onTap,
  }) {
    final s = context.s;
    final addedAt = item.capturedAt ?? item.updatedAt;
    final added = addedAt != null ? dateFmt.format(addedAt) : '—';
    final lastEditAt = _resolveLastEditedAt(item);
    final lastEdit = lastEditAt != null ? dateFmt.format(lastEditAt) : '—';
    final source = item.sourcePlatform ?? '—';
    final title = item.titlePreview ?? '—';

    return DataRow(
      onSelectChanged: (_) => onTap(),
      cells: [
        DataCell(Text('$index', style: _cellStyle)),
        DataCell(
          Text(
            item.displayCode,
            style: _cellStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: LivingBkkBrand.purplePrimary,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        DataCell(Text(item.entityLabel(s), style: _cellStyle)),
        DataCell(Text(added, style: _cellStyle.copyWith(fontSize: 10))),
        DataCell(Text(lastEdit, style: _cellStyle.copyWith(fontSize: 10))),
        DataCell(Text(source, style: _cellStyle)),
        DataCell(
          SizedBox(
            width: _colTitle,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _cellStyle,
            ),
          ),
        ),
      ],
    );
  }

  static final _cellStyle = AdminTheme.caption.copyWith(fontSize: 11);
}

/// แถบค้นหารหัส + สรุปจำนวน
class AdminAssetRegistrySearchBar extends StatelessWidget {
  const AdminAssetRegistrySearchBar({
    super.key,
    required this.controller,
    required this.total,
    required this.shown,
    required this.query,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final int total;
  final int shown;
  final String query;
  final VoidCallback? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            hintText: s.adminRegistrySearchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClear,
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: AdminTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AdminTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AdminTheme.border),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.adminRegistryShowing(shown, total),
          style: AdminTheme.caption,
        ),
      ],
    );
  }
}

Future<void> openAssetRegistryDetailSheet({
  required BuildContext context,
  required VaultAssetDetail detail,
  required bool confidential,
  required String adminTier,
  bool isDemoPreview = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scroll) => AssetRegistryDetailSheet(
        detail: detail,
        scrollController: scroll,
        confidential: confidential,
        parentContext: context,
        adminTier: adminTier,
        isDemoPreview: isDemoPreview,
      ),
    ),
  );
}

class AssetRegistryDetailSheet extends StatefulWidget {
  const AssetRegistryDetailSheet({
    super.key,
    required this.detail,
    required this.scrollController,
    required this.confidential,
    required this.parentContext,
    required this.adminTier,
    this.isDemoPreview = false,
  });

  final VaultAssetDetail detail;
  final ScrollController scrollController;
  final bool confidential;
  final BuildContext parentContext;
  final String adminTier;
  final bool isDemoPreview;

  @override
  State<AssetRegistryDetailSheet> createState() => _AssetRegistryDetailSheetState();
}

class _AssetRegistryDetailSheetState extends State<AssetRegistryDetailSheet> {
  final _ops = RegistryAssetOpsService.instance;

  VaultAssetDetail get detail => widget.detail;
  ScrollController get scrollController => widget.scrollController;
  bool get confidential => widget.confidential;

  @override
  void initState() {
    super.initState();
    _ops.addListener(_refresh);
  }

  @override
  void dispose() {
    _ops.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final d = confidential ? detail : detail.censored();
    final sum = d.summary;
    final meta = RegistryAssetRecordMeta.fromDetail(detail);
    final seedHistory = RegistryAssetRecordMeta.historyFromPayload(detail.payload);
    final history = _ops.historyFor(
      entityType: sum.entityType,
      entityId: sum.entityId,
      seed: seedHistory,
    );
    final displayTitle =
        _ops.titleFor(entityType: sum.entityType, entityId: sum.entityId) ??
        sum.titlePreview;
    final ops = _ops.opsFor(entityType: sum.entityType, entityId: sum.entityId);
    final canChat = _ops.hasChatAccess(
      entityType: sum.entityType,
      entityId: sum.entityId,
      adminTier: widget.adminTier,
    );
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            confidential ? s.adminVaultDetailTitle : s.adminRegistryDetailTitle,
            style: AdminTheme.title.copyWith(fontSize: 18),
          ),
          if (!confidential) ...[
            const SizedBox(height: 6),
            Text(s.adminRegistryCensoredHint, style: AdminTheme.hint),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _EntityTypeChip(type: sum.entityType),
              const SizedBox(width: 8),
              ...ops.tags.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(_tagShort(s, t), style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: LivingBkkBrand.purplePrimary.withOpacity(0.1),
                    ),
                  )),
              if (ops.overlay != RegistryDisplayOverlay.none)
                Chip(
                  label: Text(
                    ops.overlay == RegistryDisplayOverlay.sold
                        ? s.adminRegistryOverlaySold
                        : s.adminRegistryOverlayNotAvailable,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  backgroundColor: AppTheme.error.withOpacity(0.15),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                Text(
                  s.adminRegistryRecordedBy,
                  style: AdminTheme.section.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _metaRow(s.adminRegistryRecordedByLabel, meta.recordedBy),
                _metaRow(s.adminRegistryRecordedAt, dateFmt.format(meta.recordedAt)),
                if (meta.ownerName != null)
                  _metaRow(s.adminRegistryOwnerName, meta.ownerName!),
                _metaRow(
                  s.adminRegistryChatTag,
                  meta.chatTag,
                  onTap: canChat
                      ? () => _openChatByTag(context, meta.chatTag, widget.parentContext)
                      : null,
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(s.adminRegistryEditHistory, style: AdminTheme.caption),
                  const SizedBox(height: 6),
                  ...history.reversed.take(8).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.history, size: 14, color: AdminTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${dateFmt.format(e.at)} · ${e.actor}\n${e.action}',
                                  style: AdminTheme.caption.copyWith(height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                const Divider(height: 28),
                AdminRegistryOpsPanel(
                  summary: sum,
                  detail: detail,
                  confidential: confidential,
                  parentContext: widget.parentContext,
                  adminTier: widget.adminTier,
                  isDemoPreview: widget.isDemoPreview,
                ),
                const Divider(height: 28),
                Text(
                  s.adminRegistryDetailSection,
                  style: AdminTheme.section.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 10),
                _metaRow(s.adminRegistryColCode, sum.displayCode),
                if (displayTitle != null && displayTitle.isNotEmpty)
                  _metaRow(s.adminRegistryColTitle, displayTitle),
                if (sum.sourcePlatform != null)
                  _metaRow(s.adminRegistryColSource, sum.sourcePlatform!),
                if (sum.capturedAt != null || sum.updatedAt != null)
                  _metaRow(
                    s.adminRegistryColDate,
                    DateFormat('d MMM yyyy HH:mm').format(
                      sum.capturedAt ?? sum.updatedAt!,
                    ),
                  ),
                if (_resolveLastEditedAt(sum) != null)
                  _metaRow(
                    s.adminRegistryColLastEdit,
                    DateFormat('d MMM yyyy HH:mm').format(
                      _resolveLastEditedAt(sum)!,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (sum.listingCode != null)
                      ActionChip(
                        label: Text(sum.listingCode!),
                        onPressed: () => openAdminListing(
                          context,
                          listingId: sum.listingId,
                          listingCode: sum.listingCode,
                        ),
                      ),
                  ],
                ),
                if (confidential && d.sourceUrl != null) ...[
                  const SizedBox(height: 14),
                  Text(s.adminImportOpenSourceLink, style: AdminTheme.caption),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _openUrl(d.sourceUrl!),
                    child: Text(
                      d.sourceUrl!,
                      style: TextStyle(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                if (confidential && d.phones.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(s.adminVaultPhones, style: AdminTheme.caption),
                  ...d.phones.map(
                    (p) => SelectableText(
                      p,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (confidential && d.lines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Line ID', style: AdminTheme.caption),
                  ...d.lines.map(
                    (l) => SelectableText(
                      l,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (confidential &&
                    d.postTextFull != null &&
                    d.postTextFull!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(s.adminImportFacebookPost, style: AdminTheme.caption),
                  const SizedBox(height: 4),
                  SelectableText(
                    d.postTextFull!,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
                if (!confidential) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, size: 18, color: AdminTheme.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.adminRegistryLockedFields,
                            style: AdminTheme.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (confidential) ...[
                  const SizedBox(height: 12),
                  Text(s.adminVaultRawPayload, style: AdminTheme.caption),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminTheme.border),
                    ),
                    child: SelectableText(
                      _prettyJson(d.payload),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${s.adminVaultEntityId}: ${sum.entityType} / ${sum.entityId}',
                  style: AdminTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatByTag(
    BuildContext context,
    String tag,
    BuildContext parentContext,
  ) async {
    final s = context.s;
    final room = ChatService.instance.roomForListing(tag);
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    if (!parentContext.mounted) return;
    if (room != null) {
      final from = adminReturnNavFromContext(parentContext);
      final fromQ = from != null ? '&from=${from.name}' : '';
      parentContext.push('/admin/console?room=${room.id}$fromQ');
      return;
    }
    parentContext.push('/admin/console');
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(s.adminRegistryChatTagHint(tag))),
    );
  }

  Widget _metaRow(String label, String value, {VoidCallback? onTap}) {
    final child = Text(
      value,
      style: AdminTheme.body.copyWith(
        fontSize: 13,
        color: onTap != null ? LivingBkkBrand.purplePrimary : null,
        decoration: onTap != null ? TextDecoration.underline : null,
        fontFamily: onTap != null ? 'monospace' : null,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: AdminTheme.caption),
          ),
          Expanded(
            child: onTap != null
                ? InkWell(onTap: onTap, child: child)
                : child,
          ),
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    final buf = StringBuffer();
    m.forEach((k, v) => buf.writeln('$k: $v'));
    return buf.toString().trim();
  }

  String _tagShort(AppStrings s, RegistryAdminTag tag) => switch (tag) {
        RegistryAdminTag.hot => s.adminRegistryTagHot,
        RegistryAdminTag.exclusive => s.adminRegistryTagExclusive,
        RegistryAdminTag.featured => s.adminRegistryTagFeatured,
        RegistryAdminTag.verified => s.adminRegistryTagVerified,
        RegistryAdminTag.urgent => s.adminRegistryTagUrgent,
        RegistryAdminTag.ownerUnreachable => s.adminRegistryTagOwnerUnreachable,
      };
}

class _EntityTypeChip extends StatelessWidget {
  const _EntityTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final label = switch (type) {
      'listing_import' => s.adminVaultFilterImport,
      'listing' => s.adminVaultFilterListing,
      'profile' => s.adminVaultFilterProfile,
      _ => type,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
