import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/demo_cast_catalog.dart';
import '../data/demo_cast_simulation.dart';
import '../data/demo_viewing_record_seed.dart';
import '../l10n/app_strings.dart';
import '../models/appointment.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/profile_tag.dart';
import '../models/viewing_appointment_record.dart';
import '../models/viewing_request.dart';
import '../utils/appointment_maps_url.dart';
import '../utils/appointment_staff_labels.dart';
import '../utils/appointment_time_format.dart';
import 'chat_service.dart';
import 'local_prefs_service.dart';
import 'profile_tag_service.dart';
import 'viewing_request_service.dart';

/// แท็กบันทึกการนัดชม — สร้าง snapshot ครบและซิงก์ไปแชท / ฟอร์ม / ข้อมูลลูกค้า
class ViewingAppointmentRecordService {
  ViewingAppointmentRecordService._();
  static final instance = ViewingAppointmentRecordService._();

  static const _prefsKey = 'viewing_appointment_records_v1';
  final _memory = <String, ViewingAppointmentRecord>{};

  Future<void> init() async {
    DemoViewingRecordSeed.ensure();
    await LocalPrefsService.instance.init();
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        if (entry.value is Map) {
          _memory[entry.key.toString()] = ViewingAppointmentRecord.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    } catch (e) {
      debugPrint('ViewingAppointmentRecordService init: $e');
    }
  }

  Future<void> clearAll() async {
    _memory.clear();
    await LocalPrefsService.instance.setString(_prefsKey, '{}');
  }

  ViewingAppointmentRecord? byAppointmentId(String id) => _memory[id];

  ViewingAppointmentRecord? byViewingRequestCode(String code) {
    for (final r in _memory.values) {
      if (r.viewingRequestCode == code) return r;
    }
    return null;
  }

  /// บันทึกนัดที่ยืนยันแล้วในห้องแชท — ใช้ผูกข้อความยืนยันกับนัดที่เพิ่ง confirm
  ViewingAppointmentRecord? latestConfirmedForThread(String threadId) {
    ViewingAppointmentRecord? best;
    for (final r in _memory.values) {
      if (r.threadId != threadId || r.status != 'confirmed') continue;
      if (r.guideStaffId == null || r.guideStaffId!.trim().isEmpty) continue;
      if (best == null || r.updatedAt.isAfter(best.updatedAt)) {
        best = r;
      }
    }
    return best;
  }

  Future<ViewingAppointmentRecord> buildFromAppointment({
    required Appointment appointment,
    String? staffId,
    String? threadId,
    AppStrings? s,
  }) async {
    await init();
    final copy = s ?? AppStrings(false);
    final resolvedThread = threadId ??
        (appointment.leadId != null
            ? 'demo-lead-chat-${appointment.leadId}'
            : null);

    final existing = _memory[appointment.id];
    final vr = _resolveViewingRequest(
      threadId: resolvedThread,
      listingCode: appointment.listingCode,
      appointmentId: appointment.id,
    );

    ProfileTag? clientTag;
    if (vr?.clientTagCode != null) {
      clientTag = ProfileTagService.instance.tagByCode(vr!.clientTagCode);
    }
    final nickFromTag = clientTag?.subjectDisplayName ??
        clientTag?.snapshot['nickname'] ??
        clientTag?.snapshot['displayName'];
    final phoneFromTag = clientTag?.snapshot['phone'];

    final guideName = staffId != null
        ? AppointmentStaffLabels.label(staffId, isEn: copy.isEnglish)
        : existing?.guideName;
    final guidePhone = staffId != null
        ? AppointmentStaffLabels.phone(staffId)
        : existing?.guidePhone;

    return ViewingAppointmentRecord(
      appointmentId: appointment.id,
      transactionRef: appointment.transactionRef ?? existing?.transactionRef,
      viewingRequestCode: vr?.code ?? existing?.viewingRequestCode,
      clientTagCode: vr?.clientTagCode ?? existing?.clientTagCode,
      presenterTagCode: vr?.presenterTagCode ?? existing?.presenterTagCode,
      leadId: appointment.leadId ?? existing?.leadId,
      threadId: resolvedThread ?? vr?.threadId ?? existing?.threadId,
      listingId: appointment.listingId ?? existing?.listingId,
      listingCode: appointment.listingCode ?? existing?.listingCode,
      listingTitle: appointment.listingCode ?? existing?.listingTitle,
      seekerNickname: nickFromTag ?? appointment.seekerNickname,
      seekerPhone: phoneFromTag ?? appointment.seekerPhone ?? existing?.seekerPhone,
      scheduledDate: appointment.scheduledDate,
      timeSlot: appointment.timeSlot,
      status: appointment.status,
      locationLabel: appointment.locationLabel ?? existing?.locationLabel,
      lat: appointment.lat ?? existing?.lat,
      lng: appointment.lng ?? existing?.lng,
      guideStaffId: staffId ?? existing?.guideStaffId,
      guideName: guideName,
      guidePhone: guidePhone,
      clientSnapshot: clientTag?.snapshot ?? existing?.clientSnapshot ?? const {},
      updatedAt: DateTime.now(),
    );
  }

