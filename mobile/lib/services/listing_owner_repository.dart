import 'supabase_service.dart';

class ListingOwnerRepository {
  Future<List<Map<String, dynamic>>> myListings() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client!
        .from('listings')
        .select('id, listing_code, title, status, price_net, last_bump_at, expires_at')
        .or('owner_id.eq.$uid,created_by_id.eq.$uid')
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Anti-ghost: confirm still available = bump listing
  Future<void> bumpListing(String listingId) async {
    await SupabaseService.client!.from('listings').update({
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'status': 'published',
    }).eq('id', listingId);
  }

  Future<void> markUnavailable({
    required String listingId,
    required DateTime contractUntil,
    required DateTime availableAgain,
  }) async {
    await SupabaseService.client!.from('listings').update({
      'contract_occupied_until': contractUntil.toIso8601String().split('T').first,
      'available_again': availableAgain.toIso8601String().split('T').first,
      'status': 'hidden',
    }).eq('id', listingId);
  }
}
