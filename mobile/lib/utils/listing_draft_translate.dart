/// ร่างแปลจากข้อมูลไทย — ให้ผู้ใช้แก้ก่อนส่ง (ไม่ใช่แปลอัตโนมัติเต็มรูปแบบ)
abstract final class ListingDraftTranslate {
  static String titleEn(String thTitle) => thTitle.trim();

  static String descriptionEn(String thTitle, String thDesc) {
    final t = thTitle.trim();
    final d = thDesc.trim();
    return 'Property: $t\n\n'
        'Details:\n$d\n\n'
        'Contact and viewing via PROPPITER only.';
  }

  static String titleZh(String thTitle) => thTitle.trim();

  static String descriptionZh(String thTitle, String thDesc) {
    final t = thTitle.trim();
    final d = thDesc.trim();
    return '房源：$t\n\n'
        '详情：\n$d\n\n'
        '请通过 PROPPITER 联系与预约看房。';
  }
}
