import '../models/demand_post.dart';
import '../models/listing_public.dart';
import '../data/bangkok_projects.dart';

/// ชื่อโครงการแบบสองภาษา — เช่น ทรู ทองหล่อ (THRU Thonglor)
String bilingualProjectLabel(String? nameTh, String? nameEn) {
  final th = nameTh?.trim();
  final en = nameEn?.trim();
  if (th != null && th.isNotEmpty && en != null && en.isNotEmpty) {
    if (th.toLowerCase() == en.toLowerCase()) return th;
    return '$th ($en)';
  }
  if (th != null && th.isNotEmpty) return th;
  if (en != null && en.isNotEmpty) return en;
  return '';
}

extension BangkokProjectL10n on BangkokProject {
  String get displayBilingual => bilingualProjectLabel(nameTh, nameEn);
}

/// แสดงข้อความตามภาษาที่เลือก — fallback ไทยถ้าไม่มี EN
extension ListingPublicL10n on ListingPublic {
  String localizedTitle(bool isEnglish) =>
      isEnglish && titleEn != null && titleEn!.trim().isNotEmpty ? titleEn! : title;

  String localizedDescription(bool isEnglish) {
    if (isEnglish && descriptionEn != null && descriptionEn!.trim().isNotEmpty) {
      return descriptionEn!;
    }
    return description ?? '';
  }

  String? bilingualProjectName() {
    final label = bilingualProjectLabel(projectName, projectNameEn);
    return label.isEmpty ? null : label;
  }

  String? localizedProjectName(bool isEnglish) => bilingualProjectName();

  String? localizedDistrict(bool isEnglish) {
    if (isEnglish && districtEn != null && districtEn!.trim().isNotEmpty) {
      return districtEn;
    }
    return district;
  }

  String? localizedFloorRange(bool isEnglish) {
    if (isEnglish && floorRangeEn != null && floorRangeEn!.trim().isNotEmpty) {
      return floorRangeEn;
    }
    final th = floorRange?.trim();
    return th != null && th.isNotEmpty ? th : null;
  }

  String displayHeadline(bool isEnglish) =>
      bilingualProjectName() ?? localizedTitle(isEnglish);
}

extension DemandPostL10n on DemandPost {
  String localizedTitle(bool isEnglish) =>
      isEnglish && titleEn != null && titleEn!.trim().isNotEmpty ? titleEn! : title;

  String? localizedDescription(bool isEnglish) {
    if (isEnglish && descriptionEn != null && descriptionEn!.trim().isNotEmpty) {
      return descriptionEn;
    }
    return description;
  }
}

/// แปลชื่อเขตกรุงเทพที่ใช้บ่อยใน demo
String districtLabelEn(String? districtTh) {
  if (districtTh == null || districtTh.isEmpty) return '';
  const map = {
    'วัฒนา': 'Watthana',
    'คลองเตย': 'Khlong Toei',
    'บางนา': 'Bang Na',
    'ห้วยขวาง': 'Huai Khwang',
    'จตุจักร': 'Chatuchak',
    'พญาไท': 'Phaya Thai',
    'สาทร': 'Sathorn',
    'บางรัก': 'Bang Rak',
    'ลาดพร้าว': 'Lat Phrao',
  };
  return map[districtTh] ?? districtTh;
}
