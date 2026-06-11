import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/profile_tag.dart';
import '../../models/viewing_request.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/lead_repository.dart';
import '../../services/viewing_request_service.dart';
import 'profile_tag_picker_sheet.dart';
import 'viewing_schedule_sheet.dart';
import 'viewing_submitted_dialog.dart';

/// Gate นัดดู — ต้องมีแท็กโปรไฟล์ก่อน · แยกวันเวลา · ทวนใน thread + hub
Future<void> showViewingRequestFlow(BuildContext context, ChatRoom room) async {
  final s = context.s;
  final role = await AuthService.instance.fetchProfileRole();
  final isAgent = role == 'agent';

  ProfileTag? presenter;
  ProfileTag? client;

  if (isAgent) {
    presenter = await showProfileTagPickerSheet(
      context,
      role: ProfileTagRole.coAgentPresenter,
      title: s.profileTagPickerPresenter,
    );
    if (!context.mounted || presenter == null) return;

    client = await showProfileTagPickerSheet(
      context,
      role: ProfileTagRole.clientSubject,
      title: s.profileTagPickerClient,
    );
    if (!context.mounted || client == null) return;
  } else {
    client = await showProfileTagPickerSheet(
      context,
      role: ProfileTagRole.seekerSelf,
      title: s.profileTagPickerSeeker,
    );
    if (!context.mounted || client == null) return;
  }

  final schedule = await showViewingScheduleSheet(context);
  if (schedule == null || !context.mounted) return;

  final persisted = await ChatService.instance.ensurePersistedRoom(room);
  final fmt = DateFormat('d/M/yyyy HH:mm');
  final scheduleLabel = fmt.format(schedule.scheduledAt);

  final viewingReq = ViewingRequestService.instance.create(
    listingId: persisted.listingId,
    listingCode: persisted.listingCode,
    listingTitle: persisted.listingTitle,
    projectName: persisted.projectName,
    scheduledAt: schedule.scheduledAt,
    clientTag: client,
    presenterTag: presenter,
    source: isAgent ? ViewingRequestSource.coAgent : ViewingRequestSource.customer,
    threadId: persisted.id,
  );

  final summary = _buildLeadSummary(s, client, presenter, scheduleLabel, persisted, viewingReq.code);

  await ChatService.instance.submitViewingWithTags(
    persisted,
    viewingRequest: viewingReq,
    clientTag: client,
    presenterTag: presenter,
    scheduleLabel: scheduleLabel,
    leadSummary: summary,
  );

  var savedToDatabase = false;
  var leadRef = viewingReq.code;
  try {
    final leadRepo = LeadRepository();
    final outcome = await leadRepo.submit(
      LeadSubmission(
        listingCode: persisted.listingCode,
        listingId: persisted.listingId,
        threadId: persisted.isPersisted ? persisted.id : null,
        seekerNickname: client.snapshot['nickname'] ?? client.snapshot['displayName'] ?? '',
        seekerPhone: client.snapshot['phone'] ?? '',
        applicantType: isAgent ? 'co_agent_request' : 'seeker_self',
        occupation: client.snapshot['occupation'],
        contractDuration: client.snapshot['contract'] ?? '12m',
        viewingSchedule: scheduleLabel,
      ),
    );
    savedToDatabase = outcome.savedToDatabase;
    if (outcome.transactionRef != null && outcome.transactionRef!.isNotEmpty) {
      leadRef = outcome.transactionRef!;
    }
  } catch (e) {
    debugPrint('Lead submit failed after viewing request: $e');
  }

  if (!context.mounted) return;
  await showViewingSubmittedDialog(
    context,
    profileSummary: summary,
    savedToDatabase: savedToDatabase,
    leadRef: leadRef,
    chatRef: persisted.effectiveTransactionRef,
  );
}

Map<String, String> _buildLeadSummary(
  AppStrings s,
  ProfileTag client,
  ProfileTag? presenter,
  String scheduleLabel,
  ChatRoom room,
  String viewingCode,
) {
  return {
    s.summaryNickname: client.snapshot['nickname'] ?? client.snapshot['displayName'] ?? client.code,
    if (client.snapshot['phone'] != null) s.summaryPhone: client.snapshot['phone']!,
    if (presenter != null) s.profileTagPresenterLine: presenter.code,
    s.profileTagClientLine: client.code,
    s.summaryViewing: scheduleLabel,
    s.t('ทรัพย์', 'Property'): '${room.listingCode} · ${room.listingTitle}',
    s.viewingRequestCodeLine: viewingCode,
  };
}
