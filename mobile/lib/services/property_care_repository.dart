import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../data/admin_demo_data.dart';
import '../models/property_care_owner_data_input.dart';
import '../models/property_care_right.dart';
import '../models/property_care_summary.dart';
import '../models/trial_persona.dart';
import '../utils/demo_inventory_resolve.dart';
import 'auth_service.dart';
import 'demo_cast_bootstrap.dart';
import 'local_prefs_service.dart';
import 'property_care_notification_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';

class PropertyCareRepository extends ChangeNotifier {
  PropertyCareRepository._();
  static final PropertyCareRepository instance = PropertyCareRepository._();
  factory PropertyCareRepository() => instance;

  static const demoOwnerUserId = '11111111-1111-1111-1111-111111111111';
  static const _prefsKey = 'property_care_demo_rights_v1';
  static bool _hydrated = false;

  static List<PropertyCareRight> _seedRights() => [
        PropertyCareRight(
          id: 'demo-care-1',
          inventoryId: 'demo-inv-1',
          inventoryCode: 'RXT-2026-000201',
          userId: '22222222-2222-2222-2222-222222222222',
          careRole: 'team_steward',
          status: 'active',
          isPrimary: true,
          version: 1,
          userDisplayName: 'ทีม RealXtate',
          notes: 'ลงทรัพย์ให้ก่อนเจ้าของสมัคร',
        ),
        PropertyCareRight(
          id: 'demo-care-2',
          inventoryId: 'demo-inv-1',
          inventoryCode: 'RXT-2026-000201',
          userId: demoOwnerUserId,
          careRole: 'primary_caretaker',
          status: 'pending_claim',
          isPrimary: false,
          version: 1,
          userDisplayName: 'เจ้าของทรัพย์ (ทดลอง)',
          inviteCode: 'RX-000201',
          notes: 'รอเจ้าของกดรับสิทธิ์',
        ),
      ];

  static final List<PropertyCareRight> _demo = List<PropertyCareRight>.from(
    PropertyCareRepository._seedRights(),
  );

  static final Set<String> _demoListingOwnerComplete = {};
  static final Map<String, Map<String, dynamic>> _demoListingFieldOverrides = {};

  static String _listingPendingKey(String inventoryId, String listingCode) =>
      '$inventoryId:$listingCode';

  static bool _demoListingNeedsOwnerData(String inventoryId, String listingCode) {
    return !_demoListingOwnerComplete.contains(
      _listingPendingKey(inventoryId, listingCode),
    );
  }

  /// ข้อมูลประกาศล่าสุดจากเจ้าของ — ใช้ sync หน้าบ้าน ↔ หลังบ้าน (โหมดทดลอง)
  static Map<String, dynamic>? listingSnapshotForAdmin({
    required String listingCode,
    String? inventoryId,
    String? inventoryCode,
  }) {
    final id = inventoryId == null
        ? null
        : resolveDemoInventoryId(inventoryId, inventoryCode: inventoryCode);
    final trial = TrialListingStore.instance.rowByCode(listingCode);
    final overlay = id == null
        ? null
        : _demoListingFieldOverrides[_listingPendingKey(id, listingCode)];
    if (trial == null && overlay == null) return null;

    final merged = <String, dynamic>{
      if (trial != null) ...trial,
      if (overlay != null) ...overlay,
    };
    if (id != null) {
      final needs = _demoListingNeedsOwnerData(id, listingCode);
      merged['owner_data_pending'] = needs;
      merged['owner_data_status'] = needs ? 'pending' : 'complete';
      merged['owner_data_complete'] = !needs;
    }
    return merged;
  }

