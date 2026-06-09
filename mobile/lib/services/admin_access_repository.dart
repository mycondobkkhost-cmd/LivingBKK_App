import '../data/admin_demo_data.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// คำขอเข้าถึงข้อมูลลับ — CRUD ผ่าน Supabase (fallback demo)
class AdminAccessRequest {
  const AdminAccessRequest({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.requestedBy,
    required this.reason,
    required this.scopesRequested,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.entityCode,
    this.scopesApproved,
    this.grantHours,
    this.reviewedBy,
    this.adminNote,
    this.reviewedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String requestedBy;
  final String reason;
  final List<String> scopesRequested;
  final String status;
  final DateTime createdAt;
  final String? requesterName;
  final String? entityCode;
  final List<String>? scopesApproved;
  final int? grantHours;
  final String? reviewedBy;
  final String? adminNote;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';

  factory AdminAccessRequest.fromRow(Map<String, dynamic> row) {
    final requester = row['requester'];
    String? name;
    if (requester is Map) {
      name = requester['display_name']?.toString();
    }
    return AdminAccessRequest(
      id: row['id']?.toString() ?? '',
      entityType: row['entity_type']?.toString() ?? '',
      entityId: row['entity_id']?.toString() ?? '',
      requestedBy: row['requested_by']?.toString() ?? '',
      reason: row['reason']?.toString() ?? '',
      scopesRequested: _stringList(row['scopes_requested']),
      status: row['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      requesterName: name,
      entityCode: row['entity_code']?.toString(),
      scopesApproved: row['scopes_approved'] == null
          ? null
          : _stringList(row['scopes_approved']),
      grantHours: (row['grant_hours'] as num?)?.toInt(),
      reviewedBy: row['reviewed_by']?.toString(),
      adminNote: row['admin_note']?.toString(),
      reviewedAt: row['reviewed_at'] != null
          ? DateTime.tryParse(row['reviewed_at'].toString())
          : null,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }
}

class AdminAccessGrant {
  const AdminAccessGrant({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.granteeId,
    required this.scope,
    required this.grantedBy,
    required this.createdAt,
    this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String granteeId;
  final String scope;
  final String grantedBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  bool get isActive =>
      revokedAt == null &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory AdminAccessGrant.fromRow(Map<String, dynamic> row) {
    return AdminAccessGrant(
      id: row['id']?.toString() ?? '',
      entityType: row['entity_type']?.toString() ?? '',
      entityId: row['entity_id']?.toString() ?? '',
      granteeId: row['grantee_id']?.toString() ?? '',
      scope: row['scope']?.toString() ?? '',
      grantedBy: row['granted_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: row['expires_at'] != null
          ? DateTime.tryParse(row['expires_at'].toString())
          : null,
      revokedAt: row['revoked_at'] != null
          ? DateTime.tryParse(row['revoked_at'].toString())
          : null,
    );
  }
}

class AdminAccessRepository {
  static final AdminAccessRepository instance = AdminAccessRepository._();
  AdminAccessRepository._();

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  Future<List<AdminAccessRequest>> listPending() async {
    if (!_live) return _demoPending();

    try {
      final rows = await SupabaseService.client!
          .from('admin_access_requests')
          .select(
            'id, entity_type, entity_id, requested_by, reason, scopes_requested, '
            'scopes_approved, grant_hours, status, reviewed_by, admin_note, '
            'reviewed_at, created_at, '
            'requester:profiles!admin_access_requests_requested_by_fkey(display_name)',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50);

      final items = (rows as List)
          .whereType<Map>()
          .map((r) => AdminAccessRequest.fromRow(
                Map<String, dynamic>.from(r),
              ))
          .where((r) => r.id.isNotEmpty)
          .toList();

      if (AdminDemoData.useWhenEmpty(items)) return _demoPending();
      return items;
    } catch (_) {
      return _demoPending();
    }
  }

  Future<List<AdminAccessRequest>> listAll({int limit = 50}) async {
    if (!_live) return _demoAll();

    try {
      final rows = await SupabaseService.client!
          .from('admin_access_requests')
          .select(
            'id, entity_type, entity_id, requested_by, reason, scopes_requested, '
            'scopes_approved, grant_hours, status, reviewed_by, admin_note, '
            'reviewed_at, created_at, '
            'requester:profiles!admin_access_requests_requested_by_fkey(display_name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      final items = (rows as List)
          .whereType<Map>()
          .map((r) => AdminAccessRequest.fromRow(
                Map<String, dynamic>.from(r),
              ))
          .toList();

      if (AdminDemoData.useWhenEmpty(items)) return _demoAll();
      return items;
    } catch (_) {
      return _demoAll();
    }
  }

  Future<AdminAccessRequest?> createRequest({
    required String entityType,
    required String entityId,
    required String reason,
    required List<String> scopesRequested,
  }) async {
    if (!_live) return null;

    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      final row = await SupabaseService.client!
          .from('admin_access_requests')
          .insert({
            'entity_type': entityType,
            'entity_id': entityId,
            'requested_by': uid,
            'reason': reason.trim(),
            'scopes_requested': scopesRequested,
          })
          .select()
          .single();

      if (row is! Map) return null;
      return AdminAccessRequest.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<AdminAccessRequest?> reviewRequest({
    required String requestId,
    required String status,
    List<String>? scopesApproved,
    int? grantHours,
    String? adminNote,
  }) async {
    if (!_live) return null;

    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      final row = await SupabaseService.client!
          .from('admin_access_requests')
          .update({
            'status': status,
            if (scopesApproved != null) 'scopes_approved': scopesApproved,
            if (grantHours != null) 'grant_hours': grantHours,
            if (adminNote != null) 'admin_note': adminNote,
            'reviewed_by': uid,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      if (row is! Map) return null;
      return AdminAccessRequest.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<List<AdminAccessGrant>> activeGrantsForUser({String? userId}) async {
    final uid = userId ?? AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return const [];

    if (!_live) return const [];

    try {
      final rows = await SupabaseService.client!
          .from('admin_access_grants')
          .select()
          .eq('grantee_id', uid)
          .isFilter('revoked_at', null)
          .order('created_at', ascending: false);

      return (rows as List)
          .whereType<Map>()
          .map((r) => AdminAccessGrant.fromRow(Map<String, dynamic>.from(r)))
          .where((g) => g.isActive)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<AdminAccessRequest> _demoPending() =>
      _demoAll().where((r) => r.isPending).toList();

  List<AdminAccessRequest> _demoAll() {
    return AdminDemoData.accessRequests().map((row) {
      return AdminAccessRequest(
        id: row['id']?.toString() ?? '',
        entityType: row['entity_type']?.toString() ?? '',
        entityId: row['id']?.toString() ?? '',
        requestedBy: 'demo-admin',
        reason: row['reason']?.toString() ?? '',
        scopesRequested: const ['contact.phone'],
        status: row['status']?.toString() ?? 'pending',
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now(),
        requesterName: row['requester']?.toString(),
        entityCode: row['entity_code']?.toString(),
      );
    }).toList();
  }
}