  ViewingRequest? _resolveViewingRequest({
    String? threadId,
    String? listingCode,
    String? appointmentId,
  }) {
    final vrSvc = ViewingRequestService.instance;
    if (appointmentId != null) {
      final byAppt = vrSvc.byAppointmentId(appointmentId);
      if (byAppt != null) return byAppt;
    }
    if (threadId != null && threadId.isNotEmpty) {
      final byThread = vrSvc.byThreadId(threadId);
      if (byThread != null) return byThread;
    }
    if (listingCode != null && listingCode.isNotEmpty) {
      final list = vrSvc.all()
          .where((r) => r.listingCode == listingCode)
          .toList();
      if (list.isNotEmpty) return list.first;
    }
    return null;
  }

  /// ลิงก์ครบทุกอ้างอิง — ใช้เฉพาะหลังบ้าน/รายงาน (มี APPT + PR)
  List<ChatMessageLink> linksForAdminInternal(
    ViewingAppointmentRecord record,
    AppStrings s,
  ) {
    final links = <ChatMessageLink>[];

    final appt = _appointmentFromRecord(record);
    links.addAll(viewingAppointmentLinks(appt, s));
    links.addAll(linksForGuideNotice(record, s));

    final presenterCode = record.presenterTagCode?.trim();
    if (presenterCode != null && presenterCode.isNotEmpty) {
      final tag = ProfileTagService.instance.tagByCode(presenterCode);
      links.add(
        ChatMessageLink.profileTag(
          presenterCode,
          tag?.displayLabel ?? presenterCode,
        ),
      );
    }
    return links;
  }

  /// ลิงก์ในแชทลูกค้า — แผนที่ + VR + แท็กลูกค้า (ไม่มี APPT / PR)
  List<ChatMessageLink> linksForGuideNotice(
    ViewingAppointmentRecord record,
    AppStrings s,
  ) {
    final appt = _appointmentFromRecord(record);
    final links = <ChatMessageLink>[
      ...viewingLocationLinks(appt, s),
    ];

    final vrCode = record.viewingRequestCode?.trim();
    if (vrCode != null && vrCode.isNotEmpty) {
      links.add(ChatMessageLink.viewingRequest(vrCode, vrCode));
    }

    final clientCode = record.clientTagCode?.trim();
    if (clientCode != null && clientCode.isNotEmpty) {
      final tag = ProfileTagService.instance.tagByCode(clientCode);
      links.add(
        ChatMessageLink.profileTag(
          clientCode,
          tag?.displayLabel ?? clientCode,
        ),
      );
    }
    return links;
  }

  Appointment _appointmentFromRecord(ViewingAppointmentRecord r) {
    return Appointment(
      id: r.appointmentId,
      leadId: r.leadId,
      listingId: r.listingId,
      listingCode: r.listingCode,
      seekerNickname: r.seekerNickname,
      seekerPhone: r.seekerPhone,
      scheduledDate: r.scheduledDate,
      timeSlot: r.timeSlot,
      status: r.status,
      locationLabel: r.locationLabel,
      lat: r.lat,
      lng: r.lng,
      assignedTo: r.guideStaffId,
      transactionRef: r.transactionRef,
    );
  }

