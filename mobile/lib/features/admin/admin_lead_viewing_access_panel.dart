import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/listing_viewing_access.dart';
import '../../services/appointment_repository.dart';
import '../../services/listing_viewing_access_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_viewing_access_section.dart';

/// แก้ไขวิธีเปิดทรัพย์ — ผูกกับประกาศ + โน้ตนัดชม
class AdminLeadViewingAccessPanel extends StatefulWidget {
  const AdminLeadViewingAccessPanel({
    super.key,
    required this.leadId,
    this.listingId,
    this.listingCode,
  });

  final String leadId;
  final String? listingId;
  final String? listingCode;

  @override
  State<AdminLeadViewingAccessPanel> createState() =>
      _AdminLeadViewingAccessPanelState();
}

class _AdminLeadViewingAccessPanelState extends State<AdminLeadViewingAccessPanel> {
  final _accessRepo = ListingViewingAccessRepository();
  final _apptRepo = AppointmentRepository();
  final _noteCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  ListingViewingAccess _access = const ListingViewingAccess();
  Appointment? _appointment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final access = await _accessRepo.fetch(
      listingId: widget.listingId,
      listingCode: widget.listingCode,
    );
    final appt = await _apptRepo.fetchByLeadId(widget.leadId);
    if (!mounted) return;
    _noteCtrl.text = access.note ?? '';
    setState(() {
      _access = access;
      _appointment = appt;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final s = context.s;
    final code = widget.listingCode?.trim();
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminLeadViewingAccessNoListing)),
      );
      return;
    }

    setState(() => _saving = true);
    final next = _access.copyWith(note: _noteCtrl.text);
    try {
      await _accessRepo.save(
        access: next,
        listingId: widget.listingId,
        listingCode: code,
      );

      final linkedNote = s.adminLeadViewingAccessLinkedNote(
        code,
        next.summary(s),
      );
      final appt = _appointment;
      if (appt != null) {
        await _apptRepo.updateAdminNotes(appt.id, linkedNote);
      }

      if (!mounted) return;
      setState(() {
        _access = next;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appt != null
                ? s.adminLeadViewingAccessSavedLinked
                : s.adminLeadViewingAccessSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final code = widget.listingCode?.trim();

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.key_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.adminLeadViewingAccessTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              code != null && code.isNotEmpty
                  ? s.adminLeadViewingAccessLinkedHint(code)
                  : s.adminLeadViewingAccessNoListing,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            if (_access.hasStoredPref) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _access.summary(s),
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ],
            if (_appointment?.adminNotes != null &&
                _appointment!.adminNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.adminLeadViewingAccessApptNote,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _appointment!.adminNotes!,
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            ListingViewingAccessSection(
              value: _access,
              noteController: _noteCtrl,
              onChanged: (v) => setState(() => _access = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(s.adminLeadViewingAccessSave),
            ),
          ],
        ),
      ),
    );
  }
}
