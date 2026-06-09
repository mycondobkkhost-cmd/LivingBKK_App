import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_cast_listing_pins.dart';
import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/chat_room.dart';
import '../../services/appointment_repository.dart';
import '../../services/chat_service.dart';
import '../../services/viewing_appointment_record_service.dart';
import '../../services/viewing_ops_repository.dart';
import '../../utils/admin_routing.dart';
import 'admin_nav_model.dart';

/// แสดงปุ่มยืนยันเอเจ้น — นัด pending หรือ confirmed ที่ระบุคนพาแล้วแต่ยังไม่แจ้ง
bool appointmentNeedsGuideConfirm(Appointment a) {
  final staff = a.assignedTo?.trim();
  if (staff == null || staff.isEmpty) return false;
  if (a.status == 'completed' || a.status == 'cancelled') return false;
  if (a.status == 'pending') return true;
  if (a.status == 'confirmed') {
    final record =
        ViewingAppointmentRecordService.instance.byAppointmentId(a.id);
    return record?.guideStaffId?.trim() != staff;
  }
  return false;
}

String guideConfirmLabel(AppStrings s, Appointment a) =>
    a.status == 'pending' ? s.adminConfirmAppointment : s.adminConfirmGuideAppointment;

void dismissAdminRootOverlays(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  if (!nav.canPop()) return;
  nav.popUntil((route) => route.isFirst);
}

Future<void> openAdminChatRoom(
  BuildContext context,
  String roomId, {
  String? messageId,
  bool dismissOverlays = true,
  AdminNavId? returnNav = AdminNavId.viewingCalendar,
}) async {
  ChatService.instance.ensureViewingLeadChat(roomId);
  if (ChatService.instance.roomById(roomId) == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminCalendarStaffNotifyMissingChat)),
    );
    return;
  }
  final router = GoRouter.of(context);
  if (dismissOverlays) {
    dismissAdminRootOverlays(context);
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
  if (!context.mounted) return;
  final path = adminConsoleChatPath(
    roomId: roomId,
    messageId: messageId,
    returnNav: returnNav,
  );
  if (kIsWeb) {
    router.push(path);
    return;
  }
  final q = <String, String>{};
  if (messageId != null && messageId.isNotEmpty) q['message'] = messageId;
  if (returnNav != null) q[kAdminReturnNavKey] = returnNav.name;
  router.push(
    Uri(path: '/admin/chat/$roomId', queryParameters: q.isEmpty ? null : q)
        .toString(),
  );
}

Future<String?> resolveCustomerThreadId(Appointment a) async {
  final leadId = a.leadId?.trim();
  if (leadId == null || leadId.isEmpty) return null;
  if (leadId.startsWith('demo-lead')) {
    return 'demo-lead-chat-$leadId';
  }
  return ViewingOpsRepository().resolveCustomerThreadId(leadId);
}

Future<void> openCustomerChatForAppointment(
  BuildContext context,
  Appointment a,
) async {
  final roomId = await resolveCustomerThreadId(a);
  if (!context.mounted) return;
  if (roomId == null || roomId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminCalendarStaffNotifyMissingChat)),
    );
    return;
  }
  await openAdminChatRoom(context, roomId);
}

Future<void> openOwnerChatForAppointment(
  BuildContext context,
  Appointment a,
) async {
  final s = context.s;
  final listingCode = a.listingCode?.trim();
  if (listingCode == null || listingCode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminLeadViewingAccessNoListing)),
    );
    return;
  }
  final listingId = a.listingId?.trim() ?? listingCode;
  ChatRoom? room = ChatService.instance.roomForListing(listingCode);
  room ??= ChatService.instance.roomForListing(listingId);
  if (room == null) {
    final title = DemoCastListingPins.titles[listingCode] ?? listingCode;
    try {
      room = await ChatService.instance.openRoom(
        listingId: listingId,
        listingCode: listingCode,
        listingTitle: title,
        projectName: title.split(' · ').first,
      );
    } catch (_) {}
  }
  if (!context.mounted) return;
  if (room != null) {
    await openAdminChatRoom(context, room.id);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.adminRegistryChatTagHint(listingCode))),
  );
}

/// แชทที่แอดมินคุยกับเจ้าของทรัพย์ (ห้องทรัพย์ / listing thread)
Future<void> openAdminOwnerChatForAppointment(
  BuildContext context,
  Appointment a,
) async {
  await openOwnerChatForAppointment(context, a);
}

Future<void> confirmGuideForAppointment(
  BuildContext context, {
  required Appointment appointment,
  required Future<void> Function() onRefresh,
  bool openChatOnNotify = true,
}) async {
  final staffId = appointment.assignedTo?.trim();
  if (staffId == null || staffId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminCalendarConfirmNeedStaff)),
    );
    return;
  }

  final repo = AppointmentRepository();
  final ops = ViewingOpsRepository();
  final s = context.s;

  try {
    await repo.updateStatus(appointment.id, 'confirmed');
    final confirmed = Appointment(
      id: appointment.id,
      leadId: appointment.leadId,
      listingId: appointment.listingId,
      listingCode: appointment.listingCode,
      seekerNickname: appointment.seekerNickname,
      seekerPhone: appointment.seekerPhone,
      scheduledDate: appointment.scheduledDate,
      timeSlot: appointment.timeSlot,
      status: 'confirmed',
      locationLabel: appointment.locationLabel,
      lat: appointment.lat,
      lng: appointment.lng,
      adminNotes: appointment.adminNotes,
      assignedTo: staffId,
      transactionRef: appointment.transactionRef,
      viewingReport: appointment.viewingReport,
    );
    final notify = await ops.notifyGuideAssigned(
      appointment: confirmed,
      s: s,
      staffId: staffId,
      seekerNickname: appointment.seekerNickname,
      seekerPhone: appointment.seekerPhone,
    );
    if (!context.mounted) return;
    if (notify != null && openChatOnNotify) {
      await openAdminChatRoom(
        context,
        notify.roomId,
        messageId: notify.systemMessageId,
      );
      unawaited(onRefresh());
      return;
    }
    await onRefresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notify != null
              ? s.adminCalendarStaffNotifySent
              : '${s.adminConfirmAppointment}\n${s.adminCalendarStaffNotifyMissingChat}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}
