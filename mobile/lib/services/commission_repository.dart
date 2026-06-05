import '../config/env.dart';
import '../models/commission_tier.dart';
import 'supabase_service.dart';

class CommissionRepository {
  Future<List<CommissionTier>> fetchActiveTiers() async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      return CommissionTier.demo();
    }

    final data = await SupabaseService.client!
        .from('commission_tiers')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (data as List)
        .map((e) => CommissionTier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  CommissionTier? tierForContract(List<CommissionTier> tiers, String? contractDuration) {
    if (contractDuration == null) return tiers.isNotEmpty ? tiers.first : null;
    final months = _monthsFromContract(contractDuration);
    for (final t in tiers) {
      final max = t.maxMonths;
      if (months >= t.minMonths && (max == null || months <= max)) {
        return t;
      }
    }
    return tiers.isNotEmpty ? tiers.last : null;
  }

  int _monthsFromContract(String code) {
    switch (code) {
      case '6m':
        return 6;
      case '12m':
        return 12;
      case '24m':
        return 24;
      default:
        final n = int.tryParse(code.replaceAll(RegExp(r'\D'), ''));
        return n ?? 12;
    }
  }
}
