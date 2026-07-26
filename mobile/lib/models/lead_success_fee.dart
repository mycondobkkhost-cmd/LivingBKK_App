import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../models/offer_commission_scheme.dart';
import '../utils/listing_offer_meta.dart';

/// Success Fee ที่ผู้รับเคสต้องจ่ายเมื่อปิดดีล — ไม่ใช่ส่วนแบ่งภายในแพลตฟอร์ม
class LeadSuccessFeeSummary {
  const LeadSuccessFeeSummary({
    required this.contractLabel,
    required this.feeRuleLine,
    required this.feeAmountLine,
    required this.capacityLine,
  });

  final String contractLabel;
  final String feeRuleLine;
  final String? feeAmountLine;
  final String capacityLine;

  static int contractMonths(String? code) {
    if (code == null || code.isEmpty) return 12;
    final lower = code.toLowerCase();
    if (lower == '6m' ||
        (lower.contains('6') &&
            (lower.contains('เดือน') || lower.contains('month')))) {
      return 6;
    }
    if (lower == '24m' ||
        lower.contains('24') ||
        lower.contains('2 ปี') ||
        lower.contains('2 year')) {
      return 24;
    }
    if (lower == '12m' ||
        lower.contains('12') ||
        lower.contains('1 ปี') ||
        lower.contains('1 year')) {
      return 12;
    }
    final n = int.tryParse(code.replaceAll(RegExp(r'\D'), ''));
    return n ?? 12;
  }

  static String _contractLabel(AppStrings s, String? code) {
    switch (code) {
      case '6m':
        return s.contract6Months;
      case '12m':
        return s.contract1Year;
      case '24m':
        return s.contract2Years;
      default:
        return s.contract1Year;
    }
  }

  static String _formatBaht(double? amount, AppStrings s) {
    if (amount == null) return '—';
    return NumberFormat.currency(
      locale: s.isEnglish ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    ).format(amount);
  }

  static LeadSuccessFeeSummary compute({
    required AppStrings s,
    required Map<String, dynamic> lead,
    ListingPublic? listing,
  }) {
    final contractCode = lead['contract_duration']?.toString();
    final months = contractMonths(contractCode);
    final capacity = listing != null
        ? ListingOfferMeta.offererCapacity(listing)
        : 'owner_direct_100';
    final isCoAgent = OfferCommissionScheme.isCoAgentCapacity(capacity);

    final listingType = listing?.listingType ??
        (lead['listing_code']?.toString().toUpperCase().startsWith('SALE') == true
            ? 'sale'
            : 'rent');
    final isSale = OfferCommissionScheme.isSaleListing(listingType);

    final price = listing?.priceNet ?? (lead['budget'] as num?)?.toDouble();

    if (isSale) {
      final pct = isCoAgent ? 1.5 : 3.0;
      final amount = price != null ? price * pct / 100 : null;
      final rule = isCoAgent
          ? s.offerCommissionCoSale1_5
          : s.offerCommissionOwnerSale3;
      return LeadSuccessFeeSummary(
        contractLabel: s.t('ขาย', 'Sale'),
        feeRuleLine: rule,
      feeAmountLine: amount != null
          ? s.leadSuccessFeeAmountEstimate(_formatBaht(amount, s))
          : null,
        capacityLine: isCoAgent
            ? s.leadSuccessFeeCapacityCoAgent
            : s.leadSuccessFeeCapacityOwner,
      );
    }

    final monthly = price;
    final ownerFee =
        monthly != null ? monthly * months / 12 : null;
    final fee = isCoAgent && ownerFee != null ? ownerFee * 0.5 : ownerFee;

    String rule;
    if (isCoAgent) {
      rule = months >= 24
          ? s.offerCommissionCoRent5050
          : s.leadSuccessFeeCoRentRule(months);
    } else {
      rule = months >= 24
          ? s.offerCommissionRent2Yr
          : months <= 6
              ? s.leadSuccessFeeOwnerRentShortRule
              : s.offerCommissionRent1Yr;
    }

    return LeadSuccessFeeSummary(
      contractLabel: _contractLabel(s, contractCode),
      feeRuleLine: rule,
      feeAmountLine: fee != null
          ? s.leadSuccessFeeAmountEstimate(_formatBaht(fee, s))
          : null,
      capacityLine: isCoAgent
          ? s.leadSuccessFeeCapacityCoAgent
          : s.leadSuccessFeeCapacityOwner,
    );
  }
}
