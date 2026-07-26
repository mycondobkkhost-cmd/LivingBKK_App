import '../models/commission_agreement_context.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class CommissionAgreementRepository {
  CommissionAgreementRepository._();
  static final CommissionAgreementRepository instance =
      CommissionAgreementRepository._();

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  Future<void> record({
    required CommissionAgreementContext context,
    required Map<String, dynamic> schemeSnapshot,
    String? listingId,
    String? leadId,
    String? offerId,
    String? viewingRequestId,
  }) async {
    if (!_live) return;
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      await SupabaseService.client!.from('commission_agreements').insert({
        'user_id': uid,
        'context': context.dbValue,
        'scheme_snapshot': schemeSnapshot,
        if (listingId != null && listingId.isNotEmpty) 'listing_id': listingId,
        if (leadId != null && leadId.isNotEmpty) 'lead_id': leadId,
        if (offerId != null && offerId.isNotEmpty) 'offer_id': offerId,
        if (viewingRequestId != null && viewingRequestId.isNotEmpty)
          'viewing_request_id': viewingRequestId,
      });
    } catch (_) {}
  }
}
