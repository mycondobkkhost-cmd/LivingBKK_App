/// ช่องกล่องแชทในศูนย์แอดมิน
enum AdminInboxBucket {
  /// รอรับงาน — ยังไม่มีผู้รับผิดชอบ
  unclaimed,

  /// งานของฉัน — รับแล้วและรอตอบ
  mine,

  /// ปิดแล้ว — ตอบครบ / ปิดเคส
  resolved,
}

class AdminPeer {
  const AdminPeer({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// ลูกค้าเดิมมีแอดมินดูแลอยู่ในแชทอื่น — แจ้งก่อนรับงานห้องใหม่
class CustomerAdminContinuityHint {
  const CustomerAdminContinuityHint({
    required this.participantUserId,
    required this.adminId,
    required this.adminName,
    required this.otherRoomId,
    required this.otherRoomTitle,
  });

  final String participantUserId;
  final String adminId;
  final String adminName;
  final String otherRoomId;
  final String otherRoomTitle;
}
