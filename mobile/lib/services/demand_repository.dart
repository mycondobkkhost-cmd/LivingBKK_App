import '../config/env.dart';
import '../models/demand_post.dart';
import '../utils/reference_codes.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

bool isDemoDemandPostId(String id) =>
    id.startsWith('dm-') ||
    !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(id);

class DemandRepository {
  Future<List<DemandPost>> fetchPosts() async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return DemandPost.demo();
    }

    try {
      final data = await SupabaseService.client!
          .from('demand_posts')
          .select()
          .order('created_at', ascending: false);

      final posts = (data as List)
          .map((e) => DemandPost.fromJson(e as Map<String, dynamic>))
          .toList();

      if (posts.isEmpty) return DemandPost.demo();
      return posts;
    } catch (_) {
      return DemandPost.demo();
    }
  }

  /// @deprecated ใช้ [fetchPosts]
  Future<List<DemandPost>> fetchOpenPosts() async {
    final all = await fetchPosts();
    return all.where((p) => p.status == 'open').toList();
  }

  Future<DemandOfferSubmitResult> submitOffer({
    required String demandPostId,
    required String offererCapacity,
    required String offerType,
    required String transactionType,
    String? title,
    String? description,
    double? priceNet,
    double? priceMaxNet,
    String? transferTerms,
    String? commissionScheme,
    String? commissionNote,
    String? contactName,
    String? contactPhone,
    String? externalUrl,
    String? demandPostCode,
    String? demandPostTitle,
  }) async {
    final useDemo = !Env.isConfigured ||
        !SupabaseService.isReady ||
        !AuthService.instance.isRealSupabaseSession ||
        isDemoDemandPostId(demandPostId);

    if (useDemo) {
      await Future.delayed(const Duration(milliseconds: 300));
      final seed = 'offer-${DateTime.now().millisecondsSinceEpoch}';
      return DemandOfferSubmitResult(
        offerId: 'demo-offer-$seed',
        demandPostCode: demandPostCode,
        demandPostTitle: demandPostTitle,
        transactionRef: ReferenceCodes.demoChatRef(seed),
      );
    }

    final res = await SupabaseService.client!.functions.invoke(
      'submit-demand-offer',
      body: {
        'demand_post_id': demandPostId,
        'offerer_capacity': offererCapacity,
        'offer_type': offerType,
        'transaction_type': transactionType,
        'title': title,
        'description': description,
        'price_net': priceNet,
        'price_max_net': priceMaxNet,
        'transfer_terms': transferTerms,
        'commission_scheme': commissionScheme,
        'commission_note': commissionNote,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'external_url': externalUrl,
      },
    );

    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Submit failed');
    }

    final data = res.data as Map<String, dynamic>?;
    final offer = data?['offer'] as Map<String, dynamic>?;
    return DemandOfferSubmitResult(
      offerId: offer?['id'] as String? ?? '',
      demandPostCode: data?['demand_post_code'] as String?,
      demandPostTitle: data?['demand_post_title'] as String?,
    );
  }
}

class DemandOfferSubmitResult {
  const DemandOfferSubmitResult({
    required this.offerId,
    this.demandPostCode,
    this.demandPostTitle,
    this.transactionRef,
  });

  final String offerId;
  final String? demandPostCode;
  final String? demandPostTitle;
  final String? transactionRef;
}