  String recapText(ViewingAppointmentRecord record, AppStrings s) {
    final d = record.scheduledDate;
    final y = s.isEnglish ? d.year : d.year + 543;
    final schedule =
        '${d.day}/${d.month}/$y · ${formatAppointmentDisplayTime(record.timeSlot)}';
    final property = record.listingCode != null
        ? '${record.listingCode}${record.listingTitle != null ? ' · ${record.listingTitle}' : ''}'
        : (record.listingTitle ?? '—');

    return s.viewingAppointmentRecordRecap(
      propertyLabel: property,
      schedule: schedule,
      place: record.locationLabel ?? record.listingCode ?? '—',
      clientCode: record.clientTagCode ?? '—',
      viewingCode: record.viewingRequestCode ?? '—',
      appointmentRef: record.transactionRef ?? record.appointmentId,
      guideName: record.guideName,
      presenterCode: record.presenterTagCode,
    );
  }

  Future<ViewingAppointmentRecord> syncEverywhere({
    required ViewingAppointmentRecord record,
    ChatRoom? room,
    AppStrings? s,
  }) async {
    final copy = s ?? AppStrings(false);
    final merged = record.copyWith(updatedAt: DateTime.now());
    _memory[merged.appointmentId] = merged;
    await _persist();

    final vrCode = merged.viewingRequestCode;
    if (vrCode != null && vrCode.isNotEmpty) {
      ViewingRequestService.instance.linkAppointment(
        viewingRequestCode: vrCode,
        appointmentId: merged.appointmentId,
        status: merged.status == 'confirmed'
            ? ViewingRequestStatus.ownerConfirmed
            : null,
      );
    }

    if (room != null) {
      _backfillChatRoom(room, merged, copy);
      ChatService.instance.cacheAdminRoom(room);
      ChatService.instance.refreshRooms();
    }

    _backfillHub(merged, copy);
    return merged;
  }

  Future<ViewingAppointmentRecord> buildAndSync({
    required Appointment appointment,
    required String staffId,
    required ChatRoom room,
    required AppStrings s,
  }) async {
    final record = await buildFromAppointment(
      appointment: appointment,
      staffId: staffId,
      threadId: room.id,
      s: s,
    );
    return syncEverywhere(record: record, room: room, s: s);
  }

  Future<void> registerFromViewingForm({
    required ViewingRequest viewingRequest,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required String scheduleLabel,
    required ChatRoom room,
  }) async {
    await init();
    final draft = ViewingAppointmentRecord(
      appointmentId: 'pending-${viewingRequest.code}',
      viewingRequestCode: viewingRequest.code,
      clientTagCode: clientTag.code,
      presenterTagCode: presenterTag?.code,
      leadId: null,
      threadId: room.id,
      listingId: viewingRequest.listingId,
      listingCode: viewingRequest.listingCode,
      listingTitle: viewingRequest.listingTitle,
      seekerNickname: clientTag.snapshot['nickname'] ??
          clientTag.snapshot['displayName'] ??
          clientTag.code,
      seekerPhone: clientTag.snapshot['phone'],
      scheduledDate: viewingRequest.scheduledAt,
      timeSlot: scheduleLabel,
      status: 'pending',
      locationLabel: viewingRequest.projectName,
      clientSnapshot: Map<String, String>.from(clientTag.snapshot),
      updatedAt: DateTime.now(),
    );
    _memory[draft.appointmentId] = draft;
    await _persist();
    _backfillChatRoom(room, draft, AppStrings(false));
    _backfillHub(draft, AppStrings(false));
  }

  void _backfillChatRoom(
    ChatRoom room,
    ViewingAppointmentRecord record,
    AppStrings s,
  ) {
    final vrCode = record.viewingRequestCode;
    final hasFormRecap = room.messages.any((m) {
      if (m.role != ChatMessageRole.system) return false;
      if (m.text.contains('รับคำขอนัดดูแล้ว') ||
          m.text.contains('Viewing received')) {
        return true;
      }
      if (vrCode != null && m.links.any((l) => l.refCode == vrCode)) {
        return true;
      }
      return false;
    });

    if (!hasFormRecap && vrCode != null) {
      final links = _linksForFormRecap(record);
      final d = record.scheduledDate;
      final schedule = DateFormat('d/M/yyyy HH:mm').format(
        DateTime(d.year, d.month, d.day, d.hour, d.minute),
      );
      room.messages.add(
        ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}-vr-recap',
          role: ChatMessageRole.system,
          text: s.viewingTagRecap(
            schedule: schedule,
            clientCode: record.clientTagCode ?? '—',
            viewingCode: vrCode,
          ),
          links: links,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
    }

    room.viewingSubmitted = true;
    room.updatedAt = DateTime.now();
  }

