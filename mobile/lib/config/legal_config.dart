enum LegalDocumentType {
  terms('terms'),
  privacy('privacy');

  const LegalDocumentType(this.pathSegment);
  final String pathSegment;

  static LegalDocumentType? fromPath(String? path) {
    if (path == null) return null;
    for (final t in values) {
      if (t.pathSegment == path) return t;
    }
    return null;
  }
}

/// เวอร์ชันนโยบาย/เงื่อนไข — อัปเดตเมื่อแก้เนื้อหา แล้วบันทึกใน metadata ประกาศ
class LegalConfig {
  LegalConfig._();

  static const version = '2026-06-04-v1';
  static const operatorName = 'RealXtate';
  static const contactEmail = 'privacy@realxtateth.com';
  static const effectiveDate = '4 มิถุนายน 2569';
  static const effectiveDateEn = '4 June 2026';
}
