import '../config/env.dart';
import 'supabase_service.dart';

class LeadInboxRepository {
  static final demoInbox = <Map<String, dynamic>>[
    {
      'id': 'demo-lead-1',
      'listing_code': 'RENT-CD-2026-000001',
      'transaction_ref': 'LEAD-2026-000001',
      'seeker_nickname': 'น้องบี',
      'seeker_phone_censored': '08x-xxx-0001',
      'occupants_count': 2,
      'occupation': 'พนักงานบริษัท',
      'workplace': 'สุขุมวิท',
      'move_plan': 'ตั้งแต่ 1/7/2569',
      'contract_duration': '12m',
      'budget': 28000,
      'has_car': true,
      'pets': 'none',
      'smoking': 'no',
      'qualification_json': {
        'applicant_type': 'seeker_self',
        'viewing_schedule': '5/7/2569 · 15:00 – 18:00 น.',
      },
      'status': 'routed',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  Future<Map<String, dynamic>?> fetchLead(String leadId) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      for (final e in demoInbox) {
        if (e['id'] == leadId) return e;
      }
      return demoInbox.isNotEmpty ? demoInbox.first : null;
    }

    final row = await SupabaseService.client!
        .from('leads_for_assignee')
        .select()
        .eq('id', leadId)
        .maybeSingle();

    return row;
  }

  Future<void> claimIfNeeded(String leadId) async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    final lead = await SupabaseService.client!
        .from('leads')
        .select('status, assigned_to')
        .eq('id', leadId)
        .maybeSingle();

    if (lead == null) return;
    if (lead['assigned_to'] == null || lead['status'] == 'new') {
      await SupabaseService.client!.from('leads').update({
        'assigned_to': uid,
        'status': 'routed',
      }).eq('id', leadId);
    }
  }

  Future<void> acceptLead({
    required String leadId,
    required String commissionTierId,
  }) async {
    if (!SupabaseService.isReady) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();

    final assignment = await SupabaseService.client!
        .from('lead_assignments')
        .insert({
          'lead_id': leadId,
          'assignee_id': uid,
          'action': 'accepted',
          'commission_tier_id': commissionTierId,
          'contract_accepted_at': now,
        })
        .select('id')
        .single();

    final assignmentId = assignment['id'] as String;

    await SupabaseService.client!.from('leads').update({
      'status': 'accepted',
      'assigned_to': uid,
    }).eq('id', leadId);

    await SupabaseService.client!.from('e_contracts').insert({
      'lead_assignment_id': assignmentId,
      'commission_tier_id': commissionTierId,
      'signer_id': uid,
      'signed_at': now,
      'metadata': {'channel': 'in_app', 'version': '1.0'},
    });
  }

  Future<void> markUnavailable({
    required String leadId,
    required DateTime unavailableUntil,
    DateTime? availableAgain,
    String? listingId,
  }) async {
    if (!SupabaseService.isReady) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;

    await SupabaseService.client!.from('lead_assignments').insert({
      'lead_id': leadId,
      'assignee_id': uid,
      'action': 'declined_unavailable',
      'unavailable_until': unavailableUntil.toIso8601String().split('T').first,
      if (availableAgain != null)
        'available_again': availableAgain.toIso8601String().split('T').first,
    });

    await SupabaseService.client!.from('leads').update({
      'status': 'declined',
    }).eq('id', leadId);

    if (listingId != null && availableAgain != null) {
      await SupabaseService.client!.from('listings').update({
        'available_again': availableAgain.toIso8601String().split('T').first,
      }).eq('id', listingId);
    }
  }
}
