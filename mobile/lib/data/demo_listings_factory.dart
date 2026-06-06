import 'dart:math';

import '../models/listing_public.dart';
import '../services/listing_activity_service.dart';
import '../utils/localized_content.dart';
import '../utils/metro_region.dart';
import '../utils/reference_codes.dart';
import 'bangkok_projects.dart';

/// สร้างทรัพย์ตัวอย่างจำนวนมากจากฐานโครงการกรุงเทพ
class DemoListingsFactory {
  static final _rng = Random(42);

  static List<String> _imagesFor(String slug, int unit) {
    final count = 5 + (unit % 3);
    return List.generate(
      count,
      (i) => 'https://picsum.photos/seed/$slug-$unit-$i/800/600',
    );
  }

  static const _floorOptions = [
    ('ชั้นสูง', 'High floor'),
    ('ชั้นกลาง', 'Mid floor'),
    ('ชั้น 12-15', 'Floor 12-15'),
    ('ชั้น 20+', 'Floor 20+'),
    ('ชั้น 8-10', 'Floor 8-10'),
  ];

  static List<ListingPublic> generate({int targetCount = 72}) {
    final out = <ListingPublic>[];
    var codeSeq = 1;

    for (final project in MetroRegion.filterProjects(BangkokProjects.all)) {
      final unitsPerProject = project.propertyType == 'condo'
          ? 2 + _rng.nextInt(3)
          : 1 + _rng.nextInt(2);

      for (var u = 0; u < unitsPerProject; u++) {
        if (out.length >= targetCount) break;

        final isRent = _rng.nextDouble() > 0.22;
        final bedrooms = project.propertyType == 'condo'
            ? _rng.nextInt(3)
            : 2 + _rng.nextInt(2);
        final area = project.propertyType == 'condo'
            ? 28.0 + _rng.nextInt(35)
            : 90.0 + _rng.nextInt(80);

        var price = isRent
            ? (12000 + _rng.nextInt(45000)).toDouble()
            : (2500000 + _rng.nextInt(12000000)).toDouble();

        if (project.bts?.contains('อโศก') == true ||
            project.bts?.contains('ทองหล่อ') == true) {
          price = isRent ? price * 1.15 : price * 1.08;
        }

        final lat = project.lat + (_rng.nextDouble() - 0.5) * 0.004;
        final lng = project.lng + (_rng.nextDouble() - 0.5) * 0.004;

        final bedLabelTh = bedrooms == 0 ? 'สตูดิโอ' : '$bedrooms นอน';
        final bedLabelEn = bedrooms == 0 ? 'Studio' : '$bedrooms bed';
        final title = isRent
            ? '$bedLabelTh · ${project.nameTh}'
            : '${project.nameTh} ขาย';
        final titleEn = isRent
            ? '$bedLabelEn · ${project.nameEn}'
            : '${project.nameEn} for sale';

        final coEligible = _rng.nextDouble() > 0.65;
        final pet = _rng.nextDouble() > 0.55;
        final floor = _floorOptions[_rng.nextInt(_floorOptions.length)];

        final btsOrDistrict = project.bts ?? project.district;
        final desc = isRent
            ? 'ห้อง$bedLabelTh โครงการ${project.nameTh} ทำเล$btsOrDistrict '
                'พื้นที่ ${area.toInt()} ตร.ม. สภาพพร้อมเข้าอยู่ วิวเมือง ส่วนกลางครบ'
            : 'ขาย${project.nameTh} $bedLabelTh ${area.toInt()} ตร.ม. '
                'ทำเล$btsOrDistrict เหมาะอยู่อาศัย/ลงทุน';
        final descEn = isRent
            ? '$bedLabelEn at ${project.nameEn}, $btsOrDistrict area. '
                '${area.toInt()} sqm, move-in ready, city view, full facilities.'
            : '${project.nameEn} for sale — $bedLabelEn, ${area.toInt()} sqm. '
                '$btsOrDistrict area, live or invest.';

        final txnType = isRent
            ? 'rent'
            : (_rng.nextDouble() > 0.9 ? 'sale_installment' : 'sale');

        out.add(
          ListingPublic(
            id: 'demo-${project.slug}-$u',
            listingCode: ReferenceCodes.listingCode(
              listingType: txnType,
              propertyType: project.propertyType,
              sequence: codeSeq,
            ),
            listingType: txnType,
            title: title,
            titleEn: titleEn,
            priceNet: price.roundToDouble(),
            district: project.district,
            districtEn: districtLabelEn(project.district),
            projectName: project.nameTh,
            projectNameEn: project.nameEn,
            propertyType: project.propertyType,
            areaSqm: area,
            bedrooms: bedrooms,
            bathrooms: bedrooms == 0 ? 1 : (bedrooms >= 2 ? 2 : 1),
            floorRange: floor.$1,
            floorRangeEn: floor.$2,
            yieldPercent: !isRent && _rng.nextDouble() > 0.5
                ? 4.5 + _rng.nextDouble() * 3
                : null,
            coAgentListingType: coEligible
                ? (_rng.nextBool() ? 'co_agent_50_50' : 'owner_direct')
                : 'owner_direct',
            investorCategory: !isRent
                ? (_rng.nextDouble() > 0.85
                    ? 'bmv'
                    : _rng.nextDouble() > 0.5
                        ? 'with_tenant'
                        : 'none')
                : 'none',
            coAgentEligible: coEligible,
            petAllowed: pet,
            lat: lat,
            lng: lng,
            geoZoneSlug: _geoZoneFor(project),
            imageUrls: _imagesFor(project.slug, u),
            description: desc,
            descriptionEn: descEn,
            ownerExclusiveMandate: codeSeq == 1 && isRent,
            ownerExclusiveContractDays: codeSeq == 1 && isRent ? 30 : null,
            agentExclusive: codeSeq == 2,
            lastBumpAt: codeSeq <= 2 ? DateTime.now() : null,
          ),
        );
        codeSeq++;
      }
      if (out.length >= targetCount) break;
    }

    out.sort((a, b) => a.priceNet.compareTo(b.priceNet));
    return out;
  }

  static List<ListingPublic> get cached {
    _cache ??= generate();
    return _cache!;
  }

  static void invalidateCache() => _cache = null;

  static List<ListingPublic>? _cache;

  static String _geoZoneFor(BangkokProject project) {
    final probe = ListingPublic(
      id: 'z',
      listingCode: 'z',
      listingType: 'rent',
      title: '${project.nameTh} ${project.bts ?? ''}',
      priceNet: 0,
      district: project.district,
      projectName: project.nameTh,
      propertyType: project.propertyType,
    );
    return inferGeoZoneSlug(probe) ?? 'bangkok-all';
  }
}
