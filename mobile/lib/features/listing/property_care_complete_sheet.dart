import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/property_care_summary.dart';
import '../../services/property_care_repository.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_demo_data.dart';
import '../../utils/app_notice.dart';
import 'property_care_owner_data_sheet.dart';

Future<void> showPropertyCareCompleteSheet(
  BuildContext context, {
  required PropertyCareSummary summary,
  required Future<void> Function() onDone,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CompleteSheet(summary: summary, onDone: onDone),
  );
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.summary, required this.onDone});

  final PropertyCareSummary summary;
  final Future<void> Function() onDone;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final _repo = PropertyCareRepository.instance;
  List<Map<String, dynamic>> _listings = [];
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.listingsForSummary(widget.summary);
    if (!mounted) return;
    setState(() {
      _listings = rows.where((r) => r['owner_data_pending'] == true).toList();
      _loading = false;
    });
  }

  Future<void> _markOne(Map<String, dynamic> row) async {
    final invId = widget.summary.right.inventoryId ??
        AdminDemoData.inventoryIdForCode(widget.summary.inventoryCode);
    if (invId == null) return;
    final code = row['listing_code']?.toString() ?? '';
    final result = await showPropertyCareOwnerDataSheet(
      context,
      row: row,
      inventoryId: invId,
      inventoryCode: widget.summary.inventoryCode,
    );
    if (result?.saved != true || !mounted) return;
    final s = context.s;
    AppNotice.snack(
      context,
      result!.titleSentForReview
          ? s.careOwnerDataTitleReviewSaved
          : s.careCompleteListingDone(code),
    );
    await widget.onDone();
    await _load();
  }

  Future<void> _markAll() async {
    final invId = widget.summary.right.inventoryId;
    if (invId == null) return;
    setState(() => _busy = true);
    try {
      final n = await _repo.completeOwnerData(
        invId,
        inventoryCode: widget.summary.inventoryCode,
      );
      await widget.onDone();
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.show(context, context.s.careCompleteDataDone(n));
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final code = widget.summary.inventoryCode ?? 'RXT';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.careCompleteDataTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.careCompleteDataIntro(code, widget.summary.pendingDataCount),
            style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.careCompleteDataNote,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_listings.isEmpty)
            Text(
              s.careCompleteDataAllDone,
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ..._listings.map(
              (row) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(row['title']?.toString() ?? row['listing_code']?.toString() ?? ''),
                  subtitle: Text(row['listing_code']?.toString() ?? ''),
                  trailing: TextButton(
                    onPressed: _busy ? null : () => _markOne(row),
                    child: Text(s.careCompleteListingButton),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_busy) const LinearProgressIndicator(),
          if (_listings.isNotEmpty)
            FilledButton.icon(
              onPressed: _busy ? null : _markAll,
              icon: const Icon(Icons.task_alt_outlined),
              label: Text(s.careCompleteDataConfirm),
            ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }
}