  /// รวมข้อมูลเจ้าของเข้ากับสมาชิกทะเบียน RXT สำหรับแอดมิน
  static Map<String, dynamic> enrichInventoryMember(
    Map<String, dynamic> member, {
    required String inventoryId,
    String? inventoryCode,
  }) {
    final code = member['listing_code']?.toString();
    if (code == null || code.isEmpty) return member;
    final snap = listingSnapshotForAdmin(
      listingCode: code,
      inventoryId: inventoryId,
      inventoryCode: inventoryCode,
    );
    if (snap == null) return member;
    return {
      ...member,
      if (snap['title'] != null) 'title': snap['title'],
      if (snap['title_owner'] != null) 'title_owner': snap['title_owner'],
      if (snap['title_display'] != null) 'title_display': snap['title_display'],
      if (snap['price_net'] != null) 'price_net': snap['price_net'],
      if (snap['description_owner'] != null)
        'description_owner': snap['description_owner'],
      if (snap['description'] != null) 'description': snap['description'],
      if (snap['description_display'] != null)
        'description_display': snap['description_display'],
      if (snap['bedrooms'] != null) 'bedrooms': snap['bedrooms'],
      if (snap['bathrooms'] != null) 'bathrooms': snap['bathrooms'],
      if (snap['area_sqm'] != null) 'area_sqm': snap['area_sqm'],
      if (snap['occupancy_status'] != null)
        'occupancy_status': snap['occupancy_status'],
      if (snap['pet_policy'] != null) 'pet_policy': snap['pet_policy'],
      if (snap['viewing_access'] != null) 'viewing_access': snap['viewing_access'],
      'owner_data_status': snap['owner_data_status'],
      'owner_data_complete': snap['owner_data_complete'] == true,
      'display_contact_clean': snap['display_contact_clean'] != false,
    };
  }

  static int _demoPendingData(String inventoryId) {
    var n = 0;
    for (final m in AdminDemoData.inventoryMembers(inventoryId)) {
      if (m['status']?.toString() != 'published') continue;
      final code = m['listing_code']?.toString();
      if (code == null || code.isEmpty) continue;
      final trial = TrialListingStore.instance.rowByCode(code);
      if (trial != null) {
        if (trial['owner_data_complete'] == true ||
            trial['owner_data_status']?.toString() == 'complete') {
          continue;
        }
        // ส่งครบแล้ว รอทีมตรวจ — ไม่นับเป็นงานค้างของเจ้าของ
        if (trial['status']?.toString() == 'pending_review') continue;
      }
      if (_demoListingNeedsOwnerData(inventoryId, code)) n++;
    }
    return n;
  }

  /// โหมดทดลองใน memory — บัญชีทดลอง / demo-admin+ตัวละคร / ยังไม่มีตารางบน Supabase
  bool get _useDemo =>
      !Env.isConfigured ||
      !SupabaseService.isReady ||
      AuthService.instance.trialSimulatesBackend ||
      AuthService.instance.isTrialSignedIn ||
      DemoCastBootstrap.shouldUseCastWorld;

  static bool _isDemoId(String? id) =>
      id != null && (id.startsWith('demo-') || id.startsWith('demo_'));

  String? get _currentUserId => AuthService.instance.effectiveUserId;

  PropertyCareRight _normalizeStored(PropertyCareRight r) {
    final inv = r.inventoryId;
    if (inv == null) return r;
    final resolved = resolveDemoInventoryId(
      inv,
      inventoryCode: r.inventoryCode,
    );
    if (resolved == inv) return r;
    return PropertyCareRight(
      id: r.id,
      listingId: r.listingId,
      inventoryId: resolved,
      inventoryCode: r.inventoryCode,
      listingCode: r.listingCode,
      userId: r.userId,
      careRole: r.careRole,
      status: r.status,
      isPrimary: r.isPrimary,
      grantedBy: r.grantedBy,
      grantedAt: r.grantedAt,
      inviteCode: r.inviteCode,
      notes: r.notes,
      userDisplayName: r.userDisplayName,
      version: r.version,
    );
  }

