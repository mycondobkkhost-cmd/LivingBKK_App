import 'demo_cast_catalog.dart';

/// เอเจ้นพานัดชม — จาก DemoCastCatalog (guide-01 … guide-10)
class ViewingStaffMember {
  const ViewingStaffMember({
    required this.slug,
    required this.profileId,
    required this.nameEn,
    required this.nameTh,
    required this.phone,
    required this.email,
  });

  final String slug;
  final String profileId;
  final String nameEn;
  final String nameTh;
  final String phone;
  final String email;

  String label({required bool isEn}) => isEn ? nameEn : nameTh;
}

abstract final class ViewingStaffCatalog {
  static List<ViewingStaffMember> get agents => DemoCastCatalog.guides
      .map(
        (g) => ViewingStaffMember(
          slug: g.staffSlug ?? g.castId,
          profileId: g.profileId,
          nameEn: g.displayNameEn,
          nameTh: g.displayNameTh,
          phone: g.phone ?? '',
          email: '${g.castId}@cast.proppiter.local',
        ),
      )
      .toList();

  static ViewingStaffMember? bySlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    for (final a in agents) {
      if (a.slug == slug) return a;
    }
    return null;
  }

  static ViewingStaffMember? byProfileId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in agents) {
      if (a.profileId == id) return a;
    }
    return null;
  }

  static ViewingStaffMember? byAnyId(String? id) => bySlug(id) ?? byProfileId(id);

  static List<({String id, String th, String en, String phone})> get pickerOptions =>
      agents
          .map(
            (a) => (
              id: a.profileId,
              th: a.nameTh,
              en: a.nameEn,
              phone: a.phone,
            ),
          )
          .toList();

  static String label(String? assignedTo, {required bool isEn}) {
    if (assignedTo == null || assignedTo.trim().isEmpty) {
      return isEn ? 'Unassigned' : 'ยังไม่ระบุ';
    }
    final hit = byAnyId(assignedTo.trim());
    if (hit != null) return hit.label(isEn: isEn);
    final cast = DemoCastCatalog.guideByProfileId(assignedTo);
    if (cast != null) return cast.displayName(isEn);
    if (assignedTo.contains('·') || assignedTo.contains('@')) return assignedTo;
    return assignedTo;
  }

  static String? phone(String? assignedTo) {
    if (assignedTo == null || assignedTo.isEmpty) return null;
    return byAnyId(assignedTo)?.phone;
  }

  static bool matchesAppointment({
    required String? assignedTo,
    String? staffUserId,
    String? staffSlug,
  }) {
    if (staffUserId == null && staffSlug == null) return true;
    final at = assignedTo?.trim();
    if (at == null || at.isEmpty) return false;
    if (staffUserId != null && at == staffUserId) return true;
    if (staffSlug != null && at == staffSlug) return true;
    final member = byAnyId(at);
    if (member == null) return false;
    if (staffUserId != null && member.profileId == staffUserId) return true;
    if (staffSlug != null && member.slug == staffSlug) return true;
    return false;
  }
}
