import 'dart:async';

import '../config/env.dart';
import '../data/admin_demo_data.dart';
import '../data/viewing_staff_catalog.dart';
import '../models/appointment.dart';
import '../models/viewing_report.dart';
import 'calendar_event_repository.dart';
import 'viewing_report_repository.dart';
import 'demo_cast_bootstrap.dart';
import 'local_prefs_service.dart';
import 'supabase_service.dart';

class AppointmentRepository {
  static const _followUpPrefsKey = 'appointment_follow_up_v2';
  static const _staffPrefsKey = 'appointment_staff_v2';
  static const _demoSeedVersionKey = 'appointment_demo_seed_version';
  /// เพิ่มเมื่อเปลี่ยนชุดนัดจำลอง — บังคับล้างเอเจ้น/สถานะที่ค้างในเครื่อง
  static const demoSeedVersion = 3;
  static List<Appointment>? _demoStore;

  static bool isDemoId(String id) => id.startsWith('demo-appt');

  static void resetDemoStore() {
    _demoStore = null;
  }

  /// คืนค่านัดจำลองจาก factory — ล้างสถานะ/เอเจ้นที่แก้ใน session
  static void reseedDemoFromFactory() {
    _demoStore = Appointment.demo();
  }

  static Future<void> _purgeDemoAppointmentPrefs() async {
    await LocalPrefsService.instance.init();
    await LocalPrefsService.instance.remove('appointment_staff_v1');
    await LocalPrefsService.instance.remove(_staffPrefsKey);
    await LocalPrefsService.instance.remove('appointment_follow_up_v1');
    await LocalPrefsService.instance.remove(_followUpPrefsKey);
    await LocalPrefsService.instance.setJsonMap(_staffPrefsKey, {});
    await LocalPrefsService.instance.setJsonMap(_followUpPrefsKey, {});
    await LocalPrefsService.instance
        .remove('viewing_calendar_seen_appt_ids_v1');
    await LocalPrefsService.instance
        .remove('viewing_calendar_seen_report_sigs_v1');
    await LocalPrefsService.instance
        .remove('viewing_calendar_last_banner_total_v1');
  }

  /// ตรวจ seed นัดจำลอง — รีเฟรชเบราว์เซอร์อย่างเดียวไม่ล้าง prefs เอเจ้น
  static Future<void> ensureDemoSeedCurrent({bool force = false}) async {
    if (!Env.adminDemoCases) return;
    await LocalPrefsService.instance.init();
    if (!force) {
      final stored =
          await LocalPrefsService.instance.getInt(_demoSeedVersionKey);
      if (stored == demoSeedVersion) return;
    }
    await _purgeDemoAppointmentPrefs();
    reseedDemoFromFactory();
    await LocalPrefsService.instance.setInt(_demoSeedVersionKey, demoSeedVersion);
  }

  static bool _isProfileUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  Appointment _copyStaff(Appointment a, String? staff) => Appointment(
        id: a.id,
        leadId: a.leadId,
        listingId: a.listingId,
        listingCode: a.listingCode,
        seekerNickname: a.seekerNickname,
        seekerPhone: a.seekerPhone,
        scheduledDate: a.scheduledDate,
        timeSlot: a.timeSlot,
        status: a.status,
        locationLabel: a.locationLabel,
        lat: a.lat,
        lng: a.lng,
        adminNotes: a.adminNotes,
        assignedTo: staff,
        transactionRef: a.transactionRef,
        viewingReport: a.viewingReport,
      );

  static List<Appointment> _demoMutable() {
    if (_demoStore == null) {
      _demoStore = Appointment.demo();
    } else {
      final ids = _demoStore!.map((a) => a.id).toSet();
      for (final a in Appointment.demo()) {
        if (!ids.contains(a.id)) _demoStore!.add(a);
      }
    }
    return _demoStore!;
  }

  final _reportRepo = ViewingReportRepository();

  Future<void> _persistStaffLocal(String id, String? staffId) async {
    final map =
        await LocalPrefsService.instance.getJsonMap(_staffPrefsKey) ?? {};
    if (staffId == null || staffId.isEmpty) {
      map.remove(id);
    } else {
      map[id] = staffId;
    }
    await LocalPrefsService.instance.setJsonMap(_staffPrefsKey, map);
  }