  Future<void> _ensureHydrated() async {
    if (_hydrated) return;
    _hydrated = true;
    await LocalPrefsService.instance.init();
    final raw = await LocalPrefsService.instance.getJsonList(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final merged = <String, PropertyCareRight>{
      for (final s in _seedRights()) s.id: s,
    };
    for (final e in raw) {
      final row = _normalizeStored(
        PropertyCareRight.fromJson(Map<String, dynamic>.from(e as Map)),
      );
      if (row.id.isEmpty || row.userId.isEmpty) continue;
      merged[row.id] = row;
    }
    _demo
      ..clear()
      ..addAll(merged.values);
  }

  Future<void> _persistDemo() async {
    if (!_useDemo) return;
    await LocalPrefsService.instance.init();
    await LocalPrefsService.instance.setJsonList(
      _prefsKey,
      _demo.map((r) => r.toJson()).toList(),
    );
  }

  void _mutated({String? notifyUserId, String? notifyInventoryCode}) {
    notifyListeners();
    unawaited(_persistDemo());
    if (notifyUserId != null && notifyInventoryCode != null) {
      unawaited(
        PropertyCareNotificationService.instance.onGrantToUser(
          userId: notifyUserId,
          inventoryCode: notifyInventoryCode,
          isEnglish: false,
        ),
      );
    } else {
      unawaited(PropertyCareNotificationService.instance.sync(isEnglish: false));
    }
  }

  String _resolvedInventoryId(String inventoryId, {String? inventoryCode}) =>
      resolveDemoInventoryId(inventoryId, inventoryCode: inventoryCode);

  List<PropertyCareRight> _demoForInventory(
    String inventoryId, {
    String? inventoryCode,
  }) {
    final code = inventoryCode?.trim().toUpperCase();
    return _demo
        .where((r) {
          if (r.status == 'revoked') return false;
          if (r.inventoryId == inventoryId) return true;
          if (code != null &&
              code.isNotEmpty &&
              r.inventoryCode?.trim().toUpperCase() == code) {
            return true;
          }
          return false;
        })
        .toList();
  }

  String? _displayNameForUser(String userId) {
    if (userId == demoOwnerUserId) return 'เจ้าของทรัพย์ (ทดลอง)';
    for (final p in TrialPersona.personas) {
      if (p.userId == userId) return p.displayName;
    }
    return null;
  }

  Future<List<PropertyCareRight>> forInventory(
    String inventoryId, {
    String? inventoryCode,
  }) async {
    await _ensureHydrated();
    final id = _resolvedInventoryId(inventoryId, inventoryCode: inventoryCode);
    if (_isDemoId(id) || _useDemo) {
      return _demoForInventory(id, inventoryCode: inventoryCode);
    }
    try {
      final rows = await SupabaseService.client!
          .from('property_care_rights')
          .select('*, profiles(display_name)')
          .eq('inventory_id', id)
          .neq('status', 'revoked')
          .order('is_primary', ascending: false);
      return (rows as List)
          .map((r) => PropertyCareRight.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      if (!AdminDemoData.enabled) rethrow;
      return _demoForInventory(id, inventoryCode: inventoryCode);
    }
  }

  List<PropertyCareRight> _dedupeRights(List<PropertyCareRight> rights) {
    final byKey = <String, PropertyCareRight>{};
    for (final r in rights) {
      final key = '${r.inventoryId ?? ''}|${r.inventoryCode ?? ''}|${r.careRole}';
      final prev = byKey[key];
      if (prev == null) {
        byKey[key] = r;
        continue;
      }
      final prevAt = prev.grantedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final at = r.grantedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (!at.isBefore(prevAt)) byKey[key] = r;
    }
    return byKey.values.toList();
  }

  Future<List<PropertyCareRight>> forCurrentUser() async {
    await _ensureHydrated();
    final uid = _currentUserId;
    if (uid == null) return [];
    if (_useDemo) {
      return _dedupeRights(
        _demo.where((r) => r.userId == uid && r.status != 'revoked').toList(),
      );
    }
    try {
      final rows = await SupabaseService.client!
          .from('property_care_rights')
          .select('*, property_inventory(inventory_code, canonical_title, district, member_count)')
          .eq('user_id', uid)
          .inFilter('status', ['active', 'pending_claim'])
          .order('granted_at', ascending: false);
      return (rows as List)
          .map((r) => PropertyCareRight.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      if (!AdminDemoData.enabled) rethrow;
      return _dedupeRights(
        _demo.where((r) => r.userId == uid && r.status != 'revoked').toList(),
      );
    }
  }

  Future<List<PropertyCareSummary>> summariesForCurrentUser() async {
    final rights = await forCurrentUser();
    final out = <PropertyCareSummary>[];
    for (final r in rights) {
      final invId = r.inventoryId ??
          AdminDemoData.inventoryIdForCode(r.inventoryCode);
      if (invId == null) continue;
      out.add(await _summaryFor(r, inventoryId: invId));
    }
    return out;
  }

  /// ประกาศภายใต้ทะเบียนที่มอบให้ดูแล — สำหรับหน้าจัดการทรัพย์
  Future<List<Map<String, dynamic>>> listingsForSummary(
    PropertyCareSummary summary,
  ) async {
    final invId = summary.right.inventoryId ??
        AdminDemoData.inventoryIdForCode(summary.inventoryCode);
    if (invId == null) return [];

    if (_useDemo || invId.startsWith('demo-')) {
      var members = AdminDemoData.inventoryMembers(invId);
      // หน้าของฉัน — แสดงประกาศหลักของเจ้าของเท่านั้น (1 การ์ดต่อทรัพย์)
      final primaryCode = summary.primaryListingCode;
      members = members.where((m) {
        if (m['listed_by_role']?.toString() == 'owner_direct') return true;
        if (primaryCode != null &&
            m['listing_code']?.toString() == primaryCode) {
          return true;
        }
        return false;
      }).toList();
      final trialRows = AuthService.instance.isTrialSignedIn
          ? TrialListingStore.instance.myListings()
          : const <Map<String, dynamic>>[];
      final out = <Map<String, dynamic>>[];
      final seenCodes = <String>{};
      for (final m in members) {
        final code = m['listing_code']?.toString() ?? '';
        if (code.isEmpty || seenCodes.contains(code)) continue;
        seenCodes.add(code);
        final trial = trialRows.cast<Map<String, dynamic>?>().firstWhere(
              (r) => r?['listing_code']?.toString() == code,
              orElse: () => null,
            );
        final needsData = summary.right.status == 'active' &&
            _demoListingNeedsOwnerData(invId, code);
        final trialRow = trial ?? TrialListingStore.instance.rowByCode(code);
        final overlay = _demoListingFieldOverrides[_listingPendingKey(invId, code)];
        if (trialRow != null) {
          out.add({
            ...trialRow,
            if (overlay != null) ...overlay,
            'owner_data_pending': needsData,
            'owner_data_complete': !needsData,
          });
        } else {
          out.add({
            'id': m['listing_id']?.toString() ?? 'demo-listing-$code',
            'listing_code': code,
            'title': summary.canonicalTitle ?? code,
            'status': m['status']?.toString() ?? 'published',
            'listing_type': code.startsWith('SALE') ? 'sale' : 'rent',
            'property_type': 'condo',
            'price_net': m['price_net'],
            'district': summary.district,
            'last_bump_at': DateTime.now().toUtc().toIso8601String(),
            'published_at': DateTime.now().toUtc().toIso8601String(),
            'expires_at': DateTime.now()
                .add(const Duration(days: 22))
                .toUtc()
                .toIso8601String(),
            'cover_image_url':
                'https://picsum.photos/seed/${Uri.encodeComponent(code)}/240/180',
            if (overlay != null) ...overlay,
            'owner_data_pending': needsData,
            'owner_data_complete': !needsData,
          });
        }
      }
      return out;
    }

    final rows = await SupabaseService.client!
        .from('listings')
        .select(
          'id, listing_code, title, status, listing_type, price_net, '
          'last_bump_at, published_at, expires_at, available_again, '
          'closed_at, closed_reason, reuse_blocked, owner_data_status, viewing_access',
        )
        .eq('inventory_id', invId)
        .neq('status', 'hidden')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<bool> submitListingOwnerData({
    required String inventoryId,
    required String listingId,
    required String listingCode,
    required String listingType,
    required String propertyType,
    required PropertyCareOwnerDataInput input,
    String? inventoryCode,
    bool isEnglish = false,
    bool titleChanged = false,
    String? currentStatus,
  }) async {
    await _ensureHydrated();
    final id = _resolvedInventoryId(inventoryId, inventoryCode: inventoryCode);
    final fields = input.toListingFields(
      listingType: listingType,
      isEnglish: isEnglish,
      titleChanged: titleChanged,
    );
    fields['property_type'] = propertyType;
    if (titleChanged) {
      fields['status'] = 'pending_review';
      fields['title_review_pending'] = true;
    } else if (currentStatus != null && currentStatus.isNotEmpty) {
      fields['status'] = currentStatus;
    }

    if (_useDemo || id.startsWith('demo-')) {
      _saveDemoListingFields(
        inventoryId: id,
        listingId: listingId,
        listingCode: listingCode,
        fields: fields,
      );
      await completeListingOwnerData(
        inventoryId: id,
        listingCode: listingCode,
        inventoryCode: inventoryCode,
      );
      return titleChanged;
    }

    await SupabaseService.client!
        .from('listings')
        .update({
          ...fields,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', listingId)
        .eq('inventory_id', id)
        .eq('listing_code', listingCode);

    await completeListingOwnerData(
      inventoryId: id,
      listingCode: listingCode,
      inventoryCode: inventoryCode,
    );
    return titleChanged;
  }

  static bool _saveDemoListingFields({
    required String inventoryId,
    required String listingId,
    required String listingCode,
    required Map<String, dynamic> fields,
  }) {
    final store = TrialListingStore.instance;
    if (store.updateOwnerListingFields(listingId, fields)) return true;
    if (store.updateOwnerListingFieldsByCode(listingCode, fields)) return true;
    _demoListingFieldOverrides[_listingPendingKey(inventoryId, listingCode)] =
        Map<String, dynamic>.from(fields);
    return true;
  }

  Future<void> completeListingOwnerData({
    required String inventoryId,
    required String listingCode,
    String? inventoryCode,
  }) async {
    await _ensureHydrated();
    final id = _resolvedInventoryId(inventoryId, inventoryCode: inventoryCode);
    if (_useDemo || id.startsWith('demo-')) {
      _demoListingOwnerComplete.add(_listingPendingKey(id, listingCode));
      final key = _listingPendingKey(id, listingCode);
      final overlay = _demoListingFieldOverrides[key];
      if (overlay != null) {
        _demoListingFieldOverrides[key] = {
          ...overlay,
          'owner_data_complete': true,
          'owner_data_status': 'complete',
        };
      }
      TrialListingStore.instance.updateOwnerListingFieldsByCode(listingCode, {
        'owner_data_complete': true,
        'owner_data_status': 'complete',
      });
      _mutated();
      return;
    }
    await SupabaseService.client!
        .from('listings')
        .update({'owner_data_status': 'complete'})
        .eq('inventory_id', id)
        .eq('listing_code', listingCode);
    _mutated();
  }

  Future<PropertyCareSummary> _summaryFor(
    PropertyCareRight right, {
    String? inventoryId,
  }) async {
    final invId = inventoryId ??
        right.inventoryId ??
        AdminDemoData.inventoryIdForCode(right.inventoryCode);
    if (invId == null) {
      return PropertyCareSummary(right: right, inventoryCode: right.inventoryCode);
    }
    if (_useDemo || invId.startsWith('demo-')) {
      final roster = AdminDemoData.inventoryRoster();
      final inv = roster.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m?['id'] == invId,
            orElse: () => null,
          );
      final pending = right.status == 'active' ? _demoPendingData(invId) : 0;
      return PropertyCareSummary(
        right: right,
        inventoryCode: right.inventoryCode ?? inv?['inventory_code']?.toString(),
        canonicalTitle: inv?['canonical_title']?.toString(),
        district: inv?['district']?.toString(),
        memberCount: (inv?['member_count'] as num?)?.toInt(),
        pendingDataCount: pending,
        primaryListingCode: inv?['primary_listing_code']?.toString(),
      );
    }

    final inv = await SupabaseService.client!
        .from('property_inventory')
        .select('inventory_code, canonical_title, district, member_count, primary_listing_code')
        .eq('id', invId)
        .maybeSingle();

    final pendingRows = await SupabaseService.client!
        .from('listings')
        .select('id')
        .eq('inventory_id', invId)
        .eq('owner_data_status', 'pending')
        .eq('status', 'published');

    return PropertyCareSummary(
      right: right,
      inventoryCode: inv?['inventory_code']?.toString() ?? right.inventoryCode,
      canonicalTitle: inv?['canonical_title']?.toString(),
      district: inv?['district']?.toString(),
      memberCount: (inv?['member_count'] as num?)?.toInt(),
      pendingDataCount: (pendingRows as List).length,
      primaryListingCode: inv?['primary_listing_code']?.toString(),
    );
  }

  Future<PropertyCareRight> grant({
    required String userId,
    required String careRole,
    String? listingId,
    String? inventoryId,
    String? inventoryCode,
    String? listingCode,
    bool isPrimary = false,
    String? notes,
    String? inviteCode,
    String status = 'active',
  }) async {
    await _ensureHydrated();
    final resolvedInv = inventoryId == null
        ? null
        : _resolvedInventoryId(inventoryId, inventoryCode: inventoryCode);
    if (_useDemo || _isDemoId(resolvedInv) || _isDemoId(listingId)) {
      return _grantDemo(
        userId: userId,
        careRole: careRole,
        listingId: listingId,
        inventoryId: resolvedInv,
        inventoryCode: inventoryCode,
        listingCode: listingCode,
        isPrimary: isPrimary,
        notes: notes,
        inviteCode: inviteCode,
        status: status,
      );
    }

    final row = await SupabaseService.client!.rpc(
      'grant_property_care_right',
      params: {
        'p_user_id': userId,
        'p_care_role': careRole,
        'p_inventory_id': resolvedInv,
        'p_listing_id': listingId,
        'p_is_primary': isPrimary,
        'p_status': status,
        'p_notes': notes,
        'p_invite_code': inviteCode,
      },
    );
    return PropertyCareRight.fromJson(Map<String, dynamic>.from(row as Map));
  }

  PropertyCareRight _grantDemo({
    required String userId,
    required String careRole,
    String? listingId,
    String? inventoryId,
    String? inventoryCode,
    String? listingCode,
    bool isPrimary = false,
    String? notes,
    String? inviteCode,
    String status = 'active',
  }) {
    final actor = AuthService.instance.effectiveUserId;
    if (inventoryId != null) {
      final dup = _demo.indexWhere(
        (r) =>
            r.userId == userId &&
            r.inventoryId == inventoryId &&
            r.careRole == careRole &&
            r.status != 'revoked',
      );
      if (dup >= 0) {
        final o = _demo[dup];
        final updated = PropertyCareRight(
          id: o.id,
          listingId: listingId ?? o.listingId,
          inventoryId: inventoryId,
          inventoryCode: inventoryCode ?? o.inventoryCode,
          listingCode: listingCode ?? o.listingCode,
          userId: userId,
          careRole: careRole,
          status: status,
          isPrimary: isPrimary,
          grantedBy: actor,
          grantedAt: DateTime.now(),
          inviteCode: inviteCode ?? o.inviteCode,
          notes: notes ?? o.notes,
          userDisplayName: _displayNameForUser(userId) ?? o.userDisplayName,
          version: o.version + 1,
        );
        _demo[dup] = updated;
        _mutated(
          notifyUserId: status == 'pending_claim' ? userId : null,
          notifyInventoryCode:
              status == 'pending_claim' ? (inventoryCode ?? '') : null,
        );
        return updated;
      }
    }
    final id = 'demo-care-${DateTime.now().millisecondsSinceEpoch}';
    if (isPrimary && inventoryId != null) {
      for (var i = 0; i < _demo.length; i++) {
        if (_demo[i].inventoryId == inventoryId && _demo[i].isPrimary) {
          final o = _demo[i];
          _demo[i] = PropertyCareRight(
            id: o.id,
            listingId: o.listingId,
            inventoryId: o.inventoryId,
            inventoryCode: o.inventoryCode,
            listingCode: o.listingCode,
            userId: o.userId,
            careRole: o.careRole,
            status: o.status,
            isPrimary: false,
            grantedBy: o.grantedBy,
            grantedAt: o.grantedAt,
            inviteCode: o.inviteCode,
            notes: o.notes,
            userDisplayName: o.userDisplayName,
            version: o.version,
          );
        }
      }
    }
    final row = PropertyCareRight(
      id: id,
      listingId: listingId,
      inventoryId: inventoryId,
      inventoryCode: inventoryCode,
      listingCode: listingCode,
      userId: userId,
      careRole: careRole,
      status: status,
      isPrimary: isPrimary,
      grantedBy: actor,
      grantedAt: DateTime.now(),
      inviteCode: inviteCode,
      notes: notes,
      userDisplayName: _displayNameForUser(userId),
      version: 1,
    );
    _demo.insert(0, row);
    _mutated(
      notifyUserId: status == 'pending_claim' ? userId : null,
      notifyInventoryCode:
          status == 'pending_claim' ? (inventoryCode ?? '') : null,
    );
    return row;
  }

  Future<PropertyCareRight> acceptClaim(String rightId) async {
    if (_useDemo || rightId.startsWith('demo-')) {
      final i = _demo.indexWhere((r) => r.id == rightId);
      if (i < 0) throw Exception('ไม่พบสิทธิ์');
      final o = _demo[i];
      if (o.status != 'pending_claim') throw Exception('ไม่ใช่สถานะรอรับสิทธิ์');
      final updated = PropertyCareRight(
        id: o.id,
        listingId: o.listingId,
        inventoryId: o.inventoryId,
        inventoryCode: o.inventoryCode,
        listingCode: o.listingCode,
        userId: o.userId,
        careRole: o.careRole,
        status: 'active',
        isPrimary: o.careRole == 'primary_caretaker' ? true : o.isPrimary,
        grantedBy: o.grantedBy,
        grantedAt: o.grantedAt,
        inviteCode: o.inviteCode,
        notes: o.notes,
        userDisplayName: o.userDisplayName,
        version: o.version + 1,
      );
      _demo[i] = updated;
      final invId = updated.inventoryId;
      if (invId != null) {
        for (final m in AdminDemoData.inventoryMembers(invId)) {
          final code = m['listing_code']?.toString();
          if (code == null || code.isEmpty) continue;
          _demoListingOwnerComplete.remove(_listingPendingKey(invId, code));
        }
      }
      _mutated();
      return updated;
    }

    final row = await SupabaseService.client!.rpc(
      'accept_property_care_right',
      params: {'p_right_id': rightId},
    );
    return PropertyCareRight.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<int> completeOwnerData(String inventoryId, {String? inventoryCode}) async {
    await _ensureHydrated();
    final id = _resolvedInventoryId(inventoryId, inventoryCode: inventoryCode);
    if (_useDemo || id.startsWith('demo-')) {
      final members = AdminDemoData.inventoryMembers(id);
      var n = 0;
      for (final m in members) {
        final code = m['listing_code']?.toString();
        if (code == null || code.isEmpty) continue;
        if (m['status']?.toString() != 'published') continue;
        if (_demoListingNeedsOwnerData(id, code)) {
          _demoListingOwnerComplete.add(_listingPendingKey(id, code));
          n++;
        }
      }
      _mutated();
      return n;
    }
    final count = await SupabaseService.client!.rpc(
      'complete_property_owner_data',
      params: {'p_inventory_id': id},
    );
    return (count as num?)?.toInt() ?? 0;
  }

  Future<void> revoke(String rightId) async {
    await _ensureHydrated();
    if (_useDemo || rightId.startsWith('demo-')) {
      final i = _demo.indexWhere((r) => r.id == rightId);
      if (i >= 0) {
        final o = _demo[i];
        _demo[i] = PropertyCareRight(
          id: o.id,
          listingId: o.listingId,
          inventoryId: o.inventoryId,
          inventoryCode: o.inventoryCode,
          listingCode: o.listingCode,
          userId: o.userId,
          careRole: o.careRole,
          status: 'revoked',
          isPrimary: false,
          grantedBy: o.grantedBy,
          grantedAt: o.grantedAt,
          inviteCode: o.inviteCode,
          notes: o.notes,
          userDisplayName: o.userDisplayName,
          version: o.version + 1,
        );
        _mutated();
      }
      return;
    }
    await SupabaseService.client!.rpc(
      'revoke_property_care_right',
      params: {'p_right_id': rightId},
    );
  }

  /// มอบหลังเจ้าของแจ้งรหัสทะเบียน RXT
  Future<PropertyCareRight> claimByUserId({
    required String userId,
    required String inventoryCode,
    String careRole = 'primary_caretaker',
  }) async {
    final code = inventoryCode.trim().toUpperCase();
    if (_useDemo) {
      final inv = _demo.firstWhere(
        (r) => r.inventoryCode?.toUpperCase() == code,
        orElse: () => _demo.first,
      );
      return grant(
        userId: userId,
        careRole: careRole,
        inventoryId: inv.inventoryId,
        inventoryCode: code,
        isPrimary: true,
        status: 'active',
        notes: 'รับสิทธิ์ดูแลหลังสมัคร',
      );
    }

    final inv = await SupabaseService.client!
        .from('property_inventory')
        .select('id, inventory_code')
        .eq('inventory_code', code)
        .maybeSingle();
    if (inv == null) {
      throw Exception('ไม่พบทะเบียน $code');
    }
    return grant(
      userId: userId,
      careRole: careRole,
      inventoryId: inv['id'] as String,
      inventoryCode: inv['inventory_code'] as String?,
      isPrimary: true,
      status: 'active',
      notes: 'รับสิทธิ์ดูแลหลังสมัคร',
    );
  }

  /// Bootstrap demo: เจ้าของทดลองมีสิทธิ์รอรับ
  static Future<void> ensureDemoForTrialOwner() async {
    if (!AuthService.instance.isTrialSignedIn) return;
    if (AuthService.instance.trialRole != 'owner') return;
    final uid = TrialPersona.byRole('owner')?.userId;
    if (uid == null) return;
    await instance._ensureHydrated();
    final hasRight = _demo.any(
      (r) => r.userId == uid && r.status != 'revoked',
    );
    if (!hasRight) {
      final seed = _seedRights().firstWhere(
        (r) => r.id == 'demo-care-2',
        orElse: () => PropertyCareRight(
          id: 'demo-care-2',
          inventoryId: 'demo-inv-1',
          inventoryCode: 'RXT-2026-000201',
          userId: uid,
          careRole: 'primary_caretaker',
          status: 'pending_claim',
          isPrimary: false,
          version: 1,
          userDisplayName: 'เจ้าของทรัพย์ (ทดลอง)',
          inviteCode: 'RX-000201',
          notes: 'รอเจ้าของกดรับสิทธิ์',
        ),
      );
      _demo.add(
        PropertyCareRight(
          id: seed.id,
          listingId: seed.listingId,
          inventoryId: seed.inventoryId,
          inventoryCode: seed.inventoryCode,
          listingCode: seed.listingCode,
          userId: uid,
          careRole: seed.careRole,
          status: seed.status,
          isPrimary: seed.isPrimary,
          grantedBy: seed.grantedBy,
          grantedAt: seed.grantedAt ?? DateTime.now(),
          inviteCode: seed.inviteCode,
          notes: seed.notes,
          userDisplayName: 'เจ้าของทรัพย์ (ทดลอง)',
          version: seed.version,
        ),
      );
      instance._mutated();
      return;
    }
    final i = _demo.indexWhere((r) => r.id == 'demo-care-2');
    if (i < 0) return;
    final o = _demo[i];
    if (o.userId == uid) return;
    _demo[i] = PropertyCareRight(
      id: o.id,
      listingId: o.listingId,
      inventoryId: o.inventoryId,
      inventoryCode: o.inventoryCode,
      listingCode: o.listingCode,
      userId: uid,
      careRole: o.careRole,
      status: o.status,
      isPrimary: o.isPrimary,
      grantedBy: o.grantedBy,
      grantedAt: o.grantedAt,
      inviteCode: o.inviteCode,
      notes: o.notes,
      userDisplayName: 'เจ้าของทรัพย์ (ทดลอง)',
      version: o.version,
    );
    instance._mutated();
  }
}
