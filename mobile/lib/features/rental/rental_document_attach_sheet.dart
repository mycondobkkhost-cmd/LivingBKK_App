import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../services/auth_service.dart';
import '../../services/rental_lease_service.dart';
import '../../utils/rental_pii_guard.dart';
import 'rental_document_picker.dart';

Future<bool> showRentalDocumentAttachSheet({
  required BuildContext context,
  required RentalLease lease,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _RentalDocumentAttachSheet(lease: lease),
  );
  return result == true;
}

class _RentalDocumentAttachSheet extends StatefulWidget {
  const _RentalDocumentAttachSheet({required this.lease});

  final RentalLease lease;

  @override
  State<_RentalDocumentAttachSheet> createState() =>
      _RentalDocumentAttachSheetState();
}

class _RentalDocumentAttachSheetState extends State<_RentalDocumentAttachSheet> {
  final _fileName = TextEditingController();
  final _note = TextEditingController();
  RentalPickedDocument? _picked;
  bool _busy = false;

  @override
  void dispose() {
    _fileName.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final doc = await pickRentalDocument();
    if (doc == null || !mounted) return;
    setState(() {
      _picked = doc;
      _fileName.text = doc.fileName;
    });
  }

  Future<void> _submit() async {
    final s = context.s;
    final name = _fileName.text.trim();
    if (name.isEmpty) return;

    final combined = _note.text.trim().isEmpty ? name : '${_note.text.trim()}\n$name';
    final ok = await RentalPiiGuard.checkAndAudit(
      leaseId: widget.lease.id,
      channel: 'document',
      text: combined,
    );
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.rentalGroupPiiBlocked)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final actor = AuthService.instance.displayEmail ?? s.rentalMaintenanceTenantLabel;
      await RentalLeaseService.instance.attachContract(
        leaseId: widget.lease.id,
        fileName: name,
        uploadedBy: actor,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        fileBytes: _picked?.bytes,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.rentalDocumentUploadFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.rentalDocumentAttachTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(s.rentalDocumentAttachHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _picked == null
                  ? s.rentalDocumentPickFile
                  : s.rentalDocumentPicked(_picked!.fileName),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fileName,
            decoration: InputDecoration(
              labelText: s.rentalDocumentFileNameLabel,
              hintText: s.rentalDocumentFileNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: s.rentalDocumentNoteLabel,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.rentalDocumentAttachSubmit),
          ),
        ],
      ),
    );
  }
}
