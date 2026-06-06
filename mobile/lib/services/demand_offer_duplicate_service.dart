import '../config/env.dart';
import '../utils/phone_suffix_util.dart';
import 'auth_service.dart';
import 'lead_repository.dart';
import 'supabase_service.dart';

/// ตรวจเลข 4 ตัวท้ายเบอร์ลูกค้า — กันข้อมูลซ้ำในระบบ
class DemandOfferDuplicateService {
  DemandOfferDuplicateService._();
  static final DemandOfferDuplicateService instance =
      DemandOfferDuplicateService._();

  final _leads = LeadRepository();

  Future<DemandPhoneDuplicateResult> checkCustomerPhoneLast4(
    String last4, {
    String? excludeDemandPostId,
  }) async {
    final suffix = PhoneSuffixUtil.normalize(last4);
    if (suffix.length != 4) {
      return const DemandPhoneDuplicateResult(invalid: true);
    }

    final sources = <String>[];

    if (await _leads.isDuplicateCustomerPhoneSuffix(suffix)) {
      sources.add('leads');
    }

    if (!Env.isConfigured ||
        !SupabaseService.isReady ||
        AuthService.instance.trialSimulatesBackend) {
      return DemandPhoneDuplicateResult(
        duplicate: sources.isNotEmpty,
        sources: sources,
      );
    }

    try {
      final reqs = await SupabaseService.client!
          .from('customer_requirements')
          .select('id, contact_phone, notes')
          .or('contact_phone.like.%$suffix,notes.ilike.%$suffix')
          .limit(3);
      if ((reqs as List).isNotEmpty) sources.add('requirements');

      var postQuery = SupabaseService.client!
          .from('demand_posts')
          .select('id')
          .filter('extra_criteria->>customer_phone_last4', 'eq', suffix);
      if (excludeDemandPostId != null) {
        postQuery = postQuery.neq('id', excludeDemandPostId);
      }
      final posts = await postQuery.limit(3);
      if ((posts as List).isNotEmpty) sources.add('board');

      final offers = await SupabaseService.client!
          .from('demand_offers')
          .select('id')
          .or(
            'external_note.ilike.%$suffix%,admin_notes.ilike.%$suffix%',
          )
          .limit(3);
      if ((offers as List).isNotEmpty) sources.add('offers');
    } catch (_) {
      /* schema บางส่วนอาจยังไม่พร้อม */
    }

    return DemandPhoneDuplicateResult(
      duplicate: sources.isNotEmpty,
      sources: sources.toSet().toList(),
    );
  }
}

class DemandPhoneDuplicateResult {
  const DemandPhoneDuplicateResult({
    this.duplicate = false,
    this.invalid = false,
    this.sources = const [],
  });

  final bool duplicate;
  final bool invalid;
  final List<String> sources;
}
