/// รายการ audit log สำหรับ Governance / รายงาน
class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.entityId,
    this.actorName,
    this.payload = const {},
  });

  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? actorName;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
}
