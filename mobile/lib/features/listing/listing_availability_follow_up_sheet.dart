import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'close_listing_sheet.dart';

enum ListingAvailabilityFollowUpAction {
  republishEarly,
  remindLater,
  updateDate,
  permanentClose,
}

class ListingAvailabilityFollowUpResult {
  const ListingAvailabilityFollowUpResult(
    this.action, {
    this.newDate,
    this.permanentResult,
  });

  final ListingAvailabilityFollowUpAction action;
  final DateTime? newDate;
  final CloseListingRentResult? permanentResult;
}

Future<ListingAvailabilityFollowUpResult?> showListingAvailabilityFollowUpSheet(
  BuildContext context, {
  required String listingTitle,
  required DateTime availableAgain,
  required int daysUntil,
}) {
  return showModalBottomSheet<ListingAvailabilityFollowUpResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _Body(
      listingTitle: listingTitle,
      availableAgain: availableAgain,
      daysUntil: daysUntil,
    ),
  );
}

class _Body extends StatefulWidget {
  const _Body({
    required this.listingTitle,
    required this.availableAgain,
    required this.daysUntil,
  });

  final String listingTitle;
  final DateTime availableAgain;
  final int daysUntil;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _dateLabel(AppStrings s) {
    final d = widget.availableAgain;
    return '${d.day}/${d.month}/${d.year + 543}';
  }

  Future<void> _pickNewDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.availableAgain,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      Navigator.pop(
        context,
        ListingAvailabilityFollowUpResult(
          ListingAvailabilityFollowUpAction.updateDate,
          newDate: picked,
        ),
      );
    }
  }

  Future<void> _permanentClose() async {
    final result = await showCloseListingRentSheet(context, listingType: 'rent');
    if (result == null || !result.permanent || !mounted) return;
    Navigator.pop(
      context,
      ListingAvailabilityFollowUpResult(
        ListingAvailabilityFollowUpAction.permanentClose,
        permanentResult: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.listingAvailabilityReminderTitle(widget.daysUntil),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.listingAvailabilityReminderBody(
              widget.listingTitle,
              _dateLabel(s),
            ),
            style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          _action(
            icon: Icons.campaign_outlined,
            title: s.listingAvailabilityRepublishEarly,
            subtitle: s.listingAvailabilityRepublishEarlyHint,
            onTap: () => Navigator.pop(
              context,
              const ListingAvailabilityFollowUpResult(
                ListingAvailabilityFollowUpAction.republishEarly,
              ),
            ),
          ),
          _action(
            icon: Icons.schedule_outlined,
            title: s.listingAvailabilityRemindLater,
            subtitle: s.listingAvailabilityRemindLaterHint,
            onTap: () => Navigator.pop(
              context,
              const ListingAvailabilityFollowUpResult(
                ListingAvailabilityFollowUpAction.remindLater,
              ),
            ),
          ),
          _action(
            icon: Icons.edit_calendar_outlined,
            title: s.listingAvailabilityUpdateDate,
            subtitle: s.listingAvailabilityUpdateDateHint,
            onTap: _pickNewDate,
          ),
          _action(
            icon: Icons.block_outlined,
            title: s.listingAvailabilityPermanentClose,
            subtitle: s.listingAvailabilityPermanentCloseHint,
            onTap: _permanentClose,
            danger: true,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: danger ? AppTheme.accentDeep : null,
          side: BorderSide(
            color: danger
                ? AppTheme.accentDeep.withOpacity(0.4)
                : AppTheme.textSecondary.withOpacity(0.2),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