  Future<Appointment> _hydrateStaff(Appointment a) async {
    var staff = a.assignedTo;
    if (staff == null || staff.trim().isEmpty) {
      final map = await LocalPrefsService.instance.getJsonMap(_staffPrefsKey);
      final raw = map?[a.id];
      if (raw != null) staff = raw.toString();
    }
    if (staff == null || staff == a.assignedTo) return a;
    return _copyStaff(a, staff);
  }

  Future<Appointment> _hydrate(Appointment a) async {
    if (isDemoId(a.id) || DemoCastBootstrap.shouldUseCastWorld) {
      return _hydrateDemo(a);
    }
    return _hydrateReport(await _hydrateStaff(a));
  }

  Future<Appointment> _hydrateDemo(Appointment a) async {
    return _hydrateReportLocal(await _hydrateStaff(a));
  }

  Future<Appointment> _hydrateReportLocal(Appointment a) async {
    if (a.viewingReport != null && !a.viewingReport!.isEmpty) return a;
    final map = await LocalPrefsService.instance.getJsonMap(_followUpPrefsKey);
    final raw = map?[a.id];
    if (raw is Map && raw['outcome'] != null) {
      return Appointment(
        id: a.id,
        leadId: a.leadId,
        listingId: a.listingId,
        listingCode: a.listingCode,
        seekerNickname: a.seekerNickname,
        seekerPhone: a.seekerPhone,
        scheduledDate: a.scheduledDate,
        timeSlot: a.timeSlot,
        status: a.status,
        locationLabel: a.locationLabel,
        lat: a.lat,
        lng: a.lng,
        adminNotes: a.adminNotes,
        assignedTo: a.assignedTo,
        transactionRef: a.transactionRef,
        viewingReport: ViewingReport.fromJson({
          ...Map<String, dynamic>.from(raw),
          'appointment_id': a.id,
        }),
      );
    }
    return a;
  }

  Future<Appointment> _hydrateReport(Appointment a) async {
    if (a.viewingReport != null && !a.viewingReport!.isEmpty) return a;
    if (isDemoId(a.id)) return _hydrateReportLocal(a);
    final report = await _reportRepo.forAppointment(a.id);
    if (report == null || report.isEmpty) {
      final map = await LocalPrefsService.instance.getJsonMap(_followUpPrefsKey);
      final raw = map?[a.id];
      if (raw is Map && raw['outcome'] != null) {
        return Appointment(
          id: a.id,
          leadId: a.leadId,
          listingId: a.listingId,
          listingCode: a.listingCode,
          seekerNickname: a.seekerNickname,
          seekerPhone: a.seekerPhone,
          scheduledDate: a.scheduledDate,
          timeSlot: a.timeSlot,
          status: a.status,
          locationLabel: a.locationLabel,
          lat: a.lat,
          lng: a.lng,
          adminNotes: a.adminNotes,
          assignedTo: a.assignedTo,
          transactionRef: a.transactionRef,
          viewingReport: ViewingReport.fromJson({
            ...Map<String, dynamic>.from(raw),
            'appointment_id': a.id,
          }),
        );
      }
      return a;
    }
    return Appointment(
      id: a.id,
      leadId: a.leadId,
      listingId: a.listingId,
      listingCode: a.listingCode,
      seekerNickname: a.seekerNickname,
      seekerPhone: a.seekerPhone,
      scheduledDate: a.scheduledDate,
      timeSlot: a.timeSlot,
      status: a.status,
      locationLabel: a.locationLabel,
      lat: a.lat,
      lng: a.lng,
      adminNotes: a.adminNotes,
      assignedTo: a.assignedTo,
      transactionRef: a.transactionRef,
      viewingReport: report,
    );
  }

  Future<List<Appointment>> _loadDemoAppointments() async {
    final staffMap =
        await LocalPrefsService.instance.getJsonMap(_staffPrefsKey) ?? {};
    final followMap =
        await LocalPrefsService.instance.getJsonMap(_followUpPrefsKey) ?? {};
    return _demoMutable().map((a) {
      var out = a;
      final staffRaw = staffMap[a.id];
      if (staffRaw != null) {
        out = _copyStaff(out, staffRaw.toString());
      }
      final raw = followMap[a.id];
      if (raw is Map && raw['outcome'] != null) {
        out = Appointment(
          id: out.id,
          leadId: out.leadId,
          listingId: out.listingId,
          listingCode: out.listingCode,
          seekerNickname: out.seekerNickname,
          seekerPhone: out.seekerPhone,
          scheduledDate: out.scheduledDate,
          timeSlot: out.timeSlot,
          status: out.status,
          locationLabel: out.locationLabel,
          lat: out.lat,
          lng: out.lng,
          adminNotes: out.adminNotes,
          assignedTo: out.assignedTo,
          transactionRef: out.transactionRef,
          viewingReport: ViewingReport.fromJson({
            ...Map<String, dynamic>.from(raw),
            'appointment_id': out.id,
          }),
        );
      }
      return out;
    }).toList();
  }

