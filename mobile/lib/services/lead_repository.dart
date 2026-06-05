import 'lead_inbox_repository.dart';
import '../utils/reference_codes.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class LeadSubmitOutcome {
  const LeadSubmitOutcome({
    required this.savedToDatabase,
    this.duplicatePhoneSuffix = false,
    this.transactionRef,
  });

  final bool savedToDatabase;
  final bool duplicatePhoneSuffix;
  final String? transactionRef;
}

class LeadSubmission {
  const LeadSubmission({
    required this.listingCode,
    required this.seekerNickname,
    required this.seekerPhone,
    this.listingId,
    this.applicantType,
    this.occupantsCount,
    this.gender,
    this.occupation,
    this.workplace,
    this.movePlan,
    this.contractDuration,
    this.budget,
    this.budgetMin,
    this.budgetMax,
    this.viewingSchedule,
    this.hasCar,
    this.pets,
    this.smoking,
    this.preferredAreas,
    this.customerPhoneLast4,
    this.duplicatePhoneSuffix = false,
  });

  final String listingCode;
  final String? listingId;
  final String seekerNickname;
  final String seekerPhone;
  final String? applicantType;
  final int? occupantsCount;
  final String? gender;
  final String? occupation;
  final String? workplace;
  final String? movePlan;
  final String? contractDuration;
  final double? budget;
  final double? budgetMin;
  final double? budgetMax;
  final String? viewingSchedule;
  final bool? hasCar;
  final String? pets;
  final String? smoking;
  final List<String>? preferredAreas;
  /// โคเอเจนท์: 4 ตัวท้ายเบอร์ลูกค้า
  final String? customerPhoneLast4;
  final bool duplicatePhoneSuffix;

  Map<String, dynamic> toJson(String? seekerId) {
    final qualification = <String, dynamic>{};
    if (applicantType != null) qualification['applicant_type'] = applicantType;
    if (budgetMin != null) qualification['budget_min'] = budgetMin;
    if (budgetMax != null) qualification['budget_max'] = budgetMax;
    if (viewingSchedule != null) qualification['viewing_schedule'] = viewingSchedule;
    if (customerPhoneLast4 != null) {
      qualification['customer_phone_last4'] = customerPhoneLast4;
    }
    if (duplicatePhoneSuffix) qualification['duplicate_phone_suffix'] = true;

    return {
      'listing_code': listingCode,
      if (listingId != null) 'listing_id': listingId,
      if (seekerId != null) 'seeker_id': seekerId,
      'seeker_nickname': seekerNickname,
      'seeker_phone': seekerPhone,
      if (occupantsCount != null) 'occupants_count': occupantsCount,
      if (gender != null) 'gender': gender,
      if (occupation != null) 'occupation': occupation,
      if (workplace != null) 'workplace': workplace,
      if (movePlan != null) 'move_plan': movePlan,
      if (contractDuration != null) 'contract_duration': contractDuration,
      if (budget != null) 'budget': budget,
      if (hasCar != null) 'has_car': hasCar,
      if (pets != null) 'pets': pets,
      if (smoking != null) 'smoking': smoking,
      if (preferredAreas != null && preferredAreas!.isNotEmpty)
        'preferred_areas': preferredAreas,
      if (qualification.isNotEmpty) 'qualification_json': qualification,
      'status': 'new',
    };
  }
}

class LeadRepository {
  static final Set<String> _seenPhoneSuffixes = {};

  static String normalizePhoneSuffix(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '');

