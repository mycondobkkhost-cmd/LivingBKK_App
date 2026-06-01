import '../config/env.dart';
import '../models/demand_post.dart';
import 'supabase_service.dart';

class DemandRepository {
  Future<List<DemandPost>> fetchOpenPosts() async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return DemandPost.demo();
    }

    final data = await SupabaseService.client!
        .from('demand_posts')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => DemandPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitOffer({
    required String demandPostId,
    required String offererCapacity,
    required String offerType,
    String? title,
    String? description,
    double? priceNet,
    String? externalUrl,
    String? externalNote,
  }) async {
    if (!SupabaseService.isReady) {
      throw Exception('Supabase not configured — copy .env.example to .env');
    }

    final res = await SupabaseService.client!.functions.invoke(
      'submit-demand-offer',
      body: {
        'demand_post_id': demandPostId,
        'offerer_capacity': offererCapacity,
        'offer_type': offerType,
        'title': title,
        'description': description,
        'price_net': priceNet,
        'external_url': externalUrl,
        'external_note': externalNote,
      },
    );

    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Submit failed');
    }
  }
}