  /// รวมนัดจาก DB + เคสตัวอย่าง (เมื่อ ADMIN_DEMO_CASES เปิด)
  Future<List<Appointment>> _mergeWithDemo(List<Appointment> live) async {
    if (!AdminDemoData.enabled) {
      final out = <Appointment>[];
      for (final a in live) {
        out.add(await _hydrate(a));
      }
      return out;
    }
    final demo = await _loadDemoAppointments();
    final merged = <String, Appointment>{};
    for (final a in live) {
      merged[a.id] = await _hydrate(a);
    }
    for (final a in demo) {
      merged.putIfAbsent(a.id, () => a);
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final d = a.scheduledDate.compareTo(b.scheduledDate);
        if (d != 0) return d;
        return a.timeSlot.compareTo(b.timeSlot);
      });
    return list;
  }

  Future<List<Appointment>> fetchUpcoming({
    int limit = 50,
    String? staffUserId,
    String? staffSlug,
  }) async {
    if (Env.adminDemoCases) {
      await ensureDemoSeedCurrent();
    }
    if (DemoCastBootstrap.shouldUseCastWorld) {
      return _filterForStaff(
        await _loadDemoAppointments(),
        staffUserId: staffUserId,
        staffSlug: staffSlug,
      );
    }

    if (!Env.isConfigured || !SupabaseService.isReady) {
      return _filterForStaff(
        await _loadDemoAppointments(),
        staffUserId: staffUserId,
        staffSlug: staffSlug,
      );
    }

    final data = await SupabaseService.client!
        .from('appointments')
        .select()
        .order('scheduled_date')
        .limit(limit);

    final list = (data as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
    return _filterForStaff(
      await _mergeWithDemo(list),
      staffUserId: staffUserId,
      staffSlug: staffSlug,
    );
  }

  List<Appointment> _filterForStaff(
    List<Appointment> list, {
    String? staffUserId,
    String? staffSlug,
  }) {
    if (staffUserId == null && staffSlug == null) return list;
    return list
        .where(
          (a) => ViewingStaffCatalog.matchesAppointment(
            assignedTo: a.assignedTo,
            staffUserId: staffUserId,
            staffSlug: staffSlug,
          ),
        )
        .toList();
  }

  /// นัดที่ยืนยันแล้ว + มีคนพา — เลือกวันนัดล่าสุด (หลายนัดต่อ lead)
  Future<Appointment?> fetchLatestConfirmedByLeadId(String leadId) async {
    if (leadId.isEmpty) return null;
    Appointment? best;
    for (final raw in _demoMutable()) {
      if (raw.leadId != leadId || raw.status != 'confirmed') continue;
      final a = await _hydrateDemo(raw);
      if (a.assignedTo == null || a.assignedTo!.trim().isEmpty) continue;
      if (best == null || a.scheduledDate.isAfter(best.scheduledDate)) {
        best = a;
      }
    }
    if (best != null || leadId.startsWith('demo-lead')) return best;

    if (!Env.isConfigured || !SupabaseService.isReady) return null;
    final rows = await SupabaseService.client!
        .from('appointments')
        .select()
        .eq('lead_id', leadId)
        .eq('status', 'confirmed')
        .order('scheduled_date', ascending: false)
        .limit(5);
    for (final row in rows as List) {
      final a = await _hydrate(Appointment.fromJson(Map<String, dynamic>.from(row)));
      if (a.assignedTo != null && a.assignedTo!.trim().isNotEmpty) return a;
    }
    return null;
  }

  Future<Appointment?> fetchByLeadId(String leadId) async {
    if (leadId.isEmpty) return null;
    if (leadId.startsWith('demo-lead') ||
        DemoCastBootstrap.shouldUseCastWorld ||
        !Env.isConfigured ||
        !SupabaseService.isReady) {
      for (final a in _demoMutable()) {
        if (a.leadId == leadId) return await _hydrateDemo(a);
      }
      return null;
    }

    final row = await SupabaseService.client!
        .from('appointments')
        .select()
        .eq('lead_id', leadId)
        .order('scheduled_date')
        .limit(1)
        .maybeSingle();

    if (row == null) {
      if (AdminDemoData.enabled) {
        for (final a in _demoMutable()) {
          if (a.leadId == leadId) return await _hydrate(a);
        }
      }
      return null;
    }
    return _hydrate(Appointment.fromJson(row));
  }

  Future<Appointment?> fetchByTransactionRef(String ref) async {
    final code = ref.trim();
    if (code.isEmpty) return null;
    for (final a in _demoMutable()) {
      if (a.transactionRef == code) return await _hydrateDemo(a);
    }
    if (!Env.isConfigured || !SupabaseService.isReady) return null;
    final row = await SupabaseService.client!
        .from('appointments')
        .select()
        .eq('transaction_ref', code)
        .maybeSingle();
    if (row == null) return null;
    return _hydrate(Appointment.fromJson(row));
  }

  Future<Appointment?> fetchById(String id) async {
    if (DemoCastBootstrap.shouldUseCastWorld || isDemoId(id)) {
      for (final a in _demoMutable()) {
        if (a.id == id) return a;
      }
      if (DemoCastBootstrap.shouldUseCastWorld) return null;
    }

    if (!Env.isConfigured || !SupabaseService.isReady) {
      for (final a in _demoMutable()) {
        if (a.id == id) return await _hydrate(a);
      }
      return null;
    }

    final row = await SupabaseService.client!
        .from('appointments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      if (AdminDemoData.enabled) {
        for (final a in _demoMutable()) {
          if (a.id == id) return await _hydrate(a);
        }
      }
      return null;
    }
    return _hydrate(Appointment.fromJson(row));
  }

  Future<String> scheduleFromLead({
    required String leadId,
    required String seekerNickname,
    String? seekerPhone,
    String? listingId,
    String? listingCode,
    required DateTime scheduledDate,
    required String timeSlot,
    String? locationLabel,
    double? lat,
    double? lng,
    String? adminNotes,
    String? assignedTo,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      final id = 'demo-appt-${DateTime.now().millisecondsSinceEpoch}';
      final appt = Appointment(
        id: id,
        leadId: leadId,
        listingId: listingId,
        listingCode: listingCode,
        seekerNickname: seekerNickname,
        seekerPhone: seekerPhone,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        status: 'confirmed',
        locationLabel: locationLabel,
        lat: lat,
        lng: lng,
        adminNotes: adminNotes,
        assignedTo: assignedTo,
      );
      _demoMutable().insert(0, appt);
      unawaited(CalendarEventRepository().syncFromAppointment(appt));
      return id;
    }

    final uid = SupabaseService.client!.auth.currentUser?.id;
    final row = await SupabaseService.client!
        .from('appointments')
        .insert({
          'lead_id': leadId,
          'listing_id': listingId,
          'listing_code': listingCode,
          'seeker_nickname': seekerNickname,
          'seeker_phone': seekerPhone,
          'scheduled_date': scheduledDate.toIso8601String().split('T').first,
          'time_slot': timeSlot,
          'status': 'confirmed',
          'location_label': locationLabel,
          'lat': lat,
          'lng': lng,
          'admin_notes': adminNotes,
          'created_by': uid,
          'assigned_to': assignedTo,
        })
        .select()
        .single();

    await SupabaseService.client!.from('leads').update({
      'status': 'closed',
    }).eq('id', leadId);

    final apptId = row['id'] as String;
    try {
      await SupabaseService.client!.functions.invoke(
        'notify-appointment',
        body: {'appointment_id': apptId},
      );
    } catch (_) {
      // notification is best-effort
    }

    try {
      final synced = await _hydrate(Appointment.fromJson(row));
      await CalendarEventRepository().syncFromAppointment(synced);
      await CalendarEventRepository().runAiDraft(appointmentId: apptId);
    } catch (_) {
      // calendar sync is best-effort
    }

    return apptId;
  }

  Future<void> updateStatus(String id, String status) async {
    if (isDemoId(id) ||
        DemoCastBootstrap.shouldUseCastWorld ||
        !Env.isConfigured ||
        !SupabaseService.isReady) {
      final store = _demoMutable();
      final i = store.indexWhere((a) => a.id == id);
      if (i >= 0) {
        final old = store[i];
        store[i] = Appointment(
          id: old.id,
          leadId: old.leadId,
          listingId: old.listingId,
          listingCode: old.listingCode,
          seekerNickname: old.seekerNickname,
          seekerPhone: old.seekerPhone,
          scheduledDate: old.scheduledDate,
          timeSlot: old.timeSlot,
          status: status,
          locationLabel: old.locationLabel,
          lat: old.lat,
          lng: old.lng,
          adminNotes: old.adminNotes,
          assignedTo: old.assignedTo,
        );
      }
      return;
    }

    try {
      await SupabaseService.client!
          .from('appointments')
          .update({'status': status})
          .eq('id', id)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      throw Exception('update_status_failed: $e');
    }
  }

  Future<void> updateAdminNotes(String id, String? adminNotes) async {
    if (!Env.isConfigured || !SupabaseService.isReady || isDemoId(id)) {
      final store = _demoMutable();
      final i = store.indexWhere((a) => a.id == id);
      if (i >= 0) {
        final old = store[i];
        store[i] = Appointment(
          id: old.id,
          leadId: old.leadId,
          listingId: old.listingId,
          listingCode: old.listingCode,
          seekerNickname: old.seekerNickname,
          seekerPhone: old.seekerPhone,
          scheduledDate: old.scheduledDate,
          timeSlot: old.timeSlot,
          status: old.status,
          locationLabel: old.locationLabel,
          lat: old.lat,
          lng: old.lng,
          adminNotes: adminNotes,
          assignedTo: old.assignedTo,
          transactionRef: old.transactionRef,
        );
      }
      return;
    }

    await SupabaseService.client!
        .from('appointments')
        .update({'admin_notes': adminNotes})
        .eq('id', id);
  }

  Future<void> updateAssignment(String id, String? assignedTo) async {
    final staffId =
        assignedTo == null || assignedTo.trim().isEmpty ? null : assignedTo.trim();

    if (isDemoId(id) || DemoCastBootstrap.shouldUseCastWorld) {
      final store = _demoMutable();
      final i = store.indexWhere((a) => a.id == id);
      if (i >= 0) {
        store[i] = _copyStaff(store[i], staffId);
      }
      await _persistStaffLocal(id, staffId);
      return;
    }

    await _persistStaffLocal(id, staffId);

    if (!Env.isConfigured || !SupabaseService.isReady) {
      return;
    }

    final patch = <String, dynamic>{
      if (staffId == null) ...{
        'guide_staff_id': null,
        'assigned_to': null,
      } else if (_isProfileUuid(staffId)) ...{
        'guide_staff_id': staffId,
        'assigned_to': staffId,
      } else ...{
        'guide_staff_id': staffId,
      },
    };

    try {
      await SupabaseService.client!
          .from('appointments')
          .update(patch)
          .eq('id', id)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      if (!_isProfileUuid(staffId)) return;
      throw Exception('update_staff_failed: $e');
    }
  }

  Future<void> updateViewingReport(
    String id, {
    required ViewingReport report,
    String? adminNotes,
    String? status,
  }) async {
    final patch = <String, dynamic>{
      'follow_up': report.toJson(),
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (status != null) 'status': status,
    };

    if (!Env.isConfigured || !SupabaseService.isReady || isDemoId(id)) {
      final store = _demoMutable();
      final i = store.indexWhere((a) => a.id == id);
      if (i >= 0) {
        final old = store[i];
        store[i] = Appointment(
          id: old.id,
          leadId: old.leadId,
          listingId: old.listingId,
          listingCode: old.listingCode,
          seekerNickname: old.seekerNickname,
          seekerPhone: old.seekerPhone,
          scheduledDate: old.scheduledDate,
          timeSlot: old.timeSlot,
          status: status ?? old.status,
          locationLabel: old.locationLabel,
          lat: old.lat,
          lng: old.lng,
          adminNotes: adminNotes ?? old.adminNotes,
          assignedTo: old.assignedTo,
          transactionRef: old.transactionRef,
          viewingReport: report,
        );
      }
      final map =
          await LocalPrefsService.instance.getJsonMap(_followUpPrefsKey) ?? {};
      map[id] = report.toJson();
      await LocalPrefsService.instance.setJsonMap(_followUpPrefsKey, map);
      return;
    }

    try {
      await SupabaseService.client!
          .from('appointments')
          .update(patch)
          .eq('id', id);
    } catch (_) {
      final map =
          await LocalPrefsService.instance.getJsonMap(_followUpPrefsKey) ?? {};
      map[id] = report.toJson();
      await LocalPrefsService.instance.setJsonMap(_followUpPrefsKey, map);
    }
  }
}
