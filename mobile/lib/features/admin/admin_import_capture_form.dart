import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings.dart';
import '../../services/listing_import_repository.dart';
import '../../theme/admin_theme.dart';

/// ฟอร์มนำเข้าแบบแคปเจอร์ — paste ข้อความ + ลิงก์ + รูปหลักฐาน
class AdminImportCaptureForm extends StatefulWidget {
  const AdminImportCaptureForm({
    super.key,
    required this.onCreated,
  });

  final Future<void> Function(String importId) onCreated;

  @override
  State<AdminImportCaptureForm> createState() => _AdminImportCaptureFormState();
}

class _AdminImportCaptureFormState extends State<AdminImportCaptureForm> {
  final _repo = ListingImportRepository.instance;
  final _sourceText = TextEditingController();
  final _postUrl = TextEditingController();
  final _ownerUrl = TextEditingController();
  final _picker = ImagePicker();

  List<XFile> _evidence = [];
  List<XFile> _listingPhotos = [];
  bool _busy = false;

  @override
  void dispose() {
    _sourceText.dispose();
    _postUrl.dispose();
    _ownerUrl.dispose();
    super.dispose();
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _sourceText.text = text;
    setState(() {});
  }

  Future<void> _pickEvidence() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _evidence = [..._evidence, ...files].take(8).toList());
  }

  Future<void> _pickListingPhotos() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(
      () => _listingPhotos = [..._listingPhotos, ...files].take(12).toList(),
    );
  }

  Future<void> _submit() async {
    final s = context.s;
    final text = _sourceText.text.trim();
    if (text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportCaptureNeedText)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final row = await _repo.createCaptureImport(
        sourceText: text,
        postUrl: _postUrl.text.trim().isEmpty ? null : _postUrl.text.trim(),
        ownerProfileUrl:
            _ownerUrl.text.trim().isEmpty ? null : _ownerUrl.text.trim(),
      );

      if (_evidence.isNotEmpty || _listingPhotos.isNotEmpty) {
        try {
          await _repo.uploadCaptureImages(
            importId: row.id,
            listingId: row.listingId,
            evidence: _evidence,
            listingPhotos: _listingPhotos,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  s.adminImportCaptureEvidenceFailed(
                    ListingImportRepository.friendlyError(e),
                  ),
                ),
              ),
            );
          }
        }
      }

      _sourceText.clear();
      _postUrl.clear();
      _ownerUrl.clear();
      _evidence = [];
      _listingPhotos = [];
      if (!mounted) return;
      await widget.onCreated(row.id);
    } on ListingImportFetchException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      if (e.importId != null) {
        await widget.onCreated(e.importId!);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHint(s.adminImportCaptureIntro),
        const SizedBox(height: 10),
        TextField(
          controller: _sourceText,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: s.adminImportCaptureSourceText,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _pasteClipboard,
            icon: const Icon(Icons.content_paste, size: 18),
            label: Text(s.adminImportPaste),
          ),
        ),
        TextField(
          controller: _postUrl,
          decoration: InputDecoration(
            labelText: s.adminImportCapturePostUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ownerUrl,
          decoration: InputDecoration(
            labelText: s.adminImportCaptureOwnerUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickEvidence,
              icon: const Icon(Icons.screenshot_monitor_outlined, size: 18),
              label: Text(s.adminImportCaptureEvidenceBtn),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickListingPhotos,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(s.adminImportCaptureListingPhotosBtn),
            ),
          ],
        ),
        if (_evidence.isNotEmpty || _listingPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            s.adminImportCaptureSelectedFiles(
              _evidence.length,
              _listingPhotos.length,
            ),
            style: AdminTheme.caption,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(s.adminImportCaptureSubmit),
        ),
      ],
    );
  }
}
