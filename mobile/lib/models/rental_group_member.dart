/// สมาชิกแชทกลุ่มสัญญาเช่า — แสดงชื่อ/บทบาทเท่านั้น (ไม่มี PII)
enum RentalMemberRole { tenant, owner, agent, admin }

class RentalGroupMember {
  const RentalGroupMember({
    required this.userId,
    required this.role,
    required this.displayLabel,
    this.profileTagCode,
  });

  final String userId;
  final RentalMemberRole role;
  /// เช่น "ผู้เช่า · คุณมิ้นท์" หรือ "เอเจ้นท์ · PR-2026-00012"
  final String displayLabel;
  final String? profileTagCode;

  String get roleLabelTh => switch (role) {
        RentalMemberRole.tenant => 'ผู้เช่า',
        RentalMemberRole.owner => 'เจ้าของ',
        RentalMemberRole.agent => 'เอเจ้นท์',
        RentalMemberRole.admin => 'แอดมิน',
      };

  String get roleLabelEn => switch (role) {
        RentalMemberRole.tenant => 'Tenant',
        RentalMemberRole.owner => 'Owner',
        RentalMemberRole.agent => 'Agent',
        RentalMemberRole.admin => 'Admin',
      };

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role.name,
        'display_label': displayLabel,
        if (profileTagCode != null) 'profile_tag_code': profileTagCode,
      };

  factory RentalGroupMember.fromJson(Map<String, dynamic> j) {
    return RentalGroupMember(
      userId: j['user_id']?.toString() ?? '',
      role: RentalMemberRole.values.firstWhere(
        (r) => r.name == j['role']?.toString(),
        orElse: () => RentalMemberRole.tenant,
      ),
      displayLabel: j['display_label']?.toString() ?? '',
      profileTagCode: j['profile_tag_code']?.toString(),
    );
  }
}