  void _backfillHub(ViewingAppointmentRecord record, AppStrings s) {
    final userId = _hubUserIdForRecord(record);
    if (userId == null) return;

    final hub = ChatService.instance.ensureHubForUser(userId, agent: false);
    final marker = record.viewingRequestCode ?? record.appointmentId;
    final exists = hub.messages.any(
      (m) => m.text.contains(marker) && m.role == ChatMessageRole.system,
    );
    if (exists) return;

    ChatService.instance.appendHubSystemMessage(
      userId: userId,
      agent: false,
      message: ChatMessage(
        id: 'hub-appt-${record.appointmentId}',
        role: ChatMessageRole.system,
        text: recapText(record, s),
        links: linksForGuideNotice(record, s),
        createdAt: DateTime.now(),
      ),
    );
  }

  List<ChatMessageLink> _linksForFormRecap(ViewingAppointmentRecord record) {
    final links = <ChatMessageLink>[];
    final clientCode = record.clientTagCode?.trim();
    if (clientCode != null && clientCode.isNotEmpty) {
      final tag = ProfileTagService.instance.tagByCode(clientCode);
      links.add(
        ChatMessageLink.profileTag(
          clientCode,
          tag?.displayLabel ?? clientCode,
        ),
      );
    }
    final vrCode = record.viewingRequestCode?.trim();
    if (vrCode != null && vrCode.isNotEmpty) {
      links.add(ChatMessageLink.viewingRequest(vrCode, vrCode));
    }
    return links;
  }

  String? _hubUserIdForRecord(ViewingAppointmentRecord record) {
    if (record.leadId != null) {
      for (final lead in DemoCastSimulation.leads()) {
        if (lead['id'] == record.leadId) {
          final castId = lead['seeker_cast_id']?.toString();
          final persona = castId != null ? DemoCastCatalog.find(castId) : null;
          return persona?.profileId;
        }
      }
    }
    final vrCode = record.viewingRequestCode;
    if (vrCode != null) {
      final vr = ViewingRequestService.instance.byCode(vrCode);
      if (vr != null) return vr.createdByUserId;
    }
    final tagCode = record.clientTagCode;
    if (tagCode != null) {
      final tag = ProfileTagService.instance.tagByCode(tagCode);
      if (tag != null) return tag.ownerUserId;
    }
    return null;
  }

  Future<void> _persist() async {
    final map = <String, dynamic>{};
    for (final e in _memory.entries) {
      map[e.key] = e.value.toJson();
    }
    await LocalPrefsService.instance.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> relinkPendingToAppointment({
    required String leadId,
    required Appointment appointment,
    required ChatRoom room,
    AppStrings? s,
  }) async {
    await init();
    final threadId = room.id;
    ViewingAppointmentRecord? pending;
    for (final r in _memory.values) {
      if (r.threadId == threadId && r.appointmentId.startsWith('pending-')) {
        pending = r;
        break;
      }
    }
    if (pending == null) return;

    final upgraded = ViewingAppointmentRecord(
      appointmentId: appointment.id,
      transactionRef: appointment.transactionRef ?? pending.transactionRef,
      viewingRequestCode: pending.viewingRequestCode,
      clientTagCode: pending.clientTagCode,
      presenterTagCode: pending.presenterTagCode,
      leadId: leadId,
      threadId: pending.threadId,
      listingId: appointment.listingId ?? pending.listingId,
      listingCode: appointment.listingCode ?? pending.listingCode,
      listingTitle: pending.listingTitle,
      seekerNickname: appointment.seekerNickname,
      seekerPhone: appointment.seekerPhone ?? pending.seekerPhone,
      scheduledDate: appointment.scheduledDate,
      timeSlot: appointment.timeSlot,
      status: appointment.status,
      locationLabel: appointment.locationLabel ?? pending.locationLabel,
      lat: appointment.lat ?? pending.lat,
      lng: appointment.lng ?? pending.lng,
      clientSnapshot: pending.clientSnapshot,
      updatedAt: DateTime.now(),
    );
    _memory.remove(pending.appointmentId);
    await syncEverywhere(record: upgraded, room: room, s: s);
  }
}
