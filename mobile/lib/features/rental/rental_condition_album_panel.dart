import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_album_note.dart';
import '../../models/rental_album_photo.dart';
import '../../models/rental_lease.dart';
import '../../services/auth_service.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/app_theme.dart';

/// อัลบั้มสภาพห้องก่อนเข้าอยู่ — รูปจำนวนมาก (ไม่มีคำกำกับต่อรูป) + โน้ตยาวแบบ LINE
class RentalConditionAlbumPanel extends StatefulWidget {
  const RentalConditionAlbumPanel({
    super.key,
    required this.lease,
    this.isAdmin = false,
  });

  final RentalLease lease;
  final bool isAdmin;

  @override
  State<RentalConditionAlbumPanel> createState() =>
      _RentalConditionAlbumPanelState();
}

class _RentalConditionAlbumPanelState extends State<RentalConditionAlbumPanel> {
  final _service = RentalLeaseService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  RentalLease get _lease =>
      _service.leaseById(widget.lease.id) ?? widget.lease;

  Future<void> _editNote() async {
    final s = context.s;
    final note = _lease.albumNote;
    final bodyCtrl = TextEditingController(text: note?.body ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.85;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
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
                          s.rentalAlbumNoteEditTitle,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(s.rentalAlbumNoteEditHint,
                      style: Theme.of(ctx).textTheme.bodySmall),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: bodyCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: s.rentalAlbumNotePlaceholder,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.rentalAlbumNoteSave),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) {
      bodyCtrl.dispose();
      return;
    }
    final body = bodyCtrl.text;
    bodyCtrl.dispose();
    final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
    await _service.saveAlbumNote(
      leaseId: _lease.id,
      body: body,
      updatedBy: actor,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.rentalAlbumNoteSaved)),
    );
  }

  Future<void> _addPhotosBulk() async {
    final s = context.s;
    final filesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.rentalAlbumAddPhotosBulk),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.rentalAlbumBulkHint, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextField(
                controller: filesCtrl,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: s.rentalAlbumBulkPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.rentalAlbumBulkAdd),
          ),
        ],
      ),
    );
    if (ok != true) {
      filesCtrl.dispose();
      return;
    }
    final names = filesCtrl.text
        .split(RegExp(r'[\n,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    filesCtrl.dispose();
    if (names.isEmpty) return;

    final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
    final n = await _service.addAlbumPhotosBulk(
      leaseId: _lease.id,
      fileNames: names,
      uploadedBy: actor,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.rentalAlbumBulkAdded(n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lease = _lease;
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy HH:mm' : 'd MMM yyyy HH:mm');
    final photos = lease.albumPhotos;
    final note = lease.albumNote;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LineNoteCard(
          note: note,
          dateFmt: fmt,
          isAdmin: widget.isAdmin,
          onEdit: widget.isAdmin ? _editNote : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                s.rentalAlbumPhotosTitle(photos.length),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            if (widget.isAdmin)
              TextButton.icon(
                onPressed: _addPhotosBulk,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(s.rentalAlbumAddPhotosBulk),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(s.rentalAlbumPhotosNoCaption, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        if (photos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(s.rentalAlbumPhotosEmpty, style: Theme.of(context).textTheme.bodySmall),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) {
              final photo = photos[photos.length - 1 - i];
              return _PhotoTile(
                photo: photo,
                isAdmin: widget.isAdmin,
                leaseId: lease.id,
              );
            },
          ),
      ],
    );
  }
}

class _LineNoteCard extends StatelessWidget {
  const _LineNoteCard({
    required this.note,
    required this.dateFmt,
    required this.isAdmin,
    this.onEdit,
  });

  final RentalAlbumNote? note;
  final DateFormat dateFmt;
  final bool isAdmin;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasNote = note != null && !note!.isEmpty;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDE7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: Colors.amber.shade800, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.rentalAlbumNoteTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: s.rentalAlbumNoteEdit,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasNote)
              SelectableText(
                note!.body,
                style: const TextStyle(fontSize: 14, height: 1.5),
              )
            else
              Text(s.rentalAlbumNoteEmpty, style: Theme.of(context).textTheme.bodySmall),
            if (hasNote) ...[
              const SizedBox(height: 10),
              Text(
                s.rentalAlbumNoteUpdated(
                  dateFmt.format(note!.updatedAt),
                  note!.updatedBy,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isAdmin,
    required this.leaseId,
  });

  final RentalAlbumPhoto photo;
  final bool isAdmin;
  final String leaseId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.image_outlined, color: AppTheme.primary.withOpacity(0.35)),
        ),
        if (isAdmin)
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => RentalLeaseService.instance.removeAlbumPhoto(
                  leaseId: leaseId,
                  photoId: photo.id,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
