import 'supabase_service.dart';

class LeadSubmission {
  const LeadSubmission({
    required this.listingCode,
    required this.seekerNickname,
    required this.seekerPhone,
    this.listingId,
    this.occupantsCount,
    this.gender,
    this.occupation,
    this.workplace,
    this.movePlan,
    this.contractDuration,
    this.budget,
    this.hasCar,
    this.pets,
    this.smoking,
    this.preferredAreas,
  });

  final String listingCode;
  final String? listingId;
  final String seekerNickname;
  final String seekerPhone;
  final int? occupantsCount;
  final String? gender;
  final String? occupation;
  final String? workplace;
  final String? movePlan;
  final String? contractDuration;
  final double? budget;
  final bool? hasCar;
  final String? pets;
  final String? smoking;
  final List<String>? preferredAreas;

  Map<String, dynamic> toJson(String? seekerId) => {
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
        'status': 'new',
      };
}

class LeadRepository {
  Future<String?> resolveListingId(String listingCode) async {
    if (!SupabaseService.isReady) return null;
    final row = await SupabaseService.client!
        .from('listings')
        .select('id')
        .eq('listing_code', listingCode)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<void> submit(LeadSubmission lead) async {
    if (!SupabaseService.isReady) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final uid = SupabaseService.client!.auth.currentUser?.id;
    var listingId = lead.listingId;
    listingId ??= await resolveListingId(lead.listingCode);

    final payload = lead.toJson(uid);
    if (listingId != null) payload['listing_id'] = listingId;

    await SupabaseService.client!.from('leads').insert(payload);
  }

  Future<List<Map<String, dynamic>>> myLeads() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client!
        .from('leads')
        .select('id, listing_code, status, seeker_nickname, created_at')
        .eq('seeker_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> assignedLeads() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client!
        .from('leads_for_assignee')
        .select()
        .eq('assigned_to', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }
}
