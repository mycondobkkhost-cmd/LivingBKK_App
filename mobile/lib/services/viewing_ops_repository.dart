import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../models/appointment.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/viewing_report.dart';
import '../utils/appointment_maps_url.dart';
import 'viewing_appointment_record_service.dart';
import '../utils/appointment_staff_labels.dart';
import '../utils/appointment_time_format.dart';
import 'viewing_final_confirm_reminder_service.dart';
import 'demo_cast_bootstrap.dart';
import '../utils/pii_sanitizer.dart';
import 'admin_repository.dart';
import 'appointment_repository.dart';
import 'chat_repository.dart';
import 'chat_service.dart';
import 'supabase_service.dart';
import 'viewing_report_repository.dart';

bool isViewingGuideNoticeMessage(ChatMessage m) =>
    m.role == ChatMessageRole.system &&
    (m.id.endsWith('-guide') ||
        m.text.trim().startsWith('✅ ยืนยันนัดชมทรัพย์'));

/// ผลหลังแจ้งลูกค้าว่ามีเอเจ้นพาดู — ใช้เปิดแชทพร้อมไฮไลต์ข้อความยืนยัน
class ViewingGuideNotifyResult {
  const ViewingGuideNotifyResult({
    required this.roomId,
    this.systemMessageId,
  });

  final String roomId;
  final String? systemMessageId;
}

/// ประสานงานนัดดู — แอดมิน → เจ้าของ / ลูกค้า / บันทึกผลพาชม
class ViewingOpsRepository {
  final _admin = AdminRepository();
  final _chat = ChatRepository();
  final _appts = AppointmentRepository();
  final _reports = ViewingReportRepository();
  final _chatUi = ChatService.instance;

