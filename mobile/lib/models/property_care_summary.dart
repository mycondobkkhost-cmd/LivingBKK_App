import 'property_care_right.dart';

/// ทรัพย์ที่ผู้ใช้ดูแล — สรุปสำหรับหน้าบ้าน
class PropertyCareSummary {
  const PropertyCareSummary({
    required this.right,
    this.inventoryCode,
    this.canonicalTitle,
    this.district,
    this.memberCount,
    this.pendingDataCount = 0,
    this.primaryListingCode,
  });

  final PropertyCareRight right;
  final String? inventoryCode;
  final String? canonicalTitle;
  final String? district;
  final int? memberCount;
  final int pendingDataCount;
  final String? primaryListingCode;

  bool get needsClaim => right.status == 'pending_claim';
  bool get needsOwnerData => pendingDataCount > 0 && !needsClaim;
}
