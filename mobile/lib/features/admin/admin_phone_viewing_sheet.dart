import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/listing_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../intake/intake_flow_config.dart';
import '../intake/standard_intake_flow_sheet.dart';

/// ขั้นที่ 1 — เลือกทรัพย์ + (optional) user id ก่อนเปิดฟอร์มมาตรฐาน
Future<void> showAdminPhoneViewingSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AdminPhoneViewingPickerSheet(),
  );
}

class _AdminPhoneViewingPickerSheet extends StatefulWidget {
  const _AdminPhoneViewingPickerSheet();

  @override
  State<_AdminPhoneViewingPickerSheet> createState() =>
      _AdminPhoneViewingPickerSheetState();
}

class _AdminPhoneViewingPickerSheetState
    extends State<_AdminPhoneViewingPickerSheet> {
  final _listingRepo = ListingRepository();
  final _codeCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  ListingPublic? _listing;
  String? _lookupError;
  bool _lookingUp = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupListing() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _lookingUp = true;
      _lookupError = null;
      _listing = null;
    });
    final found = await _listingRepo.fetchByListingCode(code);
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      _listing = found;
      if (found == null) {
        _lookupError = AppStrings.of(context).adminPhoneViewingListingNotFound;
      }
    });
  }

  Future<void> _continueToIntake() async {
    final listing = _listing;
    if (listing == null) return;
    final nav = Navigator.of(context);
    final intakeListing = AdminIntakeListing(
      listingId: listing.id,
      listingCode: listing.listingCode,
      listingTitle: listing.title,
      projectName: listing.projectName,
    );
    final participantUserId = _userCtrl.text.trim();
    nav.pop();
    if (!context.mounted) return;
    await showAdminPhoneViewingIntake(
      context,
      listing: intakeListing,
      participantUserId: participantUserId.isEmpty ? null : participantUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final listing = _listing;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.adminPhoneViewingPickerTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              s.adminPhoneViewingPickerHint,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: InputDecoration(
                      labelText: s.adminPhoneViewingListingCode,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _lookupListing(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _lookingUp ? null : _lookupListing,
                  child: _lookingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.t('ค้นหา', 'Search')),
                ),
              ],
            ),
            if (_lookupError != null) ...[
              const SizedBox(height: 8),
              Text(
                _lookupError!,
                style: TextStyle(color: AppTheme.error, fontSize: 13),
              ),
            ],
            if (listing != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.listingCode,
                      style: AdminTheme.caption.copyWith(
                        fontFamily: 'monospace',
                        color: AppTheme.primary,
                      ),
                    ),
                    if (listing.projectName != null &&
                        listing.projectName!.isNotEmpty)
                      Text(
                        listing.projectName!,
                        style: AdminTheme.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userCtrl,
                decoration: InputDecoration(
                  labelText: s.adminPhoneViewingParticipantUser,
                  hintText: s.adminPhoneViewingParticipantUserHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _continueToIntake,
                icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                label: Text(s.adminPhoneViewingContinue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
