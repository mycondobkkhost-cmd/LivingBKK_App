import '../data/bangkok_projects.dart';
import '../models/listing_public.dart';

/// กรุงเทพฯ + ปริมณฑล (นนทบุรี ปทุมธานี สมุทรปราการ สมุทรสาคร นครปฐม)
class MetroRegion {
  MetroRegion._();

  static const provinceSlugs = [
    'bangkok',
    'nonthaburi',
    'pathum-thani',
    'samut-prakan',
    'samut-sakhon',
    'nakhon-pathom',
  ];

  static const _excludedKeywords = [
    'chiang mai',
    'เชียงใหม่',
    'phuket',
    'ภูเก็ต',
    'pattaya',
    'พัทยา',
    'chonburi',
    'ชลบุรี',
    'rayong',
    'ระยอง',
    'khon kaen',
    'ขอนแก่น',
    'hat yai',
    'หาดใหญ่',
    'songkhla',
    'สงขลา',
    'udon',
    'อุดร',
    'nakhon ratchasima',
    'โคราช',
  ];

  static const _metroDistrictHints = [
    'กรุงเทพ',
    'bangkok',
    'นนทบุรี',
    'nonthaburi',
    'ปทุมธานี',
    'pathum',
    'สมุทรปราการ',
    'samut prakan',
    'samut sakhon',
    'นครปฐม',
    'nakhon pathom',
    'บางใหญ่',
    'บางบัวทอง',
    'บางกรวย',
    'เมืองนนทบุรี',
    'เมืองปทุมธานี',
    'คลองหลวง',
    'รังสิต',
    'บางพลี',
    'พระประแดง',
  ];

  /// กรอบพิกัด กทม.+ปริมณฑล (โดยประมาณ)
  static bool coordsInMetro(double lat, double lng) {
    return lat >= 13.42 &&
        lat <= 14.28 &&
        lng >= 100.12 &&
        lng <= 100.98;
  }

  static bool _textExcluded(String text) {
    final hay = text.toLowerCase();
    return _excludedKeywords.any(hay.contains);
  }

  static bool _textInMetro(String text) {
    final hay = text.toLowerCase();
    if (_textExcluded(hay)) return false;
    return _metroDistrictHints.any(hay.contains);
  }

  static bool isMetroProject(BangkokProject p) {
    final text = '${p.district} ${p.nameTh} ${p.nameEn} ${p.bts ?? ''}';
    if (_textExcluded(text)) return false;
    if (coordsInMetro(p.lat, p.lng)) return true;
    return _textInMetro(text);
  }

  static bool isMetroListing(ListingPublic l) {
    final text = [
      l.district,
      l.districtEn,
      l.projectName,
      l.projectNameEn,
      l.title,
      l.geoZoneSlug,
    ].whereType<String>().join(' ');
    if (_textExcluded(text)) return false;

    final lat = l.lat;
    final lng = l.lng;
    if (lat != null && lng != null && coordsInMetro(lat, lng)) return true;

    if (l.geoZoneSlug != null && provinceSlugs.contains(l.geoZoneSlug)) {
      return true;
    }

    return _textInMetro(text);
  }

  static List<BangkokProject> filterProjects(List<BangkokProject> source) =>
      source.where(isMetroProject).toList();

  static List<ListingPublic> filterListings(List<ListingPublic> source) =>
      source.where(isMetroListing).toList();
}
