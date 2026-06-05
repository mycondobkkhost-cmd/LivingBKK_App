import '../config/env.dart';
import '../models/appointment.dart';
import 'supabase_service.dart';

class AppointmentRepository {
  static final List<Appointment> _demoStore = Appointment.demo();

  Future<List<Appointment>> fetchUpcoming({int limit = 50}) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return List<Appointment>.from(_demoStore);
    }

    final data = await SupabaseService.client!
        .from('appointments')
        .select()
        .order('scheduled_date')
        .limit(limit);

    return (data as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment?> fetchById(String id) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      for (final a in _demoStore) {
        if (a.id == id) return a;
      }
      return null;
    }

    final row = await SupabaseService.client!
        .from('appointments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return Appointment.fromJson(row);
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
      _demoStore.insert(
        0,
        Appointment(
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
        ),
      );
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
        .select('id')
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

    return apptId;
  }

  Future<void> updateStatus(String id, String status) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      final i = _demoStore.indexWhere((a) => a.id == id);
      if (i >= 0) {
        final old = _demoStore[i];
        _demoStore[i] = Appointment(
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

    await SupabaseService.client!
        .from('appointments')
        .update({'status': status})
        .eq('id', id);
  }
}
