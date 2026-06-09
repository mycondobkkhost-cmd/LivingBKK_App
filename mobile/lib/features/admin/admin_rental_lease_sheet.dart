import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_contract_attachment.dart';
import '../../models/rental_lease.dart';
import '../../services/auth_service.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../rental/rental_lease_dates_display.dart';

Future<void> showAdminRentalLeaseSheet({
  required BuildContext context,
  required RentalLease lease,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AdminRentalLeaseSheet(leaseId: lease.id),
  );
}

class _AdminRentalLeaseSheet extends StatefulWidget {
  const _AdminRentalLeaseSheet({required this.leaseId});

  final String leaseId;

  @override
  State<_AdminRentalLeaseSheet> createState() => _AdminRentalLeaseSheetState();
}

class _AdminRentalLeaseSheetState extends State<_AdminRentalLeaseSheet> {
  final _service = RentalLeaseService.instance;
  late DateTime _contractSignedAt;
  late DateTime _leaseStart;
  DateTime? _leaseEnd;
  bool _saving = false;

  RentalLease? get _lease => _service.leaseById(widget.leaseId);

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _service.ensureLoaded().then((_) {
      if (!mounted) return;
      final lease = _lease;
      if (lease == null) return;
      setState(() {
        _contractSignedAt = lease.contractSignedAt ?? lease.leaseStart;
        _leaseStart = lease.leaseStart;
        _leaseEnd = lease.leaseEnd;
      });
    });
    final lease = _service.leaseById(widget.leaseId);
    _contractSignedAt = lease?.contractSignedAt ?? lease?.leaseStart ?? DateTime.now();
    _leaseStart = lease?.leaseStart ?? DateTime.now();
    _leaseEnd = lease?.leaseEnd;
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate({
    required DateTime initial,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveDates() async {
    setState(() => _saving = true);
    await _service.updateLeaseDates(
      leaseId: widget.leaseId,
      contractSignedAt: _contractSignedAt,
      leaseStart: _leaseStart,
      leaseEnd: _leaseEnd,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminRentalDatesSaved)),
    );
  }

  Future<void> _attachContract() async {
    final s = context.s;
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminRentalAttachContract),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.adminRentalAttachContractHint, style: AdminTheme.caption),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: s.adminRentalAttachFileName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.adminRentalAttachNote,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminRentalAttachSave),
          ),
        ],
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      noteCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    nameCtrl.dispose();
    if (name.isEmpty) return;

    final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
    await _service.attachContract(
      leaseId: widget.leaseId,
      fileName: name,
      uploadedBy: actor,
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRentalAttachDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lease = _lease;
    if (lease == null) return const SizedBox.shrink();
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminRentalLeaseSheetTitle,
                      style: AdminTheme.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(lease.listingCode, style: AdminTheme.caption),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(lease.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(s.adminRentalDatesSection, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  _DateTile(
                    label: s.rentalContractSignedLabel.trim(),
                    value: fmt.format(_contractSignedAt),
                    onTap: () => _pickDate(
                      initial: _contractSignedAt,
                      onPicked: (d) => setState(() => _contractSignedAt = d),
                    ),
                  ),
                  _DateTile(
                    label: s.rentalLeaseStartLabel.trim(),
                    value: fmt.format(_leaseStart),
                    onTap: () => _pickDate(
                      initial: _leaseStart,
                      onPicked: (d) => setState(() => _leaseStart = d),
                    ),
                  ),
                  _DateTile(
                    label: s.rentalLeaseEndLabel.trim(),
                    value: _leaseEnd != null ? fmt.format(_leaseEnd!) : s.adminRentalNoEndDate,
                    onTap: () => _pickDate(
                      initial: _leaseEnd ?? _leaseStart.add(const Duration(days: 365)),
                      onPicked: (d) => setState(() => _leaseEnd = d),
                    ),
                    onClear: _leaseEnd != null
                        ? () => setState(() => _leaseEnd = null)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveDates,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(s.adminRentalSaveDates),
                  ),
                  const SizedBox(height: 20),
                  Text(s.adminRentalContractFilesSection, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  Text(s.adminRentalAttachContractHint, style: AdminTheme.caption),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _attachContract,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(s.adminRentalAttachContract),
                  ),
                  const SizedBox(height: 12),
                  if (lease.contractAttachments.isEmpty)
                    Text(s.adminRentalNoContractFiles, style: AdminTheme.hint)
                  else
                    ...lease.contractAttachments.reversed.map(
                      (a) => _AttachmentTile(
                        leaseId: widget.leaseId,
                        attachment: a,
                        dateFmt: fmt,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(s.adminRentalPreviewDates, style: AdminTheme.caption),
                  const SizedBox(height: 6),
                  RentalLeaseDatesDisplay(
                    lease: lease,
                    dateFmt: fmt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 20),
              tooltip: context.s.adminRentalClearDate,
            ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.leaseId,
    required this.attachment,
    required this.dateFmt,
  });

  final String leaseId;
  final RentalContractAttachment attachment;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: AppTheme.primary),
        title: Text(attachment.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            dateFmt.format(attachment.uploadedAt),
            attachment.uploadedBy,
            if (attachment.note != null) attachment.note!,
          ].join('\n'),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await RentalLeaseService.instance.removeAttachment(
              leaseId: leaseId,
              attachmentId: attachment.id,
            );
          },
          tooltip: s.delete,
        ),
      ),
    );
  }

}
