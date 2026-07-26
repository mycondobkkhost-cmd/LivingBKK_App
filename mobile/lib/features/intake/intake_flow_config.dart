/// ประเภทงานที่ใช้ฟอร์มมาตรฐาน
enum IntakeIntent {
  viewing,
  ownerInquiry,
  requirement,
  negotiation,
}

/// ส่วนเสริมที่แต่ละงานต้องการ (นอกจากโปรไฟล์มาตรฐาน)
enum IntakeExtension {
  viewingSchedule,
  inquiryQuestion,
  contractStart,
  lifestyleFields,
}

class IntakeFlowConfig {
  const IntakeFlowConfig({
    required this.intent,
    this.extensions = const [],
    this.allowCoAgent = true,
    this.requireAuth = true,
  });

  final IntakeIntent intent;
  final List<IntakeExtension> extensions;
  final bool allowCoAgent;
  final bool requireAuth;

  bool get showViewingSchedule =>
      extensions.contains(IntakeExtension.viewingSchedule);

  bool get showInquiryQuestion =>
      extensions.contains(IntakeExtension.inquiryQuestion);

  bool get showContractStart =>
      extensions.contains(IntakeExtension.contractStart);

  bool get showLifestyleFields =>
      extensions.contains(IntakeExtension.lifestyleFields);

  static const viewing = IntakeFlowConfig(
    intent: IntakeIntent.viewing,
    extensions: [
      IntakeExtension.contractStart,
      IntakeExtension.viewingSchedule,
      IntakeExtension.lifestyleFields,
    ],
  );

  static const ownerInquiry = IntakeFlowConfig(
    intent: IntakeIntent.ownerInquiry,
    extensions: [
      IntakeExtension.contractStart,
      IntakeExtension.inquiryQuestion,
      IntakeExtension.lifestyleFields,
    ],
  );

  static const requirement = IntakeFlowConfig(
    intent: IntakeIntent.requirement,
    extensions: [
      IntakeExtension.contractStart,
      IntakeExtension.lifestyleFields,
    ],
  );

  /// แอดมินบันทึกนัดจากโทรศัพท์ — ไม่บังคับล็อกอินลูกค้า
  static const adminPhone = IntakeFlowConfig(
    intent: IntakeIntent.viewing,
    extensions: [
      IntakeExtension.contractStart,
      IntakeExtension.viewingSchedule,
      IntakeExtension.lifestyleFields,
    ],
    allowCoAgent: true,
    requireAuth: false,
  );
}

/// ทรัพย์ที่แอดมินเลือกในฟอร์มโทรศัพท์
class AdminIntakeListing {
  const AdminIntakeListing({
    required this.listingId,
    required this.listingCode,
    required this.listingTitle,
    this.projectName,
  });

  final String listingId;
  final String listingCode;
  final String listingTitle;
  final String? projectName;
}