  Future<String?> resolveOwnerId({
    String? listingId,
    String? listingCode,
  }) async {
    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;
    try {
      if (listingId != null && listingId.isNotEmpty) {
        final row = await client
            .from('listings')
            .select('owner_id, created_by_id')
            .eq('id', listingId)
            .maybeSingle();
        if (row != null) {
          return row['owner_id']?.toString() ??
              row['created_by_id']?.toString();
        }
      }
      if (listingCode != null && listingCode.isNotEmpty) {
        final row = await client
            .from('listings')
            .select('owner_id, created_by_id')
            .eq('listing_code', listingCode)
            .maybeSingle();
        if (row != null) {
          return row['owner_id']?.toString() ??
              row['created_by_id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> requestSeniorOwnerCall({
    required String leadId,
    String? appointmentId,
    String? listingCode,
    String? note,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) return;
    try {
      await SupabaseService.client!.functions.invoke(
        'route-lead-notification',
        body: {
          'lead_id': leadId,
          'channel': 'senior_owner_call',
          if (appointmentId != null) 'appointment_id': appointmentId,
          if (listingCode != null) 'listing_code': listingCode,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } catch (_) {}
    if (note != null && note.isNotEmpty && appointmentId != null) {
      try {
        await SupabaseService.client!
            .from('appointments')
            .update({'admin_notes': note})
            .eq('id', appointmentId);
      } catch (_) {}
    }
  }

  Future<void> sendCensoredProfileToOwner({
    required Map<String, dynamic> lead,
    required String listingCode,
    String? listingId,
    String? listingTitle,
    String? projectName,
    String? appointmentDate,
    String? appointmentSlot,
  }) async {
    final leadId = lead['id']?.toString();
    if (leadId == null || leadId.isEmpty) {
      throw Exception('lead_id missing');
    }

    final ownerId = await resolveOwnerId(
      listingId: listingId ?? lead['listing_id']?.toString(),
      listingCode: listingCode,
    );
    if (ownerId == null || ownerId.isEmpty) {
      throw Exception('owner_not_found');
    }

    final qual = lead['qualification_json'] as Map<String, dynamic>?;
    final viewingSchedule = qual?['viewing_schedule']?.toString();

    final summary = PiiSanitizer.ownerSafeLeadSummary(
      lead,
      viewingSchedule: viewingSchedule,
      appointmentDate: appointmentDate,
      appointmentSlot: appointmentSlot,
    );

    final messageText =
        'คำขอนัดดูจากทีม RealXtate ($listingCode)\n'
        'กรุณาพิจารณายืนยันรับเคสตามวันเวลาที่ลูกค้าขอ\n\n'
        '$summary\n\n'
        'หมายเหตุ: ไม่แสดงเบอร์โทร/Line เต็ม — ติดต่อผ่านแพลตฟอร์มเท่านั้น';

    await _chat.notifyOwnerViewingRequest(
      ownerUserId: ownerId,
      listingId: listingId ?? lead['listing_id']?.toString(),
      listingCode: listingCode,
      listingTitle: listingTitle ?? listingCode,
      projectName: projectName,
      messageText: messageText,
      leadId: leadId,
    );

    if (Env.isConfigured && SupabaseService.isReady) {
      try {
        await SupabaseService.client!.functions.invoke(
          'route-lead-notification',
          body: {'lead_id': leadId, 'channel': 'owner_viewing_profile'},
        );
      } catch (_) {}
    }
  }

  Future<String?> resolveCustomerThreadId(String? leadId) async {
    if (leadId == null || leadId.isEmpty) return null;
    if (leadId.startsWith('demo-lead')) return 'demo-lead-chat-$leadId';
    final lead = await _admin.fetchLead(leadId);
    if (lead == null) return null;
    return _admin.resolveLeadThreadId(lead);
  }

  String buildFollowUpChatMessage({
    required AppStrings s,
    required ViewingFollowUpIntent intent,
    required String listingCode,
  }) {
    return s.adminViewingFollowUpChatContinue(
      intent: intent,
      listingCode: listingCode,
    );
  }

  static bool preferDemoChat({String? leadId, String? appointmentId}) {
    if (DemoCastBootstrap.shouldUseCastWorld) return true;
    if (leadId != null && leadId.startsWith('demo-lead')) return true;
    if (appointmentId != null && AppointmentRepository.isDemoId(appointmentId)) {
      return true;
    }
    if (Env.adminDemoCases &&
        (leadId == null || leadId.isEmpty) &&
        appointmentId != null &&
        AppointmentRepository.isDemoId(appointmentId)) {
      return true;
    }
    return false;
  }

  Future<ChatRoom?> _resolveCustomerRoom({
    required String? leadId,
    String? listingId,
    String? listingCode,
    String? listingTitle,
    String? seekerPhone,
    String? seekerNickname,
    String? appointmentId,
  }) async {
    if (preferDemoChat(leadId: leadId, appointmentId: appointmentId)) {
      Map<String, dynamic>? lead;
      if (leadId != null && leadId.isNotEmpty) {
        lead = await _admin.fetchLead(leadId);
      }
      final room = _resolveDemoCustomerRoom(
        leadId: leadId,
        listingCode: listingCode ?? lead?['listing_code']?.toString(),
        listingTitle: listingTitle,
        seekerPhone: seekerPhone ?? lead?['seeker_phone']?.toString(),
        seekerNickname: seekerNickname ?? lead?['seeker_nickname']?.toString(),
      );
      _chatUi.cacheAdminRoom(room);
      return room;
    }

    Map<String, dynamic>? lead;
    if (leadId != null && leadId.isNotEmpty) {
      lead = await _admin.fetchLead(leadId);
    }

    if (Env.isConfigured && SupabaseService.isReady) {
      final room = await _chat.fetchCustomerThreadForLead(
        lead: lead,
        leadId: leadId,
        listingCode: listingCode ?? lead?['listing_code']?.toString(),
        seekerPhone: seekerPhone ?? lead?['seeker_phone']?.toString(),
      );
      if (room != null) {
        _chatUi.cacheAdminRoom(room);
        return room;
      }
      return null;
    }

    return _resolveDemoCustomerRoom(
      leadId: leadId,
      listingCode: listingCode ?? lead?['listing_code']?.toString(),
      listingTitle: listingTitle,
      seekerPhone: seekerPhone ?? lead?['seeker_phone']?.toString(),
      seekerNickname: seekerNickname ?? lead?['seeker_nickname']?.toString(),
    );
  }

  ChatRoom _resolveDemoCustomerRoom({
    String? leadId,
    String? listingCode,
    String? listingTitle,
    String? seekerPhone,
    String? seekerNickname,
  }) {
    final code = listingCode?.trim().isNotEmpty == true
        ? listingCode!.trim()
        : 'DEMO-LISTING';
    final roomKey = leadId != null && leadId.isNotEmpty
        ? 'demo-lead-chat-$leadId'
        : 'demo-listing-chat-$code';

    if (leadId != null && leadId.startsWith('demo-lead')) {
      _chatUi.ensureViewingLeadChat(roomKey);
    } else {
      _chatUi.ensureDemoAdminChatsForPreview();
    }

    var room = _chatUi.roomById(roomKey);
    if (room == null && (leadId == null || !leadId.startsWith('demo-lead'))) {
      room = _chatUi.roomForListing(code);
    }
    if (room == null) {
      room = _chatUi.memoryOpenCustomerRoomForLead(
        roomId: roomKey,
        listingCode: code,
        listingTitle: listingTitle ?? code,
        seekerNickname: seekerNickname,
        seekerUserId: leadId != null ? 'demo-seeker-$leadId' : 'demo-seeker',
      );
    }
    return room;
  }

  Future<void> _postCustomerChat({
    required ChatRoom room,
    String? internalNoteText,
    String? systemNoticeText,
    required bool keepOpen,
  }) async {
    if (Env.isConfigured && SupabaseService.isReady && room.isPersisted) {
      await _chat.postViewingFollowUpNotice(
        room: room,
        internalNoteText: internalNoteText,
        systemNoticeText: systemNoticeText,
        keepOpen: keepOpen,
      );
      _chatUi.cacheAdminRoom(room);
      await _chatUi.refreshAdminInbox();
      if (keepOpen && systemNoticeText != null) {
        _chatUi.bumpUnread(room.id);
      }
      return;
    }
    if (internalNoteText != null && internalNoteText.trim().isNotEmpty) {
      room.messages.add(
        ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}-internal',
          role: ChatMessageRole.adminNotice,
          text: '${ChatMessage.adminInternalPrefix}${internalNoteText.trim()}',
          requiresAdmin: true,
        ),
      );
    }
    if (keepOpen &&
        systemNoticeText != null &&
        systemNoticeText.trim().isNotEmpty) {
      room.messages.add(
        ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}-system',
          role: ChatMessageRole.system,
          text: systemNoticeText.trim(),
          requiresAdmin: true,
        ),
      );
      _chatUi.bumpUnread(room.id);
    }
    if (keepOpen) {
      room.adminReplyDone = false;
      room.adminEscalated = true;
      room.viewingSubmitted = true;
      room.category = 'viewing_request';
      room.status = 'waiting_admin';
      room.priority = 'high';
    }
    room.updatedAt = DateTime.now();
    _chatUi.cacheAdminRoom(room);
    _chatUi.refreshRooms();
  }

  bool _sameGuideLinks(List<ChatMessageLink> a, List<ChatMessageLink> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.kind != y.kind || x.refCode != y.refCode || x.label != y.label) {
        return false;
      }
    }
    return true;
  }

  String _guideNoticeText({
    required Appointment appointment,
    required String staffId,
    required AppStrings s,
  }) {
    final guideName =
        AppointmentStaffLabels.label(staffId, isEn: s.isEnglish);
    final guidePhone = AppointmentStaffLabels.phone(staffId) ?? '—';
    final dateLine = formatAppointmentCustomerDateLine(
      appointment.scheduledDate,
      isEn: s.isEnglish,
    );
    final place = appointment.locationLabel?.trim().isNotEmpty == true
        ? appointment.locationLabel!.trim()
        : (appointment.listingCode ?? '—');
    return s.adminViewingGuideAssignedCustomerNotice(
      dateLine: dateLine,
      timeSlot: appointment.displayTimeSlot,
      place: place,
      guideName: guideName,
      guidePhone: guidePhone,
    );
  }

  Future<Appointment?> _resolveGuideNoticeAppointment(String roomId) async {
    await ViewingAppointmentRecordService.instance.init();
    final record =
        ViewingAppointmentRecordService.instance.latestConfirmedForThread(roomId);
    if (record != null) {
      final fromRecord = await _appts.fetchById(record.appointmentId);
      if (fromRecord != null &&
          fromRecord.assignedTo != null &&
          fromRecord.assignedTo!.trim().isNotEmpty) {
        return fromRecord;
      }
    }
    final leadId = roomId.replaceFirst('demo-lead-chat-', '');
    return _appts.fetchLatestConfirmedByLeadId(leadId);
  }

  /// ซิงก์ข้อความยืนยันนัดในแชท demo ให้ตรงเทมเพลตล่าสุดเสมอ
  Future<bool> refreshGuideNoticeInRoom({
    required String roomId,
    required AppStrings s,
  }) async {
    if (!roomId.startsWith('demo-lead-chat-')) return false;
    final room = _chatUi.roomById(roomId);
    if (room == null) return false;

    final guideIdx = room.messages.lastIndexWhere(isViewingGuideNoticeMessage);
    if (guideIdx < 0) return false;

    final appt = await _resolveGuideNoticeAppointment(roomId);
    final staffId = appt?.assignedTo;
    if (appt == null || staffId == null || staffId.trim().isEmpty) {
      return false;
    }

    final systemText = _guideNoticeText(
      appointment: appt,
      staffId: staffId,
      s: s,
    );
    final existing = room.messages[guideIdx];

    final record = await ViewingAppointmentRecordService.instance.buildAndSync(
      appointment: appt,
      staffId: staffId,
      room: room,
      s: s,
    );
    final noticeLinks =
        ViewingAppointmentRecordService.instance.linksForGuideNotice(record, s);
    final sameText = existing.text.trim() == systemText.trim();
    final sameLinks = _sameGuideLinks(existing.links, noticeLinks);
    if (sameText && sameLinks) return false;

    room.messages[guideIdx] = ChatMessage(
      id: existing.id,
      role: existing.role,
      text: systemText,
      requiresAdmin: existing.requiresAdmin,
      links: noticeLinks,
      createdAt: existing.createdAt,
    );
    _chatUi.cacheAdminRoom(room);
    _chatUi.refreshRooms();
    return true;
  }

  /// แจ้งลูกค้าหลังระบุเอเจ้นพาดู
  Future<ViewingGuideNotifyResult?> notifyGuideAssigned({
    required Appointment appointment,
    required AppStrings s,
    required String staffId,
    String? seekerNickname,
    String? seekerPhone,
  }) async {
    final leadId = appointment.leadId;
    if (leadId == null || leadId.isEmpty) return null;

    final systemText = _guideNoticeText(
      appointment: appointment,
      staffId: staffId,
      s: s,
    );
    final room = await _resolveCustomerRoom(
      leadId: leadId,
      listingId: appointment.listingId,
      listingCode: appointment.listingCode,
      seekerPhone: seekerPhone ?? appointment.seekerPhone,
      seekerNickname: seekerNickname ?? appointment.seekerNickname,
      appointmentId: appointment.id,
    );
    if (room == null) return null;

    final record = await ViewingAppointmentRecordService.instance.buildAndSync(
      appointment: appointment,
      staffId: staffId,
      room: room,
      s: s,
    );
    final noticeLinks =
        ViewingAppointmentRecordService.instance.linksForGuideNotice(record, s);

    final nick = (seekerNickname ?? appointment.seekerNickname)?.trim();
    if (nick != null && nick.isNotEmpty) {
      room.adminDisplayName = nick;
    }

    final useLiveChat =
        Env.isConfigured && SupabaseService.isReady && room.isPersisted &&
            !preferDemoChat(leadId: leadId, appointmentId: appointment.id);

    if (useLiveChat) {
      await _chat.postCustomerSystemNotice(
        room: room,
        text: systemText,
        links: noticeLinks,
      );
      _chatUi.cacheAdminRoom(room);
      await _chatUi.refreshAdminInbox();
      if (!AppointmentRepository.isDemoId(appointment.id)) {
        try {
          await SupabaseService.client!.functions.invoke(
            'notify-appointment',
            body: {'appointment_id': appointment.id},
          );
        } catch (_) {}
      }
      await ViewingFinalConfirmReminderService.schedule(
        appointment: appointment,
        roomId: room.id,
        s: s,
      );
      return ViewingGuideNotifyResult(roomId: room.id);
    } else {
      room.messages.removeWhere(isViewingGuideNoticeMessage);
      final msgId = '${DateTime.now().microsecondsSinceEpoch}-guide';
      room.messages.add(
        ChatMessage(
          id: msgId,
          role: ChatMessageRole.system,
          text: systemText,
          requiresAdmin: true,
          links: noticeLinks,
          createdAt: DateTime.now(),
        ),
      );
      room.updatedAt = DateTime.now();
      room.viewingSubmitted = true;
      room.adminEscalated = true;
      room.adminReplyDone = false;
      _chatUi.cacheAdminRoom(room);
      _chatUi.bumpUnread(room.id);
      _chatUi.refreshRooms();
      await ViewingFinalConfirmReminderService.schedule(
        appointment: appointment,
        roomId: room.id,
        s: s,
      );
      return ViewingGuideNotifyResult(roomId: room.id, systemMessageId: msgId);
    }
  }

  /// บันทึกผลหลังพาชม — แชทลูกค้าเฉพาะ「ติดตามต่อ」เท่านั้น
  Future<String?> recordViewingReport({
    required Appointment appointment,
    required ViewingReportSheetResult input,
    required AppStrings s,
    String? listingTitle,
    String? seekerNickname,
    String? seekerPhone,
  }) async {
    final leadId = appointment.leadId;
    if (leadId == null || leadId.isEmpty) {
      throw Exception('lead_id missing');
    }

    final noShow = input.outcome.contains('ลูกค้าไม่มา') ||
        input.outcome.toLowerCase().contains('no-show') ||
        input.outcome.toLowerCase().contains('no show');
    final keepOpen =
        !noShow && input.decision == ViewingFollowUpDecision.continueFollow;
    final intentKey = switch (input.intent) {
      ViewingFollowUpIntent.consider => 'consider',
      ViewingFollowUpIntent.findMore => 'find_more',
      ViewingFollowUpIntent.both => 'both',
      null => null,
    };

    final report = ViewingReport(
      id: 'report-${appointment.id}-${DateTime.now().millisecondsSinceEpoch}',
      appointmentId: appointment.id,
      leadId: leadId,
      listingId: appointment.listingId,
      listingCode: appointment.listingCode,
      locationLabel: appointment.locationLabel,
      viewedDate: appointment.scheduledDate,
      timeSlot: appointment.timeSlot,
      guideStaffId: appointment.assignedTo,
      outcome: input.outcome,
      customerFeedback: input.customerFeedback,
      customerWants: input.customerWants,
      teamNotes: input.teamNotes,
      decision: keepOpen ? 'continue' : 'closed',
      intent: intentKey,
      seekerNickname: seekerNickname,
      seekerPhone: seekerPhone,
      recordedAt: DateTime.now(),
    );

    await _reports.save(report);

    final adminNote = s.adminViewingReportAdminNoteSummary(
      outcome: input.outcome,
      feedback: input.customerFeedback,
      wants: input.customerWants,
      decision: keepOpen ? 'continue' : 'closed',
    );
    final mergedNotes = [
      if (appointment.adminNotes != null && appointment.adminNotes!.trim().isNotEmpty)
        appointment.adminNotes!.trim(),
      adminNote,
    ].join('\n');

    await _appts.updateViewingReport(
      appointment.id,
      report: report,
      adminNotes: mergedNotes,
      status: keepOpen ? appointment.status : 'completed',
    );

    if (noShow) {
      return null;
    }

    String? roomId;
    if (keepOpen && input.intent != null) {
      final systemText = buildFollowUpChatMessage(
        s: s,
        intent: input.intent!,
        listingCode: appointment.listingCode ?? '',
      );
      final internalNote = s.adminViewingReportChatInternalNote(
        outcome: input.outcome,
        feedback: input.customerFeedback,
        wants: input.customerWants,
        teamNotes: input.teamNotes,
        timeSlot: appointment.timeSlot,
        viewedDate: appointment.scheduledDate,
      );
      try {
        final room = await _resolveCustomerRoom(
          leadId: leadId,
          listingId: appointment.listingId,
          listingCode: appointment.listingCode,
          listingTitle: listingTitle,
          seekerPhone: seekerPhone ?? appointment.seekerPhone,
          seekerNickname: seekerNickname ?? appointment.seekerNickname,
        );
        if (room != null) {
          await _postCustomerChat(
            room: room,
            internalNoteText: internalNote,
            systemNoticeText: systemText,
            keepOpen: true,
          );
          roomId = room.id;
        }
      } catch (_) {}
    }

    return roomId;
  }
}
