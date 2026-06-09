import '../config/env.dart';
import '../models/viewing_report.dart';
import 'local_prefs_service.dart';
import 'supabase_service.dart';

class ViewingReportRepository {
  static const _prefsKey = 'viewing_reports_v1';

  Future<List<ViewingReport>> _loadLocal() async {
    final raw = await LocalPrefsService.instance.getJsonList(_prefsKey);
    return raw.map((e) => ViewingReport.fromJson(e)).toList();
  }

  Future<void> _saveLocal(List<ViewingReport> list) async {
    await LocalPrefsService.instance.setJsonList(
      _prefsKey,
      list.map((r) => r.toJson()).toList(),
    );
  }

  Future<void> save(ViewingReport report) async {
    final local = await _loadLocal();
    local.removeWhere((r) => r.appointmentId == report.appointmentId);
    local.insert(0, report);
    await _saveLocal(local);

    if (Env.isConfigured && SupabaseService.isReady) {
      try {
        await SupabaseService.client!.from('viewing_reports').upsert(report.toJson());
      } catch (_) {}
    }
  }

  static bool _isDemoAppointmentId(String id) => id.startsWith('demo-appt');

  Future<ViewingReport?> forAppointment(String appointmentId) async {
    final local = await _loadLocal();
    for (final r in local) {
      if (r.appointmentId == appointmentId) return r;
    }
    if (_isDemoAppointmentId(appointmentId) ||
        !Env.isConfigured ||
        !SupabaseService.isReady) {
      return null;
    }
    try {
      final row = await SupabaseService.client!
          .from('viewing_reports')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      if (row == null) return null;
      return ViewingReport.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<ViewingReport>> forLead(String leadId) async {
    if (leadId.isEmpty) return [];
    final local = await _loadLocal();
    final hits = local.where((r) => r.leadId == leadId).toList();
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return _sortNewest(hits);
    }
    try {
      final data = await SupabaseService.client!
          .from('viewing_reports')
          .select()
          .eq('lead_id', leadId)
          .order('recorded_at', ascending: false);
      final remote = (data as List)
          .map((e) => ViewingReport.fromJson(e as Map<String, dynamic>))
          .toList();
      final merged = <String, ViewingReport>{};
      for (final r in [...remote, ...hits]) {
        merged[r.appointmentId] = r;
      }
      return _sortNewest(merged.values.toList());
    } catch (_) {
      return _sortNewest(hits);
    }
  }

  /// ประวัติพาชมทั้งหมดของลูกค้า (เบอร์เดียวกัน)
  Future<List<ViewingReport>> forSeekerPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return [];
    final normalized = phone.trim();
    final local = await _loadLocal();
    final hits =
        local.where((r) => r.seekerPhone?.trim() == normalized).toList();
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return _sortNewest(hits);
    }
    try {
      final data = await SupabaseService.client!
          .from('viewing_reports')
          .select()
          .eq('seeker_phone', normalized)
          .order('recorded_at', ascending: false);
      final remote = (data as List)
          .map((e) => ViewingReport.fromJson(e as Map<String, dynamic>))
          .toList();
      final merged = <String, ViewingReport>{};
      for (final r in [...remote, ...hits]) {
        merged[r.id] = r;
      }
      return _sortNewest(merged.values.toList());
    } catch (_) {
      return _sortNewest(hits);
    }
  }

  List<ViewingReport> _sortNewest(List<ViewingReport> list) {
    list.sort((a, b) {
      final ad = a.recordedAt ?? a.viewedDate;
      final bd = b.recordedAt ?? b.viewedDate;
      return bd.compareTo(ad);
    });
    return list;
  }
}
