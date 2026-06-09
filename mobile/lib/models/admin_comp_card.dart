/// โปรไฟล์ย่อย (คอมพ์การ์ด) สมาชิกองค์กร — ผูกแท็ก PR ส่งลูกค้าได้
class AdminCompCard {
  const AdminCompCard({
    required this.memberProfileId,
    required this.castId,
    required this.roleLabelTh,
    required this.roleLabelEn,
    required this.displayNameTh,
    required this.displayNameEn,
    required this.tagId,
    required this.tagCode,
    this.phone,
    this.agencyName = 'RealXtate',
    this.licenseNo,
    this.active = true,
  });

  final String memberProfileId;
  final String castId;
  final String roleLabelTh;
  final String roleLabelEn;
  final String displayNameTh;
  final String displayNameEn;
  final String tagId;
  final String tagCode;
  final String? phone;
  final String agencyName;
  final String? licenseNo;
  final bool active;

  String displayName(bool isEn) => isEn ? displayNameEn : displayNameTh;
  String roleLabel(bool isEn) => isEn ? roleLabelEn : roleLabelTh;

  Map<String, dynamic> toJson() => {
        'member_profile_id': memberProfileId,
        'cast_id': castId,
        'role_label_th': roleLabelTh,
        'role_label_en': roleLabelEn,
        'display_name_th': displayNameTh,
        'display_name_en': displayNameEn,
        'tag_id': tagId,
        'tag_code': tagCode,
        'phone': phone,
        'agency_name': agencyName,
        'license_no': licenseNo,
        'active': active,
      };

  factory AdminCompCard.fromJson(Map<String, dynamic> json) => AdminCompCard(
        memberProfileId: json['member_profile_id'] as String,
        castId: json['cast_id'] as String,
        roleLabelTh: json['role_label_th'] as String? ?? '',
        roleLabelEn: json['role_label_en'] as String? ?? '',
        displayNameTh: json['display_name_th'] as String,
        displayNameEn: json['display_name_en'] as String? ?? json['display_name_th'] as String,
        tagId: json['tag_id'] as String,
        tagCode: json['tag_code'] as String,
        phone: json['phone'] as String?,
        agencyName: json['agency_name'] as String? ?? 'RealXtate',
        licenseNo: json['license_no'] as String?,
        active: json['active'] as bool? ?? true,
      );

  AdminCompCard copyWith({
    String? tagId,
    String? tagCode,
    String? displayNameTh,
    String? displayNameEn,
    String? phone,
    String? agencyName,
    String? licenseNo,
    bool? active,
  }) =>
      AdminCompCard(
        memberProfileId: memberProfileId,
        castId: castId,
        roleLabelTh: roleLabelTh,
        roleLabelEn: roleLabelEn,
        displayNameTh: displayNameTh ?? this.displayNameTh,
        displayNameEn: displayNameEn ?? this.displayNameEn,
        tagId: tagId ?? this.tagId,
        tagCode: tagCode ?? this.tagCode,
        phone: phone ?? this.phone,
        agencyName: agencyName ?? this.agencyName,
        licenseNo: licenseNo ?? this.licenseNo,
        active: active ?? this.active,
      );
}