  Future<bool> isDuplicateCustomerPhoneSuffix(String last4) async {
    final suffix = normalizePhoneSuffix(last4);
    if (suffix.length != 4) return false;
    if (_seenPhoneSuffixes.contains(suffix)) return true;

    if (!SupabaseService.isReady || AuthService.instance.trialSimulatesBackend) {
      return false;
    }

    try {
      final byQual = await SupabaseService.client!
          .from('leads')
          .select('id')
          .eq('qualification_json->>customer_phone_last4', suffix)
          .limit(1);
      if ((byQual as List).isNotEmpty) return true;

      final rows = await SupabaseService.client!
          .from('leads')
          .select('seeker_phone')
          .like('seeker_phone', '%$suffix')
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (e) {
      if (_schemaNotReady(e)) return false;
      rethrow;
    }
  }

  void recordPhoneSuffix(String last4) {
    final suffix = normalizePhoneSuffix(last4);
    if (suffix.length == 4) _seenPhoneSuffixes.add(suffix);
  }

  Future<String?> resolveListingId(String listingCode) async {
    if (!SupabaseService.isReady) return null;
    final row = await SupabaseService.client!
        .from('listings')
        .select('id')
        .eq('listing_code', listingCode)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<LeadSubmitOutcome> submit(LeadSubmission lead) async {
    if (lead.customerPhoneLast4 != null) {
      recordPhoneSuffix(lead.customerPhoneLast4!);
    }

    if (lead.duplicatePhoneSuffix) {
      await _notifyDuplicatePhone(lead);
    }

    if (AuthService.instance.trialSimulatesBackend) {
      await Future.delayed(const Duration(milliseconds: 400));
      return LeadSubmitOutcome(
        savedToDatabase: false,
        duplicatePhoneSuffix: lead.duplicatePhoneSuffix,
        transactionRef: ReferenceCodes.demoLeadRef(
          '${lead.listingCode}-${lead.seekerPhone}',
        ),
      );
    }
    if (!SupabaseService.isReady) {
      await Future.delayed(const Duration(milliseconds: 400));
      return LeadSubmitOutcome(
        savedToDatabase: false,
        duplicatePhoneSuffix: lead.duplicatePhoneSuffix,
        transactionRef: ReferenceCodes.demoLeadRef(
          '${lead.listingCode}-${lead.seekerPhone}',
        ),
      );
    }

    try {
      final uid = AuthService.instance.effectiveUserId;
      var listingId = lead.listingId;
      listingId ??= await resolveListingId(lead.listingCode);

      final payload = lead.toJson(uid);
      if (listingId != null) payload['listing_id'] = listingId;

      final inserted = await SupabaseService.client!
          .from('leads')
          .insert(payload)
          .select('id, transaction_ref')
          .single();

      final leadId = inserted['id'] as String?;
      final txnRef = inserted['transaction_ref'] as String?;
      if (leadId != null) {
        try {
          await SupabaseService.client!.functions.invoke(
            'route-lead-notification',
            body: {
              'lead_id': leadId,
              if (lead.duplicatePhoneSuffix) 'duplicate_phone_suffix': true,
            },
          );
        } catch (_) {}
      }
      return LeadSubmitOutcome(
        savedToDatabase: true,
        duplicatePhoneSuffix: lead.duplicatePhoneSuffix,
        transactionRef: txnRef,
      );
    } catch (e) {
      if (_schemaNotReady(e)) {
        await Future.delayed(const Duration(milliseconds: 400));
        return LeadSubmitOutcome(
          savedToDatabase: false,
          duplicatePhoneSuffix: lead.duplicatePhoneSuffix,
          transactionRef: ReferenceCodes.demoLeadRef(
            '${lead.listingCode}-${lead.seekerPhone}',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _notifyDuplicatePhone(LeadSubmission lead) async {
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client!.functions.invoke(
        'route-lead-notification',
        body: {
          'listing_code': lead.listingCode,
          'listing_id': lead.listingId,
          'reason': 'duplicate_phone_suffix',
          'customer_phone_last4': lead.customerPhoneLast4,
          'channel': 'staff_alert',
        },
      );
    } catch (_) {}
  }

  bool _schemaNotReady(Object e) {
    final msg = e.toString();
    return msg.contains('PGRST205') ||
        msg.contains('public.leads') ||
        msg.contains('schema cache');
  }

  Future<List<Map<String, dynamic>>> myLeads() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final data = await SupabaseService.client!
          .from('leads')
          .select('id, listing_code, status, seeker_nickname, created_at')
          .eq('seeker_id', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      if (_schemaNotReady(e)) return [];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> assignedLeads() async {
    if (AuthService.instance.trialSimulatesBackend ||
        !SupabaseService.isReady) {
      return List<Map<String, dynamic>>.from(LeadInboxRepository.demoInbox);
    }
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null) return [];

    try {
      final data = await SupabaseService.client!
          .from('leads_for_assignee')
          .select()
          .eq('assigned_to', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      if (_schemaNotReady(e)) {
        return List<Map<String, dynamic>>.from(LeadInboxRepository.demoInbox);
      }
      rethrow;
    }
  }
}

String leadGenderLabel(String? value) {
  switch (value) {
    case 'male':
      return 'ชาย';
    case 'female':
      return 'หญิง';
    case 'lgbtq_plus':
      return 'LGBTQ+';
    case 'prefer_not_say':
      return 'ไม่ระบุ';
    default:
      return '-';
  }
}
