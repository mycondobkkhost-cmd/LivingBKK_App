import '../data/listing_form_options.dart';

/// ร่างแปลจากข้อมูลไทย — ให้ผู้ใช้แก้ก่อนส่ง (ไม่ใช่แปลอัตโนมัติเต็มรูปแบบ)
abstract final class ListingDraftTranslate {
  static String titleEn(String thTitle) => thTitle.trim();

  static String descriptionEn(
    String thTitle,
    String thDesc, {
    List<String> hashtagIds = const [],
    List<String> facilityIds = const [],
  }) {
    final t = thTitle.trim();
    final d = thDesc.trim();
    final highlights = ListingFormOptions.formatTagsSection(
      hashtagIds,
      facilityIds,
      isEnglish: true,
    );
    final body = StringBuffer()
      ..writeln('Property: $t')
      ..writeln()
      ..writeln('Details:')
      ..writeln(d);
    if (highlights.isNotEmpty) {
      body
        ..writeln()
        ..writeln(highlights);
    }
    body
      ..writeln()
      ..writeln('Contact and viewing via RealXtate only.');
    return body.toString().trim();
  }

  static String titleZh(String thTitle) => thTitle.trim();

  static String descriptionZh(String thTitle, String thDesc) {
    final t = thTitle.trim();
    final d = thDesc.trim();
    return '房源：$t\n\n'
        '详情：\n$d\n\n'
        '请通过 RealXtate 联系与预约看房。';
  }
}
