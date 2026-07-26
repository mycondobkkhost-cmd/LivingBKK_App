import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/viewing_request.dart';
import '../../services/owner_hub_repository.dart';
import '../../services/viewing_request_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../contact/chat_link_detail_sheets.dart';
import 'admin_enterprise_page.dart';
import 'admin_phone_viewing_sheet.dart';

/// ตารางคำขอนัดดูทั้งหมด (Phase 24b)
class AdminViewingRequestsPanel extends StatefulWidget {
  const AdminViewingRequestsPanel({super.key});

  @override
  State<AdminViewingRequestsPanel> createState() =>
      _AdminViewingRequestsPanelState();
}

class _AdminViewingRequestsPanelState extends State<AdminViewingRequestsPanel> {
  bool _loading = true;
  List<ViewingRequest> _rows = [];
  ViewingRequestStatus? _statusFilter;
  ViewingRequestSource? _sourceFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _dispatchToOwner(ViewingRequest v) async {
    final s = context.s;
    await OwnerHubRepository.instance.dispatchToOwner(
      viewingRequest: v,
      s: s,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminViewingDispatchedSnack(v.code))),
    );
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await ViewingRequestRepository.instance.fetchAllForAdmin(
      force: true,
    );
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  List<ViewingRequest> get _filtered {
    var list = _rows;
    if (_statusFilter != null) {
      list = list.where((v) => v.status == _statusFilter).toList();
    }
    if (_sourceFilter != null) {
      list = list.where((v) => v.source == _sourceFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((v) {
        return v.code.toLowerCase().contains(q) ||
            v.listingCode.toLowerCase().contains(q) ||
            v.listingTitle.toLowerCase().contains(q) ||
            v.clientTagCode.toLowerCase().contains(q) ||
            (v.presenterTagCode?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  void _openDetail(ViewingRequest v) {
    showViewingRequestDetailSheet(context, v.code, adminView: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filtered = _filtered;
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return ListenableBuilder(
      listenable: ViewingRequestRepository.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEnterprisePageHeader(
              title: s.adminViewingRequestsTableTitle,
              subtitle: s.adminViewingRequestsTableHint,
              badge: '${filtered.length}',
              actions: [
                IconButton(
                  tooltip: s.refresh,
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () => showAdminPhoneViewingSheet(context),
                  icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                  label: Text(s.adminPhoneViewingNewBtn),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: s.adminViewingRequestsSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                _filterChip(
                  label: s.adminViewingFilterAllStatus,
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                for (final st in ViewingRequestStatus.values)
                  _filterChip(
                    label: _statusLabel(st, s),
                    selected: _statusFilter == st,
                    onSelected: () => setState(() => _statusFilter = st),
                  ),
                const SizedBox(width: 8),
                _filterChip(
                  label: s.adminViewingFilterAllSource,
                  selected: _sourceFilter == null,
                  onSelected: () => setState(() => _sourceFilter = null),
                ),
                for (final src in ViewingRequestSource.values)
                  _filterChip(
                    label: _sourceLabel(src, s),
                    selected: _sourceFilter == src,
                    onSelected: () => setState(() => _sourceFilter = src),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? AdminEnterpriseEmptyState(
                          message: s.adminViewingRequestsEmpty,
                        )
                      : Card(
                          clipBehavior: Clip.antiAlias,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 720;
                              if (compact) {
                                return ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final v = filtered[i];
                                    return ListTile(
                                      title: Text(
                                        '${v.code} · ${v.listingCode}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${dateFmt.format(v.scheduledAt)}\n'
                                        '${v.clientTagCode} · '
                                        '${_sourceLabel(v.source, s)} · '
                                        '${_statusLabel(v.status, s)}',
                                        style: AdminTheme.caption,
                                      ),
                                      isThreeLine: true,
                                      trailing: v.status == ViewingRequestStatus.submitted
                                          ? IconButton(
                                              tooltip: s.adminViewingDispatchBtn,
                                              icon: const Icon(Icons.send, size: 20),
                                              onPressed: () => _dispatchToOwner(v),
                                            )
                                          : const Icon(
                                              Icons.chevron_right,
                                              size: 20,
                                            ),
                                      onTap: () => _openDetail(v),
                                    );
                                  },
                                );
                              }
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowHeight: 40,
                                    dataRowMinHeight: 44,
                                    dataRowMaxHeight: 56,
                                    columns: [
                                      DataColumn(label: Text(s.adminViewingColCode)),
                                      DataColumn(label: Text(s.adminViewingColListing)),
                                      DataColumn(label: Text(s.adminViewingColSchedule)),
                                      DataColumn(label: Text(s.adminViewingColClientTag)),
                                      DataColumn(label: Text(s.adminViewingColSource)),
                                      DataColumn(label: Text(s.adminViewingColStatus)),
                                    ],
                                    rows: filtered.map((v) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              v.code,
                                              style: TextStyle(
                                                color: AppTheme.primary,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${v.listingCode}\n${v.listingTitle}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              dateFmt.format(v.scheduledAt),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              v.clientTagCode,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _sourceLabel(v.source, s),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _statusLabel(v.status, s),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                        onSelectChanged: (_) => _openDetail(v),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }

  String _statusLabel(ViewingRequestStatus st, AppStrings s) =>
      switch (st) {
        ViewingRequestStatus.draft => s.adminViewingStatusDraft,
        ViewingRequestStatus.submitted => s.adminViewingStatusSubmitted,
        ViewingRequestStatus.sentToOwner => s.adminViewingStatusSentToOwner,
        ViewingRequestStatus.ownerConfirmed => s.adminViewingStatusOwnerConfirmed,
        ViewingRequestStatus.ownerDeclined => s.adminViewingStatusOwnerDeclined,
        ViewingRequestStatus.cancelled => s.adminViewingStatusCancelled,
      };

  String _sourceLabel(ViewingRequestSource src, AppStrings s) =>
      switch (src) {
        ViewingRequestSource.customer => s.adminViewingSourceCustomer,
        ViewingRequestSource.coAgent => s.adminViewingSourceCoAgent,
        ViewingRequestSource.adminPhone => s.adminViewingSourceAdminPhone,
      };
}
