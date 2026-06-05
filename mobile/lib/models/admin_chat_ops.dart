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
