import '../config/env.dart';
import '../data/demo_calendar_events.dart';
import '../models/appointment.dart';
import '../models/calendar_event.dart';
import '../utils/calendar_field_locks.dart';
import 'supabase_service.dart';

class CalendarEventRepository {
  static List<CalendarEvent>? _demoStore;

  static bool isDemoId(String id) => id.startsWith('demo-cal');

  static void resetDemoStore() {
    _demoStore = null;
  }

  static List<CalendarEvent> _demoMutable() {
    _demoStore ??= DemoCalendarEvents.build();
    return _demoStore!;
  }

  Future<List<CalendarEvent>> fetchRange({
    required DateTime from,
    required DateTime to,
    int limit = 300,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return _demoMutable()
          .where(
            (e) =>
                e.status != 'cancelled' &&
                !e.startAt.isBefore(from) &&
                e.startAt.isBefore(to.add(const Duration(days: 1))),
          )
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    final rows = await SupabaseService.client!
        .from('calendar_events')
        .select()
        .gte('start_at', from.toUtc().toIso8601String())
        .lt('start_at', to.add(const Duration(days: 1)).toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .order('start_at')
        .limit(limit);

    return (rows as List)
        .map((r) => CalendarEvent.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<List<CalendarEvent>> fetchUpcoming({int limit = 200}) async {
    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now().add(const Duration(days: 120));
    return fetchRange(from: from, to: to, limit: limit);
  }

  Future<CalendarEvent?> fetchById(String id) async {
    if (isDemoId(id) || !Env.isConfigured || !SupabaseService.isReady) {
      for (final e in _demoMutable()) {
        if (e.id == id) return e;
      }
      return null;
    }
    final row = await SupabaseService.client!
        .from('calendar_events')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return CalendarEvent.fromJson(Map<String, dynamic>.from(row));
  }

  /// มนุษย์แก้ไข — lock ฟิลด์ที่เปลี่ยน + bump version
  Future<CalendarEvent> updateHuman({
    required CalendarEvent current,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    String? locationLabel,
    String? ownerNotes,
    String? seekerNotes,
    String? colorHint,
    String? actorUserId,
  }) async {
    final before = CalendarFieldLocks.snapshot(current);
    final next = current.copyWith(
      title: title ?? current.title,
      description: description ?? current.description,
      startAt: startAt ?? current.startAt,
      endAt: endAt ?? current.endAt,
      locationLabel: locationLabel ?? current.locationLabel,
      ownerNotes: ownerNotes ?? current.ownerNotes,
      seekerNotes: seekerNotes ?? current.seekerNotes,
      colorHint: colorHint ?? current.colorHint,
      humanEditedAt: DateTime.now(),
      humanEditedBy: actorUserId,
      version: current.version + 1,
    );
    final after = CalendarFieldLocks.snapshot(next);
    final locks = CalendarFieldLocks.lockChangedFields(
      existing: current.fieldLocks,
      before: before,
      after: after,
    );
    final patched = next.copyWith(fieldLocks: locks);

    if (isDemoId(current.id) ||
        !Env.isConfigured ||
        !SupabaseService.isReady) {
      final store = _demoMutable();
      final i = store.indexWhere((e) => e.id == current.id);
      if (i >= 0) store[i] = patched;
      return patched;
    }

    final row = await SupabaseService.client!
        .from('calendar_events')
        .update({
          'title': patched.title,
          'description': patched.description,
          'start_at': patched.startAt.toUtc().toIso8601String(),
          'end_at': patched.endAt.toUtc().toIso8601String(),
          'location_label': patched.locationLabel,
          'owner_notes': patched.ownerNotes,
          'seeker_notes': patched.seekerNotes,
          'color_hint': patched.colorHint,
          'field_locks': patched.fieldLocks,
          'version': patched.version,
          'human_edited_at': patched.humanEditedAt?.toUtc().toIso8601String(),
          'human_edited_by': actorUserId,
        })
        .eq('id', current.id)
        .eq('version', current.version)
        .select()
        .maybeSingle();

    if (row == null) {
      throw CalendarVersionConflictException();
    }
    return CalendarEvent.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CalendarEvent> confirmDraft(CalendarEvent current) async {
    return updateStatus(current, 'confirmed', syncExternal: true);
  }

  Future<CalendarEvent> updateStatus(
    CalendarEvent current,
    String status, {
    bool syncExternal = false,
  }) async {
    if (isDemoId(current.id) ||
        !Env.isConfigured ||
        !SupabaseService.isReady) {
      final store = _demoMutable();
      final i = store.indexWhere((e) => e.id == current.id);
      final patched = current.copyWith(status: status, version: current.version + 1);
      if (i >= 0) store[i] = patched;
      return patched;
    }

    final row = await SupabaseService.client!
        .from('calendar_events')
        .update({
          'status': status,
          'version': current.version + 1,
        })
        .eq('id', current.id)
        .eq('version', current.version)
        .select()
        .maybeSingle();

    if (row == null) throw CalendarVersionConflictException();
    final out = CalendarEvent.fromJson(Map<String, dynamic>.from(row));
    if (syncExternal) {
      await _syncExternal(out.id);
    }
    return out;
  }

  Future<void> discardDraft(String id) async {
    final ev = await fetchById(id);
    if (ev == null) return;
    await updateStatus(ev, 'cancelled');
  }

  /// เรียก Edge AI สร้าง/รีเฟรช draft
  Future<CalendarEvent?> runAiDraft({
    String? threadId,
    String? leadId,
    String? appointmentId,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return _demoAiRefresh(threadId: threadId, leadId: leadId);
    }

    final res = await SupabaseService.client!.functions.invoke(
      'calendar-ai-draft',
      body: {
        if (threadId != null) 'thread_id': threadId,
        if (leadId != null) 'lead_id': leadId,
        if (appointmentId != null) 'appointment_id': appointmentId,
      },
    );
    if (res.data is! Map) return null;
    final map = Map<String, dynamic>.from(res.data as Map);
    final event = map['event'];
    if (event is! Map) return null;
    return CalendarEvent.fromJson(Map<String, dynamic>.from(event));
  }

  CalendarEvent? _demoAiRefresh({String? threadId, String? leadId}) {
    final store = _demoMutable();
    final match = store.where(
      (e) =>
          e.isAiDraft &&
          ((threadId != null && e.threadId == threadId) ||
              (leadId != null && e.leadId == leadId)),
    );
    if (match.isEmpty) return store.where((e) => e.isAiDraft).firstOrNull;
    final e = match.first;
    final i = store.indexOf(e);
    final refreshed = e.copyWith(
      aiLastRunAt: DateTime.now(),
      description: '${e.description ?? ''}\n🤖 AI อัปเดต ${DateTime.now().hour}:${DateTime.now().minute}',
    );
    store[i] = refreshed;
    return refreshed;
  }

  /// สร้าง/อัปเดต calendar event จากนัดที่ยืนยันแล้ว
  Future<CalendarEvent?> syncFromAppointment(Appointment appt) async {
    final times = _parseAppointmentTimes(appt);
    final title = '${appt.seekerNickname}นัดดูห้อง';
    final existing = await _findByAppointmentId(appt.id);

    if (existing != null) {
      if (CalendarFieldLocks.isLocked(existing.fieldLocks, 'start_at')) {
        return existing;
      }
      return updateHuman(
        current: existing,
        title: title,
        description: appt.adminNotes,
        startAt: times.$1,
        endAt: times.$2,
        locationLabel: appt.locationLabel,
      );
    }

    final draft = CalendarEvent(
      id: isDemoId(appt.id) ? 'demo-cal-${appt.id}' : '',
      eventType: 'viewing',
      status: appt.status == 'confirmed' ? 'confirmed' : 'pending',
      title: title,
      description: appt.adminNotes,
      startAt: times.$1,
      endAt: times.$2,
      colorHint: 'red',
      leadId: appt.leadId,
      listingId: appt.listingId,
      listingCode: appt.listingCode,
      appointmentId: appt.id,
      locationLabel: appt.locationLabel,
      lat: appt.lat,
      lng: appt.lng,
      assignedTo: appt.assignedTo,
      version: 1,
    );

    if (isDemoId(appt.id) || !Env.isConfigured || !SupabaseService.isReady) {
      final id = draft.id.isEmpty ? 'demo-cal-${appt.id}' : draft.id;
      final stored = CalendarEvent(
        id: id,
        eventType: draft.eventType,
        status: draft.status,
        title: draft.title,
        description: draft.description,
        startAt: draft.startAt,
        endAt: draft.endAt,
        colorHint: draft.colorHint,
        leadId: draft.leadId,
        listingId: draft.listingId,
        listingCode: draft.listingCode,
        appointmentId: draft.appointmentId,
        locationLabel: draft.locationLabel,
        lat: draft.lat,
        lng: draft.lng,
        assignedTo: draft.assignedTo,
        version: 1,
      );
      _demoMutable().removeWhere((e) => e.appointmentId == appt.id);
      _demoMutable().add(stored);
      return stored;
    }

    final uid = SupabaseService.client!.auth.currentUser?.id;
    final row = await SupabaseService.client!
        .from('calendar_events')
        .insert({
          'event_type': 'viewing',
          'status': draft.status,
          'title': draft.title,
          'description': draft.description,
          'start_at': draft.startAt.toUtc().toIso8601String(),
          'end_at': draft.endAt.toUtc().toIso8601String(),
          'color_hint': 'red',
          'lead_id': draft.leadId,
          'listing_id': draft.listingId,
          'listing_code': draft.listingCode,
          'appointment_id': draft.appointmentId,
          'location_label': draft.locationLabel,
          'lat': draft.lat,
          'lng': draft.lng,
          'assigned_to': draft.assignedTo,
          'created_by': uid,
        })
        .select()
        .single();

    final created = CalendarEvent.fromJson(Map<String, dynamic>.from(row));
    await _syncExternal(created.id);
    return created;
  }

  Future<CalendarEvent?> _findByAppointmentId(String appointmentId) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      for (final e in _demoMutable()) {
        if (e.appointmentId == appointmentId) return e;
      }
      return null;
    }
    final row = await SupabaseService.client!
        .from('calendar_events')
        .select()
        .eq('appointment_id', appointmentId)
        .neq('status', 'cancelled')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return CalendarEvent.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> _syncExternal(String calendarEventId) async {
    if (!Env.isConfigured || !SupabaseService.isReady) return;
    try {
      await SupabaseService.client!.functions.invoke(
        'calendar-event-sync',
        body: {'calendar_event_id': calendarEventId},
      );
    } catch (_) {
      // best-effort
    }
  }

  (DateTime, DateTime) _parseAppointmentTimes(Appointment appt) {
    final d = appt.scheduledDate;
    final slot = appt.timeSlot.replaceAll('–', '-');
    final parts = slot.split('-').map((s) => s.trim()).toList();
    final start = _parseClock(parts.isNotEmpty ? parts.first : '10:00', d);
    final end = _parseClock(parts.length > 1 ? parts[1] : '11:00', d);
    return (start, end.isAfter(start) ? end : start.add(const Duration(hours: 1)));
  }

  DateTime _parseClock(String raw, DateTime day) {
    final m = RegExp(r'(\d{1,2})[:\.]?(\d{2})?').firstMatch(raw);
    final h = m != null ? int.parse(m.group(1)!) : 10;
    final min = m != null ? int.parse(m.group(2) ?? '0') : 0;
    return DateTime(day.year, day.month, day.day, h, min);
  }
}

class CalendarVersionConflictException implements Exception {}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
