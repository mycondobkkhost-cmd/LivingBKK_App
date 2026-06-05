/// กฎฟอร์มลงประกาศ — อ้างอิง flow LI (เจ้าของ/เอเจนท์)
enum ListingPosterRole {
  owner,
  agent,
}

/// ทำเล / โครงการ
enum ListingLocationScope {
  /// เลือกจากทะเบียนโครงการ — ปักหมุดจากแคตตาล็อก
  catalogProject,

  /// กรอกชื่อโครงการ/ทำเลเอง (ยังไม่อยู่ในระบบ)
  customProject,

  /// ไม่ระบุโครงการ (เช่น บ้านนอกโครงการ)
  standalone,
}

abstract final class ListingCreateRules {
  /// ประเภทที่ถือว่า「อยู่ในโครงการ」แม้กรอกเอง — ไม่บังคับลิงก์แผนที่
  static const projectStyleTypes = {'condo', 'apartment'};

  /// ต้องใส่ลิงก์โลเคชัน (Google Maps ฯลฯ) เมื่อไม่มีโครงการในระบบ และเป็นทรัพย์แบบบ้าน/ที่ดิน
  static bool requiresLocationLink({
    required ListingLocationScope scope,
    required String propertyTypeDb,
  }) {
    if (scope == ListingLocationScope.catalogProject) return false;
    if (projectStyleTypes.contains(propertyTypeDb)) return false;
    return true;
  }

  static bool isValidLocationUrl(String url) {
    final t = url.trim().toLowerCase();
    if (t.isEmpty) return false;
    return t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.contains('maps.google') ||
        t.contains('goo.gl/maps') ||
        t.contains('google.com/maps');
  }

  static ListingPosterRole defaultPosterRole(bool isAgentPerspective) =>
      isAgentPerspective ? ListingPosterRole.agent : ListingPosterRole.owner;

  static String listedByRoleDb(ListingPosterRole role) =>
      role == ListingPosterRole.agent ? 'agent' : 'owner';

  static bool ownerVerifiedFor(ListingPosterRole role) =>
      role == ListingPosterRole.owner;
}
