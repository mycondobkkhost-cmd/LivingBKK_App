import '../config/code_glossary.dart';

/// รหัสทรัพย์ + หมายเลขธุรกรรม — คำอธิบายไทยดู [CodeGlossary]
///
/// ประกาศ: `RENT-CD-2026-000042` (ประเภทธุรกรรม · ประเภททรัพย์ · ปี · ลำดับ)
/// ทะเบียนกลาง: `RXT-2026-000001` (RealXtate · หน่วยทรัพย์รวมหลายโพสต์)
/// แชท:   `CHAT-2026-000001`
/// Lead:  `LEAD-2026-000001`
/// นัด:   `APPT-2026-000001`
abstract final class ReferenceCodes {
  /// รหัสทะเบียนทรัพย์กลาง (RXT) — ดู [CodeGlossary.inventory]
  static const inventoryPrefix = 'RXT';

  static const _legacyInventoryPrefixes = ['RXT', 'PPTR', 'PTP'];
  static String propertyPrefix(String propertyType) {
    switch (propertyType) {
      case 'house':
        return 'HS';
      case 'townhouse':
        return 'TH';
      case 'apartment':
        return 'AP';
      case 'other':
        return 'OT';
      case 'condo':
      default:
        return 'CD';
    }
  }

  static String listingTypePrefix(String listingType) =>
      listingType == 'sale' ? 'SALE' : 'RENT';

  /// รหัสประกาศ PIR — ตัวอย่าง demo (production ใช้ trigger ใน Supabase)
  static String pirListingCode({int sequence = 1, DateTime? date}) {
    final d = date ?? DateTime.now();
    final dd = '${d.day.toString().padLeft(2, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${(d.year % 100).toString().padLeft(2, '0')}';
    return 'PIR$dd-${sequence.toString().padLeft(4, '0')}';
  }

  static final RegExp pirListingPattern =
      RegExp(r'PIR\d{6}-\d{4}', caseSensitive: false);

  /// สร้างรหัสทรัพย์ตามหมวด (ใช้ demo / preview — production ใช้ trigger ใน Supabase)
  static String listingCode({
    required String listingType,
    required String propertyType,
    required int sequence,
    int? year,
  }) {
    final y = year ?? DateTime.now().year;
    return '${listingTypePrefix(listingType)}-${propertyPrefix(propertyType)}-$y-'
        '${sequence.toString().padLeft(6, '0')}';
  }

  static String transactionRef(String kind, int sequence, {int? year}) {
    final y = year ?? DateTime.now().year;
    final prefix = switch (kind) {
      'chat' => 'CHAT',
      'lead' => 'LEAD',
      'appt' => 'APPT',
      _ => 'TXN',
    };
    return '$prefix-$y-${sequence.toString().padLeft(6, '0')}';
  }

  /// อ้างอิงแชท demo ที่ stable จาก seed string
  static String demoChatRef(String seed, {int offset = 0}) {
    final n = (seed.hashCode.abs() + offset) % 999999 + 1;
    return transactionRef('chat', n);
  }

  static String demoLeadRef(String seed) {
    final n = seed.hashCode.abs() % 999999 + 1;
    return transactionRef('lead', n);
  }

  static String demoApptRef(String seed) {
    final n = seed.hashCode.abs() % 999999 + 1;
    return transactionRef('appt', n);
  }

  /// รหัสพิเศษ (discovery / staff) — ไม่ใช่ทรัพย์จริง
  static bool isSpecialListingCode(String code) {
    final upper = code.toUpperCase();
    return upper == 'DISCOVERY' ||
        upper.startsWith('SUPPORT') ||
        upper.startsWith('REQ-') ||
        upper.startsWith('DEMAND-') ||
        upper.startsWith('DM-') ||
        upper.startsWith('OFR');
  }

  static bool isPirListingCode(String code) =>
      pirListingPattern.hasMatch(code.trim().toUpperCase());

  /// รหัสทะเบียนกลาง RXT-YYYY-###### (รองรับ PPTR/PTP เก่า)
  static bool isInventoryCode(String code) {
    final upper = code.trim().toUpperCase();
    for (final p in _legacyInventoryPrefixes) {
      if (upper.startsWith('$p-')) return true;
    }
    return false;
  }

  static String inventoryCode({required int sequence, int? year}) {
    final y = year ?? DateTime.now().year;
    return '$inventoryPrefix-$y-${sequence.toString().padLeft(6, '0')}';
  }
}
