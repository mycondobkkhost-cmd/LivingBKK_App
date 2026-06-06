import 'package:flutter/material.dart';

import '../data/bangkok_geo_zone_tags.dart';
import '../data/bangkok_projects.dart';
import '../l10n/app_strings.dart';
import '../models/demand_post.dart';
import '../models/listing_public.dart';
import 'transit_proximity.dart';

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

  /// ชื่อโครงการตามภาษาที่เลือก — ไม่รวมสองภาษาในบรรทัดเดียว
  String? localizedProjectName(bool isEnglish) {
    if (isEnglish) {
      final en = projectNameEn?.trim();
      if (en != null && en.isNotEmpty) return en;
      final th = projectName?.trim();
      if (th != null && th.isNotEmpty) return th;
      return null;
    }
    final th = projectName?.trim();
    if (th != null && th.isNotEmpty) return th;
    final en = projectNameEn?.trim();
    if (en != null && en.isNotEmpty) return en;
    return null;
  }

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
      localizedProjectName(isEnglish) ?? localizedTitle(isEnglish);

  /// สเปกบนการ์ด — ห้องนอน · ตร.ม. · ชั้น (ไม่รวมห้องน้ำ — ดูในหน้ารายละเอียด)
  List<({IconData icon, String label})> listingCardSpecItems(AppStrings s) {
    final en = s.isEnglish;
    final out = <({IconData icon, String label})>[];

    if (bedrooms != null) {
      out.add((
        icon: Icons.bed_outlined,
        label: s.bedroomCardLabel(bedrooms!),
      ));
    }
    if (areaSqm != null && areaSqm! > 0) {
      out.add((
        icon: Icons.square_foot_outlined,
        label: s.areaCardLabel(areaSqm!),
      ));
    }
    final floor = localizedFloorRange(en);
    if (floor != null && floor.isNotEmpty) {
      out.add((
        icon: Icons.layers_outlined,
        label: floor,
      ));
    }
    return out;
  }

  /// แท็กทำเลบนการ์ด — สถานีรถไฟ (ชัวร์) ก่อน แล้วตามด้วยย่าน
  List<String> listingCardLocationTags(bool isEnglish) {
    final out = <String>[];

    if (lat != null && lng != null) {
      final hits = TransitProximity.fromCoordinates(
        lat!,
        lng!,
        maxKm: 0.65,
        limit: 1,
      );
      if (hits.isNotEmpty && hits.first.distanceKm <= 0.65) {
        final st = hits.first.station;
        out.add(isEnglish ? st.labelEn : st.labelTh);
      }
    }

    if (geoZoneSlug != null) {
      for (final z in BangkokGeoZoneTags.all) {
        if (z.slug == geoZoneSlug) {
          final label = z.label(isEnglish);
          if (!out.contains(label)) out.add(label);
          break;
        }
      }
    }

    if (out.length < 2) {
      final district = localizedDistrict(isEnglish)?.trim();
      if (district != null &&
          district.isNotEmpty &&
          !out.any((t) => t.contains(district) || district.contains(t))) {
        out.add(district);
      }
    }

    return out.take(2).toList();
  }
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
