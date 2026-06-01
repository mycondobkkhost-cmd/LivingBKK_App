import 'supabase_service.dart';

class CoAgentRepository {
  Future<void> requestCoAgent({
    required String listingId,
    String? message,
  }) async {
    if (!SupabaseService.isReady) {
      throw Exception('ต้องล็อกอินและตั้งค่า Supabase');
    }
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) throw Exception('กรุณาล็อกอินก่อนขอโคเอเจ้นท์');

    await SupabaseService.client!.from('co_agent_requests').insert({
      'listing_id': listingId,
      'requesting_agent_id': uid,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> myRequests() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client!
        .from('co_agent_requests')
        .select('id, listing_id, status, created_at')
        .eq('requesting_agent_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }
}
