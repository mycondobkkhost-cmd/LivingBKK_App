/// นโยบายรับข้อเสนอบนประกาศบอร์ด — เก็บใน `extra_criteria.accepted_offerer_policy`
enum DemandOfferAcceptancePolicy {
  /// เจ้าของทรัพย์ (owner_direct_100) เท่านั้น
  ownerOnly,

  /// เจ้าของทรัพย์ + โคนายหน้า (owner_direct_100, co_agent_50_50)
  ownerAndCoAgent,
}

/// แหล่งลีดที่นำมาประกาศบนบอร์ด — `extra_criteria.lead_source`
enum DemandLeadSource {
  customerDirect,
  coAgentSourced,
}

abstract final class DemandBoardPostMeta {
  static const policyKey = 'accepted_offerer_policy';
  static const leadSourceKey = 'lead_source';

  /// ลูกค้าเลือก「หาแบบด่วนที่สุด」— แสดงป้ายไฟบนบอร์ดให้เจ้าของ/นายหน้ารีบเสนอ
  static const urgentRushKey = 'urgent_rush';

  static bool isUrgentRushFromExtra(Map<String, dynamic> extra) {
    final v = extra[urgentRushKey];
    if (v == true) return true;
    if (v == 1) return true;
    return v?.toString() == 'true' || v?.toString() == '1';
  }

  static DemandOfferAcceptancePolicy policyFromExtra(
    Map<String, dynamic> extra, {
    DemandOfferAcceptancePolicy fallback = DemandOfferAcceptancePolicy.ownerAndCoAgent,
  }) {
    final raw = extra[policyKey]?.toString();
    switch (raw) {
      case 'owner_only':
        return DemandOfferAcceptancePolicy.ownerOnly;
      case 'owner_and_co_agent':
        return DemandOfferAcceptancePolicy.ownerAndCoAgent;
      default:
        return fallback;
    }
  }

  static DemandLeadSource? leadSourceFromExtra(Map<String, dynamic> extra) {
    switch (extra[leadSourceKey]?.toString()) {
      case 'customer_direct':
        return DemandLeadSource.customerDirect;
      case 'co_agent_sourced':
        return DemandLeadSource.coAgentSourced;
      default:
        return null;
    }
  }

  static String policyToStorage(DemandOfferAcceptancePolicy policy) {
    switch (policy) {
      case DemandOfferAcceptancePolicy.ownerOnly:
        return 'owner_only';
      case DemandOfferAcceptancePolicy.ownerAndCoAgent:
        return 'owner_and_co_agent';
    }
  }

  static String leadSourceToStorage(DemandLeadSource source) {
    switch (source) {
      case DemandLeadSource.customerDirect:
        return 'customer_direct';
      case DemandLeadSource.coAgentSourced:
        return 'co_agent_sourced';
    }
  }

  /// ความสามารถที่อนุญาตในฟอร์มเสนอทรัพย์
  static List<String> allowedOffererCapacities(
    DemandOfferAcceptancePolicy policy,
  ) {
    switch (policy) {
      case DemandOfferAcceptancePolicy.ownerOnly:
        return const ['owner_direct_100'];
      case DemandOfferAcceptancePolicy.ownerAndCoAgent:
        return const ['owner_direct_100', 'co_agent_50_50'];
    }
  }

  static bool capacityAllowed(
    DemandOfferAcceptancePolicy policy,
    String capacity,
  ) =>
      allowedOffererCapacities(policy).contains(capacity);
}
