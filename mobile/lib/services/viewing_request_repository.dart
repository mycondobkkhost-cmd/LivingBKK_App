import 'package:flutter/foundation.dart';

import '../models/profile_tag.dart';
import '../models/viewing_request.dart';
import 'auth_service.dart';
import 'profile_tag_repository.dart';
import 'supabase_service.dart';
import 'viewing_request_service.dart';

/// คำขอนัดดู — DB-backed พร้อม fallback in-memory
class ViewingRequestRepository extends ChangeNotifier {
  ViewingRequestRepository._();
  static final ViewingRequestRepository instance = ViewingRequestRepository._();

  bool _loaded = false;
  bool _adminLoaded = false;

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  ViewingRequestService get _demo => ViewingRequestService.instance;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (_live) await _hydrateFromDb();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _hydrateFromDb() async {
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final rows = await SupabaseService.client!
          .from('viewing_requests')
          .select()
          .eq('created_by_user_id', uid)
          .order('created_at', ascending: false)
          .limit(200);

      for (final raw in rows as List) {
        if (raw is! Map) continue;
        final req = _fromRow(Map<String, dynamic>.from(raw));
        if (req != null) _demo.registerDemoRequest(req);
      }
    } catch (_) {}
  }

  Future<ViewingRequest> create({
    required String listingId,
    required String listingCode,
    required String listingTitle,
    String? projectName,
    required DateTime scheduledAt,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required ViewingRequestSource source,
    String? threadId,
    String? createdByUserId,
  }) async {
    await ensureLoaded();
    final uid = createdByUserId ?? AuthService.instance.effectiveUserId ?? 'demo-user';

    if (_live) {
      final created = await _insertDb(
        listingId: listingId,
        listingCode: listingCode,
        listingTitle: listingTitle,
        projectName: projectName,
        scheduledAt: scheduledAt,
        clientTag: clientTag,
        presenterTag: presenterTag,
        source: source,
        threadId: threadId,
        createdByUserId: uid,
      );
      if (created != null) {
        _demo.registerDemoRequest(created);
        notifyListeners();
        return created;
      }
    }

    final req = _demo.create(
      listingId: listingId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      projectName: projectName,
      scheduledAt: scheduledAt,
      clientTag: clientTag,
      presenterTag: presenterTag,
      source: source,
      threadId: threadId,
      createdByUserId: uid,
    );
    notifyListeners();
    return req;
  }

  Future<ViewingRequest?> _insertDb({
    required String listingId,
    required String listingCode,
    required String listingTitle,
    String? projectName,
    required DateTime scheduledAt,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required ViewingRequestSource source,
    String? threadId,
    required String createdByUserId,
  }) async {
    try {
      final seq = DateTime.now().microsecondsSinceEpoch % 1000000;
      final code = 'VR-2026-${seq.toString().padLeft(6, '0')}';

      final row = await SupabaseService.client!
          .from('viewing_requests')
          .insert({
            'code': code,
            'listing_id': listingId.isNotEmpty ? listingId : null,
            'listing_code': listingCode,
            'listing_title': listingTitle,
            if (projectName != null) 'project_name': projectName,
            'scheduled_at': scheduledAt.toIso8601String(),
            'client_tag_id': clientTag.id.isNotEmpty ? clientTag.id : null,
            'client_tag_code': clientTag.code,
            if (presenterTag != null) ...{
              'presenter_tag_id':
                  presenterTag.id.isNotEmpty ? presenterTag.id : null,
              'presenter_tag_code': presenterTag.code,
            },
            'source': _sourceDb(source),
            'status': 'submitted',
            if (threadId != null) 'thread_id': threadId,
            'created_by_user_id': createdByUserId,
          })
          .select()
          .single();

      return _fromRow(Map<String, dynamic>.from(row as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus({
    required String id,
    required ViewingRequestStatus status,
    String? appointmentId,
    DateTime? scheduledAt,
  }) async {
    if (_live) {
      try {
        await SupabaseService.client!.from('viewing_requests').update({
          'status': _statusDb(status),
          if (appointmentId != null) 'appointment_id': appointmentId,
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toIso8601String(),
        }).eq('id', id);
      } catch (_) {}
    }
    final req = _demo.byId(id);
    if (req != null) {
      _demo.registerDemoRequest(
        req.copyWith(
          status: status,
          appointmentId: appointmentId,
          scheduledAt: scheduledAt,
        ),
      );
      notifyListeners();
    }
  }

  ViewingRequest? byCode(String code) => _demo.byCode(code);

  Future<ViewingRequest?> fetchByCode(String code) async {
    await ensureLoaded();
    final cached = byCode(code);
    if (cached != null) return cached;
    if (!_live) return null;
    try {
      final row = await SupabaseService.client!
          .from('viewing_requests')
          .select()
          .eq('code', code.trim())
          .maybeSingle();
      if (row == null) return null;
      final req = _fromRow(Map<String, dynamic>.from(row as Map));
      if (req != null) _demo.registerDemoRequest(req);
      return req;
    } catch (_) {
      return null;
    }
  }
  ViewingRequest? byThreadId(String threadId) => _demo.byThreadId(threadId);
  ViewingRequest? byId(String id) => _demo.byId(id);
  List<ViewingRequest> all() => _demo.all();
  List<ViewingRequest> forListing(String listingId) => _demo.forListing(listingId);

  /// คำขอนัดของผู้ใช้หนึ่งคน (admin 360° / per-user)
  List<ViewingRequest> forUser(String userId) =>
      _demo.all().where((v) => v.createdByUserId == userId).toList();

  /// โหลดคำขอนัดทั้งหมดสำหรับแอดมิน (RLS: is_admin)
  Future<List<ViewingRequest>> fetchAllForAdmin({bool force = false}) async {
    await ensureLoaded();
    if (_adminLoaded && !force) {
      return _sortedAll();
    }
    if (_live) {
      try {
        final rows = await SupabaseService.client!
            .from('viewing_requests')
            .select()
            .order('scheduled_at', ascending: false)
            .limit(500);
        for (final raw in rows as List) {
          if (raw is! Map) continue;
          final req = _fromRow(Map<String, dynamic>.from(raw));
          if (req != null) _demo.registerDemoRequest(req);
        }
      } catch (_) {}
    }
    _adminLoaded = true;
    notifyListeners();
    return _sortedAll();
  }

  List<ViewingRequest> _sortedAll() {
    final list = _demo.all().toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return list;
  }

  /// คำขอนัดที่รอเจ้าของตอบ (sent_to_owner) ตาม listing ids
  List<ViewingRequest> pendingForOwnerListings(Set<String> listingIds) =>
      _demo.all().where((v) {
        if (!listingIds.contains(v.listingId)) return false;
        return v.status == ViewingRequestStatus.sentToOwner;
      }).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<ViewingRequest> forListingOwner(String listingId) => _demo
      .all()
      .where((v) => v.listingId == listingId)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  ViewingRequest? _fromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final sourceRaw = row['source']?.toString() ?? 'customer';
    final source = ViewingRequestSource.values.firstWhere(
      (s) => _sourceDb(s) == sourceRaw,
      orElse: () => ViewingRequestSource.customer,
    );
    final statusRaw = row['status']?.toString() ?? 'submitted';
    final status = ViewingRequestStatus.values.firstWhere(
      (s) => _statusDb(s) == statusRaw,
      orElse: () => ViewingRequestStatus.submitted,
    );

    return ViewingRequest(
      id: id,
      code: row['code']?.toString() ?? '',
      listingId: row['listing_id']?.toString() ?? '',
      listingCode: row['listing_code']?.toString() ?? '',
      listingTitle: row['listing_title']?.toString() ?? '',
      projectName: row['project_name']?.toString(),
      scheduledAt: DateTime.tryParse(row['scheduled_at']?.toString() ?? '') ??
          DateTime.now(),
      clientTagId: row['client_tag_id']?.toString() ?? '',
      clientTagCode: row['client_tag_code']?.toString() ?? '',
      presenterTagId: row['presenter_tag_id']?.toString(),
      presenterTagCode: row['presenter_tag_code']?.toString(),
      source: source,
      status: status,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      createdByUserId: row['created_by_user_id']?.toString() ?? '',
      threadId: row['thread_id']?.toString(),
      appointmentId: row['appointment_id']?.toString(),
    );
  }

  String _sourceDb(ViewingRequestSource s) => switch (s) {
        ViewingRequestSource.customer => 'customer',
        ViewingRequestSource.coAgent => 'co_agent',
        ViewingRequestSource.adminPhone => 'admin_phone',
      };

  String _statusDb(ViewingRequestStatus s) => switch (s) {
        ViewingRequestStatus.draft => 'draft',
        ViewingRequestStatus.submitted => 'submitted',
        ViewingRequestStatus.sentToOwner => 'sent_to_owner',
        ViewingRequestStatus.ownerConfirmed => 'owner_confirmed',
        ViewingRequestStatus.ownerDeclined => 'owner_declined',
        ViewingRequestStatus.cancelled => 'cancelled',
      };

  /// โหลดแท็กจาก DB ตาม code (admin / cross-profile)
  Future<ProfileTag?> fetchTagByCode(String code) =>
      ProfileTagRepository.instance.fetchTagByCode(code);
}
