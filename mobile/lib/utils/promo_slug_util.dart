import 'project_import_url.dart';

/// สร้าง slug อัตโนมัติสำหรับโฆษณาหน้าแรก
abstract final class PromoSlugUtil {
  static String autofill({
    required String titleTh,
    String? titleEn,
  }) {
    final fromEn = ProjectImportUrl.slugify(titleEn ?? '');
    if (fromEn.isNotEmpty) return fromEn;

    final fromTh = ProjectImportUrl.slugify(titleTh);
    if (fromTh.isNotEmpty) return fromTh;

    final seed = titleTh.trim();
    if (seed.isNotEmpty) {
      final hash = seed.hashCode.abs().toRadixString(36);
      return 'promo_$hash';
    }

    return 'promo_${DateTime.now().millisecondsSinceEpoch}';
  }
}
