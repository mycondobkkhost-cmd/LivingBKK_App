import '../utils/reference_codes.dart';

/// ศัพท์รหัสมาตรฐาน — อธิบายเป็นภาษาไทย (ไม่ต้องรู้อังกฤษ)
///
/// หลัก: ตัวอักษรในรหัส = คำย่อที่อ่านออกเสียงได้ + มีชื่อไทยชัดเจนใน UI เสมอ
abstract final class CodeGlossary {
  static const brandName = 'RealXtate';

  /// ทะเบียนทรัพย์กลาง — RXT-ปี-ลำดับ
  static const inventory = CodeKind(
    prefix: 'RXT',
    nameTh: 'ทะเบียนทรัพย์',
    nameEn: 'Property registry',
    hintTh: 'รหัสกลางรวมหลายประกาศเป็นทรัพย์เดียวกัน',
  );

  static const listingRent = CodeKind(
    prefix: 'เช่า',
    altPrefix: 'RENT',
    nameTh: 'ประกาศเช่า',
    nameEn: 'For rent',
    hintTh: 'รูปแบบ เช่า-ประเภททรัพย์-ปี-ลำดับ',
  );

  static const listingSale = CodeKind(
    prefix: 'ขาย',
    altPrefix: 'SALE',
    nameTh: 'ประกาศขาย',
    nameEn: 'For sale',
    hintTh: 'รูปแบบ ขาย-ประเภททรัพย์-ปี-ลำดับ',
  );

  static const propertyTypes = <String, String>{
    'CD': 'คอนโด',
    'HS': 'บ้านเดี่ยว',
    'TH': 'ทาวน์เฮาส์',
    'AP': 'อพาร์ทเมนต์',
    'OT': 'อื่นๆ',
  };

  static const chatRef = CodeKind(
    prefix: 'CHAT',
    nameTh: 'รหัสแชท',
    nameEn: 'Chat ref',
    hintTh: 'อ้างอิงห้องสนทนา',
  );

  static const leadRef = CodeKind(
    prefix: 'LEAD',
    nameTh: 'รหัสลูกค้าเป้าหมาย',
    nameEn: 'Lead ref',
    hintTh: 'ลูกค้าที่สนใจทรัพย์',
  );

  static const apptRef = CodeKind(
    prefix: 'APPT',
    nameTh: 'รหัสนัดชม',
    nameEn: 'Viewing ref',
    hintTh: 'นัดดูทรัพย์',
  );

  static const importRef = CodeKind(
    prefix: 'IMP',
    nameTh: 'รหัสนำเข้า',
    nameEn: 'Import ref',
    hintTh: 'นำเข้าจากลิงก์ภายนอก',
  );

  static const profileTags = <String, String>{
    'SP': 'แท็กตัวเอง (ลูกค้านัด)',
    'PR': 'แท็กผู้นำชม (โคเอ)',
    'CL': 'แท็กลูกค้า (แทนคนอื่น)',
  };

  /// บทบาทผู้ดูแลทรัพย์ (ไม่ใช่เจ้าของกฎหมายเสมอ)
  static const careRoles = <String, String>{
    'team_steward': 'ทีมดูแลแทน',
    'primary_caretaker': 'ผู้ดูแลหลัก',
    'co_agent_caretaker': 'โคเอดูแล',
    'customer_caretaker': 'ลูกค้าดูแลแทน',
    'view_only': 'ดูอย่างเดียว',
  };

  static const careStatus = <String, String>{
    'active': 'ใช้งานอยู่',
    'pending_claim': 'รอรับสิทธิ์',
    'revoked': 'ถอนสิทธิ์แล้ว',
  };

  /// คำอธิบายสั้นสำหรับแสดงใต้รหัส
  static String captionFor(String code, {bool isEn = false}) {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) return '';

    if (ReferenceCodes.isInventoryCode(upper)) {
      return isEn ? inventory.nameEn : inventory.nameTh;
    }
    if (upper.startsWith('RENT-') || upper.startsWith('เช่า')) {
      return _listingCaption(upper, rent: true, isEn: isEn);
    }
    if (upper.startsWith('SALE-') || upper.startsWith('ขาย')) {
      return _listingCaption(upper, rent: false, isEn: isEn);
    }
    if (upper.startsWith('CHAT-')) {
      return isEn ? chatRef.nameEn : chatRef.nameTh;
    }
    if (upper.startsWith('LEAD-')) {
      return isEn ? leadRef.nameEn : leadRef.nameTh;
    }
    if (upper.startsWith('APPT-')) {
      return isEn ? apptRef.nameEn : apptRef.nameTh;
    }
    if (upper.startsWith('IMP-') || upper.startsWith('IMPORT-')) {
      return isEn ? importRef.nameEn : importRef.nameTh;
    }
    for (final entry in profileTags.entries) {
      if (upper.startsWith('${entry.key}-')) {
        return entry.value;
      }
    }
    return isEn ? 'Reference code' : 'รหัสอ้างอิง';
  }

  static String careRoleLabel(String role, {bool isEn = false}) {
    if (isEn) return role;
    return careRoles[role] ?? role;
  }

  static String careStatusLabel(String status, {bool isEn = false}) {
    if (isEn) return status;
    return careStatus[status] ?? status;
  }

  static String _listingCaption(String upper, {required bool rent, required bool isEn}) {
    final parts = upper.split('-');
    final typeKey = parts.length > 1 ? parts[1] : '';
    final typeTh = propertyTypes[typeKey] ?? typeKey;
    if (isEn) {
      return rent ? 'Listing · rent · $typeKey' : 'Listing · sale · $typeKey';
    }
    final deal = rent ? 'ประกาศเช่า' : 'ประกาศขาย';
    return typeTh.isEmpty ? deal : '$deal · $typeTh';
  }
}

class CodeKind {
  const CodeKind({
    required this.prefix,
    required this.nameTh,
    required this.nameEn,
    this.altPrefix,
    this.hintTh,
  });

  final String prefix;
  final String? altPrefix;
  final String nameTh;
  final String nameEn;
  final String? hintTh;
}
