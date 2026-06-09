/// ตัวละครจำลอง — สลับภายในหลังบ้านหลังล็อกอิน demo-admin
enum DemoCastKind {
  ceo,
  sup,
  lead,
  admin,
  guide,
  seeker,
  broker,
  owner,
  ;

  bool get isBackOfficeStaff =>
      this == ceo || this == sup || this == lead || this == admin || this == guide;

  String? get adminTier => switch (this) {
        DemoCastKind.ceo => 'ceo',
        DemoCastKind.sup => 'super',
        DemoCastKind.lead => 'lead',
        DemoCastKind.admin => 'admin',
        _ => null,
      };

  String labelTh(bool isEn) {
    if (isEn) return labelEn;
    return switch (this) {
      DemoCastKind.ceo => 'CEO',
      DemoCastKind.sup => 'SUP',
      DemoCastKind.lead => 'Lead',
      DemoCastKind.admin => 'Admin',
      DemoCastKind.guide => 'เอเจ้นพานัด',
      DemoCastKind.seeker => 'ลูกค้า',
      DemoCastKind.broker => 'โคนายหน้า',
      DemoCastKind.owner => 'เจ้าของทรัพย์',
    };
  }

  String get labelEn => switch (this) {
        DemoCastKind.ceo => 'CEO',
        DemoCastKind.sup => 'SUP',
        DemoCastKind.lead => 'Lead',
        DemoCastKind.admin => 'Admin',
        DemoCastKind.guide => 'Viewing guide',
        DemoCastKind.seeker => 'Customer',
        DemoCastKind.broker => 'Broker',
        DemoCastKind.owner => 'Owner',
      };
}

class DemoCastPersona {
  const DemoCastPersona({
    required this.castId,
    required this.password,
    required this.kind,
    required this.displayNameTh,
    required this.displayNameEn,
    required this.profileId,
    this.staffSlug,
    this.phone,
  });

  final String castId;
  final String password;
  final DemoCastKind kind;
  final String displayNameTh;
  final String displayNameEn;
  final String profileId;
  final String? staffSlug;
  final String? phone;

  String displayName(bool isEn) => isEn ? displayNameEn : displayNameTh;

  String get roleLabelTh => kind.labelTh(false);
  String get roleLabelEn => kind.labelEn;
}
