import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/appointment.dart';
import '../models/chat_message.dart';
import '../utils/appointment_maps_url.dart';
import 'viewing_appointment_record_service.dart';
import '../utils/appointment_time_format.dart';
import 'appointment_repository.dart';
import 'chat_service.dart';
import 'in_app_notification_hub.dart';
import 'local_prefs_service.dart';

/// แจ้งเตือนลูกค้ายืนยันนัดครั้งสุดท้าย — ก่อนเวลานัด 1 ชั่วโมง
abstract final class ViewingFinalConfirmReminderService {
  static const _prefsKey = 'viewing_final_confirm_reminders_v1';
  static const reminderLeadTime = Duration(hours: 1);

  static Future<void> schedule({
    required Appointment appointment,
    required String roomId,
    required AppStrings s,
  }) async {
    if (appointment.status != 'confirmed') return;
    final at = appointment.scheduledDateTime;
    if (at == null) return;
    final fireAt = at.subtract(reminderLeadTime);
    if (fireAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      return;
    }

    await LocalPrefsService.instance.init();
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      } catch (e) {
        debugPrint('ViewingFinalConfirmReminderService parse: $e');
      }
    }

    list.removeWhere((e) => e['appointment_id'] == appointment.id);
    list.add({
      'appointment_id': appointment.id,
      'room_id': roomId,
      'fire_at': fireAt.toIso8601String(),
      'fired': false,
      'time_label': appointment.displayTimeSlot,
      'place': appointment.locationLabel ?? appointment.listingCode ?? '—',
      'maps_url': appointmentMapsUrl(appointment),
      'is_en': s.isEnglish,
    });
    await LocalPrefsService.instance.setString(_prefsKey, jsonEncode(list));
  }

  static Future<void> checkDue({AppStrings? s}) async {
    await LocalPrefsService.instance.init();
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    List<Map<String, dynamic>> list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      list = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    var changed = false;
    final chat = ChatService.instance;

    for (final row in list) {
      if (row['fired'] == true) continue;
      final fireAt = DateTime.tryParse(row['fire_at']?.toString() ?? '');
      if (fireAt == null || now.isBefore(fireAt)) continue;

      final roomId = row['room_id']?.toString() ?? '';
      final timeLabel = row['time_label']?.toString() ?? '';
      final place = row['place']?.toString() ?? '—';
      final isEn = row['is_en'] == true;

      final copy = s ?? AppStrings(isEn);
      final pushText = copy.viewingFinalConfirmReminderPush(
        time: timeLabel,
        place: place,
      );
      final chatText = copy.viewingFinalConfirmReminderChatMessage(
        time: timeLabel,
        place: place,
      );
      final apptId = row['appointment_id']?.toString() ?? '';
      List<ChatMessageLink> noticeLinks;
      if (apptId.isNotEmpty) {
        await ViewingAppointmentRecordService.instance.init();
        var record =
            ViewingAppointmentRecordService.instance.byAppointmentId(apptId);
        final appt = await AppointmentRepository().fetchById(apptId);
        if (record == null && appt != null) {
          record = await ViewingAppointmentRecordService.instance
              .buildFromAppointment(appointment: appt, s: copy);
        }
        noticeLinks = record != null
            ? ViewingAppointmentRecordService.instance.linksForGuideNotice(
                record,
                copy,
              )
            : (appt != null
                ? viewingLocationLinks(appt, copy)
                : viewingLocationLinksFromUrl(
                    row['maps_url']?.toString(),
                    copy,
                  ));
      } else {
        noticeLinks =
            viewingLocationLinksFromUrl(row['maps_url']?.toString(), copy);
      }

      if (roomId.isNotEmpty) {
        chat.ensureViewingLeadChat(roomId);
        final room = chat.roomById(roomId);
        if (room != null) {
          room.messages.add(
            ChatMessage(
              id: '${DateTime.now().microsecondsSinceEpoch}-final-confirm',
              role: ChatMessageRole.system,
              text: chatText,
              requiresAdmin: true,
              links: noticeLinks,
              createdAt: DateTime.now(),
            ),
          );
          room.updatedAt = DateTime.now();
          chat.cacheAdminRoom(room);
          chat.bumpUnread(room.id);
          chat.refreshRooms();
        }
      }

      InAppNotificationHub.instance.show(pushText, countAsUnread: true);
      row['fired'] = true;
      changed = true;
    }

    if (changed) {
      await LocalPrefsService.instance.setString(_prefsKey, jsonEncode(list));
    }
  }

  static Future<void> clearForAppointment(String appointmentId) async {
    await LocalPrefsService.instance.init();
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['appointment_id'] != appointmentId)
          .toList();
      await LocalPrefsService.instance.setString(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }
}
