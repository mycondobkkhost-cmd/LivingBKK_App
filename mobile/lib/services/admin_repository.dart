import 'supabase_service.dart';

class AdminRepository {
  bool get _ready => SupabaseService.isReady;

  Future<bool> isAdmin() async {
    if (!_ready) return false;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await SupabaseService.client!
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    return row?['role'] == 'admin';
  }

  Future<List<Map<String, dynamic>>> allDemandOffers() async {
    final data = await SupabaseService.client!
        .from('demand_offers')
        .select('*, demand_posts(title, post_code)')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> recentLeads() async {
    final data = await SupabaseService.client!
        .from('leads')
        .select('id, listing_code, status, seeker_nickname, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>?> leadStats() async {
    final data = await SupabaseService.client!
        .from('lead_stats_daily')
        .select()
        .order('stat_date', ascending: false)
        .limit(7);
    final rows = List<Map<String, dynamic>>.from(data as List);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> verifyOfferCapacity(String offerId, {required bool approved}) async {
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('demand_offers').update({
      'capacity_verified': approved ? 'verified' : 'rejected',
      'capacity_verified_by': uid,
      'capacity_verified_at': DateTime.now().toUtc().toIso8601String(),
      'status': approved ? 'under_review' : 'rejected',
    }).eq('id', offerId);
  }

  Future<void> createDemandPost({
    required String title,
    required String description,
    required String transactionType,
    double? maxPriceNet,
    double? minAreaSqm,
    double? maxDistanceBtsKm,
  }) async {
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('demand_posts').insert({
      'created_by': uid,
      'title': title,
      'description': description,
      'transaction_type': transactionType,
      'property_type': 'condo',
      'max_price_net': maxPriceNet,
      'min_area_sqm': minAreaSqm,
      'max_distance_bts_km': maxDistanceBtsKm,
      'status': 'open',
      'open_until': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
    });
  }
}
