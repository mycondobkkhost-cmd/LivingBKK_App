import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/availability_alert.dart';
import '../../models/availability_contact_record.dart';
import '../../models/vault_asset.dart';
import '../../services/auth_service.dart';
import '../../services/availability_follow_up_service.dart';
import '../../services/availability_hidden_registry_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../theme/admin_theme.dart';
import 'admin_registry_edit_sheet.dart';

Future<void> showAvailabilityContactHistory({
  required BuildContext context,
  required AvailabilityAlertItem item,
}) async {
  final s = context.s;
  final followUp = AvailabilityFollowUpService.instance.stateFor(item.listingId);
  final fmt = DateFormat('d MMM yyyy HH:mm');
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.adminAvailabilityContactHistoryTitle),
      content: SizedBox(
        width: 420,
        child: followUp.contacts.isEmpty
            ? Text(s.adminAvailabilityContactHistoryEmpty, style: AdminTheme.hint)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: followUp.contacts.reversed.map((c) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_channelIcon(c.channel), size: 20),
                      title: Text(
                        _channelLabel(s, c.channel),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          fmt.format(c.at.toLocal()),
                          if (c.note != null && c.note!.isNotEmpty) c.note!,
                          if (c.actor != null && c.actor!.isNotEmpty) c.actor!,
                        ].join('\n'),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
      ],
    ),
  );
}

String _channelLabel(AppStrings s, AvailabilityContactChannel ch) =>
    switch (ch) {
      AvailabilityContactChannel.inAppChat =>
        s.adminAvailabilityContactChannelChat,
      AvailabilityContactChannel.externalPhone =>
        s.adminAvailabilityContactChannelPhone,
      AvailabilityContactChannel.other =>
        s.adminAvailabilityContactChannelOther,
    };

IconData _channelIcon(AvailabilityContactChannel ch) => switch (ch) {
      AvailabilityContactChannel.inAppChat => Icons.chat_outlined,
      AvailabilityContactChannel.externalPhone => Icons.phone_in_talk_outlined,
      AvailabilityContactChannel.other => Icons.more_horiz,
    };

Future<bool> showRecordExternalCallDialog({
  required BuildContext context,
  required AvailabilityAlertItem item,
}) async {
  final s = context.s;
  final noteCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.adminAvailabilityRecordCallTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.adminAvailabilityRecordCallHint, style: AdminTheme.caption),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.adminAvailabilityRecordCallNote,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.adminAvailabilityRecordCallSave),
        ),
      ],
    ),
  );
  if (ok != true) {
    noteCtrl.dispose();
    return false;
  }
  final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
  await AvailabilityFollowUpService.instance.recordContact(
    listingId: item.listingId,
    channel: AvailabilityContactChannel.externalPhone,
    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    actor: actor,
  );
  noteCtrl.dispose();
  return true;
}

Future<bool> showStopFollowUpDialog({
  required BuildContext context,
  required AvailabilityAlertItem item,
}) async {
  final s = context.s;
  final reasonCtrl = TextEditingController(
    text: s.adminAvailabilityStopFollowUpDefaultReason,
  );
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.adminAvailabilityStopFollowUpTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.adminAvailabilityStopFollowUpHint, style: AdminTheme.caption),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.adminAvailabilityStopFollowUpReason,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: Text(s.adminAvailabilityStopFollowUpConfirm),
        ),
      ],
    ),
  );
  if (ok != true) {
    reasonCtrl.dispose();
    return false;
  }
  final reason = reasonCtrl.text.trim();
  reasonCtrl.dispose();
  if (reason.isEmpty) return false;

  final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
  final hidden = AvailabilityHiddenRegistryService.instance;
  final ops = RegistryAssetOpsService.instance;
  final followUp = AvailabilityFollowUpService.instance;

  await followUp.stopFollowUp(listingId: item.listingId, reason: reason);
  await hidden.archive(HiddenRegistryEntry.fromAlert(item, reason: reason));
  ops.markOwnerUnreachable(
    entityType: 'listing',
    entityId: item.listingId,
    actor: actor,
    reason: reason,
  );
  return true;
}

Future<void> openAvailabilityListingEdit({
  required BuildContext context,
  required AvailabilityAlertItem item,
}) async {
  final ops = RegistryAssetOpsService.instance;
  final summary = VaultAssetSummary(
    id: item.listingId,
    entityType: 'listing',
    entityId: item.listingId,
    listingId: item.listingId,
    listingCode: item.listingCode,
    titlePreview: item.title,
  );
  await showRegistryEditSheet(
    context: context,
    summary: summary,
    initialTitle: ops.titleFor(
          entityType: 'listing',
          entityId: item.listingId,
        ) ??
        item.title,
    initialDescription: ops.descriptionFor(
          entityType: 'listing',
          entityId: item.listingId,
        ) ??
        '',
  );
}
