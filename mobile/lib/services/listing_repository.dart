import '../config/env.dart';
import '../models/listing_public.dart';
import 'supabase_service.dart';

class ListingRepository {
  Future<List<ListingPublic>> fetchPublished({
    String? listingType,
    bool coAgentEligibleOnly = false,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      var list = ListingPublic.demo();
      if (listingType != null) {
        list = list.where((l) => l.listingType == listingType).toList();
      }
      if (coAgentEligibleOnly) {
        list = list.where((l) => l.coAgentEligible).toList();
      }
      return list;
    }

    var query = SupabaseService.client!.from('listings_public').select();

    if (listingType != null) {
      query = query.eq('listing_type', listingType);
    }
    if (coAgentEligibleOnly) {
      query = query.eq('co_agent_eligible', true);
    }

    final data = await query.order('published_at', ascending: false);
    return (data as List)
        .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
