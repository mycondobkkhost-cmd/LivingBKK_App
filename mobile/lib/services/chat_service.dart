import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../data/demo_listings_factory.dart';
import '../l10n/app_strings.dart';
import '../models/admin_chat_ops.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/customer_requirement.dart';
import '../models/listing_public.dart';
import '../models/profile_tag.dart';
import 'admin_chat_label_service.dart';
import '../models/viewing_request.dart';
import '../state/locale_controller.dart';
import 'in_app_notification_hub.dart';
import '../utils/listing_ids.dart';
import '../utils/localized_content.dart';
import '../utils/reference_codes.dart';
import '../data/demo_cast_simulation.dart';
import '../data/demo_viewing_record_seed.dart';
import 'auth_service.dart';
import 'demo_cast_bootstrap.dart';
import 'demo_cast_session.dart';
import 'chat_repository.dart';
import 'listing_repository.dart';
import 'supabase_service.dart';
import 'viewing_appointment_record_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._();
  ChatService._();

  final _rooms = <String, ChatRoom>{};
  final _listingRepo = ListingRepository();
  final _repo = ChatRepository();
  List<ListingPublic>? _listingCache;

  AppStrings get _copy => AppStrings(LocaleController.instance?.isEnglish ?? false);

  static const discoveryId = ChatServiceIds.discovery;
  static const staffSupportId = ChatServiceIds.staffSupport;

  bool get _supabaseReady => Env.isConfigured && SupabaseService.isReady;

  bool get _backendActive =>
      _supabaseReady &&
      !AuthService.instance.trialSimulatesBackend &&
      AuthService.instance.isRealSupabaseSession;

  /// โหมดทดลองแยก — inbox จากจำลองเท่านั้น ไม่ดึง Supabase
  bool get _adminInboxBackendActive =>
      !DemoCastBootstrap.isolatedAdminTrial &&
      _supabaseReady &&
      (AuthService.instance.isRealSupabaseSession ||
          AuthService.instance.isTrialAdmin);

  final Set<String> _myThreadIds = {};
  final Map<String, int> _unreadByThread = {};
  /// เวลาที่แอดมินเปิดดูแชทล่าสุด (inbox preview อ่านแล้ว = เทา)
  final Map<String, DateTime> _adminReadAtByThread = {};
  RealtimeChannel? _customerInboxChannel;
  bool _castSimSeeded = false;

  int unreadForThread(String threadId) => _unreadByThread[threadId] ?? 0;

  int get totalUnreadChats =>
      _unreadByThread.values.fold<int>(0, (sum, n) => sum + n);

  void bumpUnread(String threadId, {int by = 1}) {
    if (threadId.isEmpty) return;
    _unreadByThread[threadId] = unreadForThread(threadId) + by;
    notifyListeners();
  }

  void markThreadRead(String threadId) {
    if (_unreadByThread.remove(threadId) != null) {
      notifyListeners();
    }
  }

  /// แอดมินเปิดดูแชท — ข้อความตัวอย่างใน inbox เปลี่ยนเป็นสีเทา
  void markAdminThreadRead(String threadId) {
    if (threadId.isEmpty) return;
    _adminReadAtByThread[threadId] = DateTime.now();
    notifyListeners();
  }

  void refreshRooms() => notifyListeners();

  /// เก็บห้องแชทลูกค้าใน cache หลัง ops (นัดดู / ติดตาม)
  void cacheAdminRoom(ChatRoom room) {
    _registerRoom(room, aliasKey: room.listingCode);
    if (room.listingId.isNotEmpty) {
      _registerRoom(room, aliasKey: room.listingId);
    }
    notifyListeners();
  }

  /// โหลดแชท demo สำหรับ preview แอดมิน
  void ensureDemoAdminChatsForPreview() {
    if (_adminInboxBackendActive) return;
    _memoryEnsureDemoAdminChats();
  }

  /// สร้าง/คืนแชทลูกค้า demo สำหรับ Lead (โหมดทดลอง)
  ChatRoom memoryOpenCustomerRoomForLead({
    required String roomId,
    required String listingCode,
    required String listingTitle,
    String? seekerNickname,
    String? seekerUserId,
  }) {
    final existing = _rooms[roomId];
    if (existing != null) return existing;

    final nick = seekerNickname?.trim().isNotEmpty == true
        ? seekerNickname!.trim()
        : 'ลูกค้าตัวอย่าง';
    final room = ChatRoom(
      id: roomId,
      listingId: roomId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      transactionRef: ReferenceCodes.demoChatRef(roomId),
      roomKind: 'property',
      category: 'viewing_request',
      allowViewingRequest: true,
      participantUserId: seekerUserId ?? 'demo-seeker',
      adminDisplayName: nick,
      viewingSubmitted: true,
      adminEscalated: true,
      adminReplyDone: false,
      status: 'waiting_admin',
      priority: 'high',
      messages: [
        ChatMessage(
          id: 'welcome-$roomId',
          role: ChatMessageRole.ai,
          text: _copy.chatPropertyWelcome(listingTitle, allowViewing: true),
        ),
        ChatMessage(
          id: 'user-viewing-$roomId',
          role: ChatMessageRole.user,
          text: 'สนใจนัดดูทรัพย์นี้ค่ะ ($listingCode)',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ChatMessage(
          id: 'sys-viewing-$roomId',
          role: ChatMessageRole.system,
          text: 'สรุปโปรไฟล์ลูกค้า\n• ชื่อ: $nick\n• ทรัพย์: $listingCode',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
      ],
    );
    _registerRoom(room, aliasKey: listingCode);
    _registerRoom(room, aliasKey: roomId);
    notifyListeners();
    return room;
  }

  /// แชทที่ยังต้องตอบและยังไม่เปิดดูหลังอัปเดตล่าสุด
  bool isAdminThreadUnread(ChatRoom room) {
    if (isAdminResolved(room)) return false;
    if (!needsAdminReply(room)) return false;
    final readAt = _adminReadAtByThread[room.id];
    if (readAt == null) return true;
    return room.updatedAt.isAfter(readAt);
  }

  List<ChatRoom> listRooms() => listMyRooms();

  /// ห้องแชทของลูกค้า — ไม่ซ้ำ alias, เรียงยังไม่อ่านก่อน แล้วล่าสุดบน
  List<ChatRoom> listMyRooms() {
    final seen = <String>{};
    final list = _rooms.values
        .where((r) => _myThreadIds.contains(r.id))
        .where((r) => seen.add(r.id))
        .toList()
      ..sort((a, b) {
        final unreadCmp =
            unreadForThread(b.id).compareTo(unreadForThread(a.id));
        if (unreadCmp != 0) return unreadCmp;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  Iterable<ChatRoom> _dedupedRooms() sync* {
    final seen = <String>{};
    for (final room in _rooms.values) {
      if (seen.add(room.id)) yield room;
    }
  }

  ChatRoom? roomForListing(String listingId) {
    for (final room in _rooms.values) {
      if (room.listingId == listingId || room.listingCode == listingId) {
        return room;
      }
    }
    return _rooms[listingId];
  }

  ChatRoom _resolveActiveRoom(ChatRoom room) =>
      roomById(room.id) ??
      roomForListing(room.listingId) ??
      roomForListing(room.listingCode) ??
      room;

  void _registerRoom(ChatRoom room, {String? aliasKey}) {
    _rooms[room.id] = room;
    if (room.isPersisted) {
      _myThreadIds.add(room.id);
    }
    if (aliasKey != null && aliasKey.isNotEmpty) {
      _rooms[aliasKey] = room;
    }
  }

  void clearAllUnread() {
    if (_unreadByThread.isEmpty) return;
    _unreadByThread.clear();
    notifyListeners();
  }

  ChatRoom? roomById(String id) => _rooms[id];

  ChatRoom? roomByTransactionRef(String ref) {
    final key = ref.trim();
    if (key.isEmpty) return null;
    for (final room in _rooms.values) {
      if (room.effectiveTransactionRef == key) return room;
    }
    return null;
  }

  /// โหลดประวัติแชทจาก Supabase (แท็บแชท)
  Future<void> refreshMyThreads() async {
    if (!_backendActive) return;
    try {
      final rooms = await _repo.fetchMyThreads();
      _myThreadIds
        ..clear()
        ..addAll(rooms.map((r) => r.id));
      for (final room in rooms) {
        _rooms[room.id] = room;
        _detectUnreadFromMessages(room);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('refreshMyThreads: $e');
    }
  }

  /// Realtime — รับข้อความทีมงาน + อัปเดตรายการแชท (ทุกหน้า ไม่เฉพาะแท็บข้อความ)
  Future<void> ensureCustomerInboxRealtime() async {
    if (!_backendActive) return;
    final uid = SupabaseService.client?.auth.currentUser?.id;
    if (uid == null) return;

    await refreshMyThreads();

    if (_customerInboxChannel != null) return;

    final channel = SupabaseService.client!.channel('customer-inbox-$uid');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) {
        final record = payload.newRecord;
        if (record.isEmpty) return;
        _onCustomerChatMessage(Map<String, dynamic>.from(record));
      },
    );
    channel.subscribe();
    _customerInboxChannel = channel;
  }

  Future<void> _onCustomerChatMessage(Map<String, dynamic> record) async {
    final role = record['role']?.toString();
    if (role != 'admin_notice') return;

    final threadId = record['thread_id']?.toString() ?? '';
    if (!await _isMyThread(threadId)) return;

    final message = ChatMessage.fromJson(record);
    final text = message.text.trim();
    final isAuto = _isAutoStaffAck(text) ||
        text.startsWith('⚠️') ||
        _isViewingDetailNotice(text);

    await _mergeIncomingMessage(threadId, message);

    if (isAuto) {
      notifyListeners();
      return;
    }

    bumpUnread(threadId);
    final preview = text.isNotEmpty
        ? (text.length > 80 ? '${text.substring(0, 80)}…' : text)
        : (message.links.isNotEmpty ? message.links.first.label : 'ข้อความใหม่');
    InAppNotificationHub.instance.show(
      'ข้อความจากทีม: $preview',
      threadId: threadId,
    );
    notifyListeners();
  }

  Future<bool> _isMyThread(String threadId) async {
    if (threadId.isEmpty) return false;
    if (_myThreadIds.contains(threadId)) return true;
    final uid = SupabaseService.client?.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await SupabaseService.client!
          .from('chat_threads')
          .select('user_id')
          .eq('id', threadId)
          .maybeSingle();
      if (row?['user_id']?.toString() == uid) {
        _myThreadIds.add(threadId);
        return true;
      }
    } catch (e) {
      debugPrint('_isMyThread: $e');
    }
    return false;
  }

  Future<void> _mergeIncomingMessage(String threadId, ChatMessage message) async {
    var room = roomById(threadId);
    if (room == null) {
      final fetched = await _repo.fetchThreadById(threadId);
      if (fetched != null) {
        _registerRoom(fetched);
        room = fetched;
      } else {
        await refreshMyThreads();
        return;
      }
    }
    if (!room.messages.any((m) => m.id == message.id)) {
      room.messages.add(message);
      room.updatedAt = message.createdAt;
    }
  }

  void _detectUnreadFromMessages(ChatRoom room) {
    if (_unreadByThread.containsKey(room.id)) return;
    for (var i = room.messages.length - 1; i >= 0; i--) {
      final m = room.messages[i];
      if (m.role == ChatMessageRole.adminNotice &&
          !_isAutoStaffAck(m.text) &&
          !m.text.startsWith('⚠️') &&
          !_isViewingDetailNotice(m.text)) {
        bumpUnread(room.id);
        return;
      }
      if (m.role == ChatMessageRole.user) return;
    }
  }

  /// โหลด inbox ทีมงานจาก Supabase
  Future<void> refreshAdminInbox() async {
    if (_adminInboxBackendActive) {
      try {
        final pending = await _repo.fetchAdminInbox();
        final openAssigned = await _repo.fetchAdminOpenAssigned();
        final resolved = await _repo.fetchAdminResolved();
        for (final room in {...pending, ...openAssigned, ...resolved}) {
          AdminChatLabelService.instance.applyToRoom(room);
          _rooms[room.id] = room;
        }
      } catch (e) {
        debugPrint('refreshAdminInbox: $e');
      }
    }
    _ensureCastSimulation();
    notifyListeners();
  }

  void resetCastSimulation() {
    final remove = _rooms.keys
        .where((k) => k.startsWith('cast-chat-') || k.startsWith('demo-'))
        .toList();
    for (final key in remove) {
      _rooms.remove(key);
    }
    _castSimSeeded = false;
    notifyListeners();
  }

  void _syncDemoLeadRoomMetadata(ChatRoom existing, ChatRoom seed) {
    if (seed.adminDisplayName?.trim().isNotEmpty == true) {
      existing.adminDisplayName = seed.adminDisplayName!.trim();
    }
    existing.viewingSubmitted = seed.viewingSubmitted;
    existing.category = seed.category;
    for (var i = 0; i < existing.messages.length; i++) {
      final m = existing.messages[i];
      if (m.role != ChatMessageRole.system ||
          !m.text.contains('สรุปโปรไฟล์ลูกค้า')) {
        continue;
      }
      final nick = existing.adminDisplayName ?? 'ลูกค้า';
      existing.messages[i] = ChatMessage(
        id: m.id,
        role: m.role,
        text: 'สรุปโปรไฟล์ลูกค้า\n• ชื่อ: $nick\n• ทรัพย์: ${existing.listingCode}',
        createdAt: m.createdAt,
        requiresAdmin: m.requiresAdmin,
        links: m.links,
      );
    }
  }

  /// เติมห้องจำลองที่ยังไม่มี — ไม่ล้างข้อความที่ส่งไปแล้ว
  void reloadCastSimulation() {
    if (!DemoCastSimulation.enabled) return;
    _ensureCastSimulation();
  }

  void _ensureCastSimulation() {
    if (!DemoCastSimulation.enabled) return;
    DemoViewingRecordSeed.ensure();
    final seeds = DemoCastSession.hubEnabled
        ? DemoCastSimulation.chatSeeds()
        : DemoCastSimulation.viewingLeadChatSeeds();
    var added = false;
    for (final seed in seeds) {
      final room = DemoCastSimulation.toRoom(seed);
      final existing = _rooms[room.id];
      if (existing != null) {
        if (room.id.startsWith('demo-lead-chat-')) {
          _syncDemoLeadRoomMetadata(existing, room);
        }
        continue;
      }
      _registerRoom(room, aliasKey: room.listingCode);
      _registerRoom(room, aliasKey: room.id);
      added = true;
    }
    if (added || !_castSimSeeded) {
      _castSimSeeded = true;
      notifyListeners();
    }
  }

  /// เปิดแชทนัดดู demo — ไม่รอ Supabase
  void ensureViewingLeadChat(String roomId) {
    _ensureCastSimulation();
    if (!roomId.startsWith('demo-lead-chat-')) return;
    final leadId = roomId.replaceFirst('demo-lead-chat-', '');
    for (final lead in DemoCastSimulation.leads()) {
      if (lead['id'] != leadId) continue;
      final code = lead['listing_code']?.toString() ?? 'DEMO';
      final nick = lead['seeker_nickname']?.toString();
      if (_rooms.containsKey(roomId)) {
        final existing = _rooms[roomId]!;
        if (nick != null && nick.isNotEmpty) {
          existing.adminDisplayName = nick;
          for (var i = 0; i < existing.messages.length; i++) {
            final m = existing.messages[i];
            if (m.role != ChatMessageRole.system ||
                !m.text.contains('สรุปโปรไฟล์ลูกค้า')) {
              continue;
            }
            existing.messages[i] = ChatMessage(
              id: m.id,
              role: m.role,
              text:
                  'สรุปโปรไฟล์ลูกค้า\n• ชื่อ: $nick\n• ทรัพย์: ${existing.listingCode}',
              createdAt: m.createdAt,
              requiresAdmin: m.requiresAdmin,
              links: m.links,
            );
          }
          notifyListeners();
        }
        return;
      }
      final room = memoryOpenCustomerRoomForLead(
        roomId: roomId,
        listingCode: code,
        listingTitle: code,
        seekerNickname: nick,
        seekerUserId: leadId,
      );
      cacheAdminRoom(room);
      return;
    }
    if (_rooms.containsKey(roomId)) return;
    cacheAdminRoom(
      memoryOpenCustomerRoomForLead(
        roomId: roomId,
        listingCode: 'DEMO',
        listingTitle: 'Demo viewing',
        seekerUserId: leadId,
      ),
    );
  }

  String? get _myAdminId {
    if (DemoCastSession.instance.hasActiveCast) {
      return DemoCastSession.instance.effectiveAdminId;
    }
    return SupabaseService.client?.auth.currentUser?.id;
  }

  String get currentAdminId => _myAdminId ?? 'demo-admin';

  /// ตรงกับ `_countChatWaiting` ใน AdminRepository
  bool _matchesAdminWaitingQueue(ChatRoom room) {
    if (room.adminReplyDone) return false;
    if (room.viewingSubmitted) return true;
    if (room.adminEscalated) return true;
    if (room.status == 'waiting_admin') return true;
    const cats = {
      'escalation',
      'viewing_request',
      'demand_offer',
      'discovery',
      'staff_support',
      'customer_requirement',
      'booking_interest',
    };
    final cat = room.category;
    if (cat != null && cats.contains(cat)) return true;
    return room.messages.any((m) => m.requiresAdmin);
  }

  List<ChatRoom> listAdminInbox({
    AdminInboxBucket bucket = AdminInboxBucket.unclaimed,
    bool includeResolved = false,
  }) {
    _ensureCastSimulation();
    if (!_adminInboxBackendActive) {
      _memoryEnsureDemoAdminChats();
    }
    final uid = _myAdminId;
    final list = _dedupedRooms().where((room) {
      if (!_matchesAdminWaitingQueue(room) && !_isAdminRelevant(room)) {
        return false;
      }
      switch (bucket) {
        case AdminInboxBucket.unclaimed:
          return room.isUnclaimed &&
              (_matchesAdminWaitingQueue(room) || needsAdminReply(room));
        case AdminInboxBucket.mine:
          return !isAdminResolved(room) && room.isClaimedBy(uid);
        case AdminInboxBucket.resolved:
          return isAdminResolved(room);
      }
    }).toList()
      ..sort((a, b) {
        final score = _adminInboxScore(b).compareTo(_adminInboxScore(a));
        if (score != 0) return score;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    if (includeResolved && bucket != AdminInboxBucket.resolved) {
      final closed = _dedupedRooms()
          .where(_isAdminRelevant)
          .where(isAdminResolved)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return [...list, ...closed];
    }
    for (final room in list) {
      AdminChatLabelService.instance.applyToRoom(room);
    }
    return list;
  }

  bool isAdminResolved(ChatRoom room) => room.status == 'resolved';

  bool canReplyAsAdmin(ChatRoom room) {
    if (isAdminResolved(room)) return false;
    if (room.isUnclaimed) return false;
    return room.isClaimedBy(_myAdminId);
  }

  bool isClaimedByOtherAdmin(ChatRoom room) {
    final uid = _myAdminId;
    if (room.isUnclaimed) return false;
    return !room.isClaimedBy(uid);
  }

  /// ลูกค้าเดิมมีแอดมินดูแลอยู่ในแชทอื่นที่ยังไม่ปิดเคส
  CustomerAdminContinuityHint? continuityHintForRoom(ChatRoom room) {
    final pid = room.participantUserId?.trim();
    if (pid == null || pid.isEmpty) return null;

    ChatRoom? best;
    for (final other in _dedupedRooms()) {
      if (other.id == room.id) continue;
      if (other.participantUserId != pid) continue;
      if (other.isUnclaimed) continue;
      if (isAdminResolved(other)) continue;
      final adminId = other.assignedAdminId?.trim();
      final adminName = other.assignedAdminName?.trim();
      if (adminId == null ||
          adminId.isEmpty ||
          adminName == null ||
          adminName.isEmpty) {
        continue;
      }
      if (best == null || other.updatedAt.isAfter(best.updatedAt)) {
        best = other;
      }
    }
    if (best == null) return null;
    return CustomerAdminContinuityHint(
      participantUserId: pid,
      adminId: best.assignedAdminId!,
      adminName: best.assignedAdminName!,
      otherRoomId: best.id,
      otherRoomTitle: best.displayTitle,
    );
  }

  int _adminInboxScore(ChatRoom room) {
    if (room.category == 'booking_interest') return 1000;
    if (room.viewingSubmitted) return 900;
    if (room.priority == 'high') return 800;
    if (room.category == 'viewing_request') return 700;
    if (room.category == 'escalation') return 600;
    return 0;
  }

  ChatRoom? _pendingOpenRoom;
  ChatRoom? consumePendingOpenRoom() {
    final room = _pendingOpenRoom;
    _pendingOpenRoom = null;
    return room;
  }

  void _queueOpenRoom(ChatRoom room) {
    _pendingOpenRoom = room;
    notifyListeners();
  }

  Future<void> claimThread(ChatRoom room) async {
    if (_backendActive && room.isPersisted) {
      final updated = await _repo.claimThread(room.id);
      final profile = await _repo.fetchAdminDisplayName(updated.assignedAdminId);
      updated.assignedAdminName =
          profile ?? AuthService.instance.displayEmail ?? 'ทีมงาน';
      _rooms[room.id] = updated;
      notifyListeners();
      return;
    }
    room.assignedAdminId = _myAdminId ?? 'demo-admin';
    room.assignedAdminName = AuthService.instance.displayEmail ?? 'ทีมทดลอง';
    room.assignedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> assignThread(ChatRoom room, AdminPeer peer) async {
    if (_backendActive && room.isPersisted) {
      final updated = await _repo.assignThread(room.id, peer.id);
      updated.assignedAdminName = peer.displayName;
      _rooms[room.id] = updated;
      notifyListeners();
      return;
    }
    room.assignedAdminId = peer.id;
    room.assignedAdminName = peer.displayName;
    room.assignedAt = DateTime.now();
    notifyListeners();
  }

  Future<List<AdminPeer>> fetchTeamAdmins() async {
    if (!_backendActive) {
      return const [
        AdminPeer(id: 'demo-admin-1', displayName: 'แอดมิน A'),
        AdminPeer(id: 'demo-admin-2', displayName: 'แอดมิน B'),
      ];
    }
    return _repo.fetchTeamAdmins();
  }

  bool _isAdminRelevant(ChatRoom room) {
    if (room.viewingSubmitted && !room.adminReplyDone) return true;
    if (room.category == 'booking_interest') return true;
    if (room.category == 'escalation' ||
        room.category == 'viewing_request' ||
        room.category == 'demand_offer') {
      return true;
    }
    if (room.category == 'discovery' || room.isDiscovery) return true;
    if (room.category == 'customer_requirement' || room.isCustomerRequirement) {
      return true;
    }
    if (room.isStaffSupport && room.status == 'waiting_admin') return true;
    if (room.adminEscalated && !room.adminReplyDone) return true;
    if (room.status == 'waiting_admin' && !room.adminReplyDone) return true;
    if (room.category == 'property_faq' &&
        room.adminEscalated &&
        !room.adminReplyDone) {
      return true;
    }
    return room.messages.any((m) => m.requiresAdmin);
  }

  bool needsAdminReply(ChatRoom room) {
    if (!_isAdminRelevant(room)) return false;
    if (room.adminReplyDone) return false;
    // ใช้สถานะ thread เป็นหลัก (inbox preview อาจมีแค่ข้อความ system ล่าสุด)
    if (room.adminEscalated) return true;
    if (room.viewingSubmitted) return true;
    if (room.status == 'waiting_admin') return true;
    if (room.messages.any((m) => m.requiresAdmin)) return true;
    if (room.messages.isEmpty) return false;
    for (var i = room.messages.length - 1; i >= 0; i--) {
      final m = room.messages[i];
      if (m.role == ChatMessageRole.user) return true;
      if (m.role == ChatMessageRole.adminNotice &&
          !_isAutoStaffAck(m.text) &&
          !m.text.startsWith('⚠️') &&
          !_isViewingDetailNotice(m.text)) {
        return false;
      }
    }
    return false;
  }

  Future<void> sendAdminReply(
    ChatRoom room,
    String text, {
    List<ChatMessageLink> links = const [],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && links.isEmpty) return;

    if (isClaimedByOtherAdmin(room)) {
      throw StateError('claimed_by_other');
    }

    final linkPayload = links.map((l) => l.toJson()).toList();

    if (_backendActive && room.isPersisted) {
      await _repo.sendAdminReply(
        room,
        trimmed.isEmpty ? ' ' : trimmed,
        links: linkPayload,
      );
      notifyListeners();
      return;
    }

    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-admin',
      role: ChatMessageRole.adminNotice,
      text: trimmed,
      links: links,
    ));
    room.updatedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> markAdminResolved(ChatRoom room) async {
    if (_backendActive && room.isPersisted) {
      await _repo.markResolved(room);
      notifyListeners();
      return;
    }
    room.adminEscalated = false;
    room.adminReplyDone = true;
    room.status = 'resolved';
    notifyListeners();
  }

  void _memoryEnsureDemoAdminChats() {
    if (!Env.trialMode) return;
    if (_rooms.values.any(needsAdminReply)) return;

    final staff = _memoryOpenStaffSupportRoom();
    staff.messages.add(
      ChatMessage(
        id: 'demo-staff-user-1',
        role: ChatMessageRole.user,
        text: 'ขอสอบถามเรื่องค่าคอมและเงื่อนไขโคนายหน้าครับ',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    );
    staff.adminEscalated = true;
    staff.updatedAt = DateTime.now().subtract(const Duration(minutes: 18));

    final listing = DemoListingsFactory.cached.first;
    final property = _memoryOpenRoom(
      listingId: listing.id,
      listingCode: listing.listingCode,
      listingTitle: listing.title,
      projectName: listing.projectName,
      allowViewingRequest: true,
    );
    property.messages.addAll([
      ChatMessage(
        id: 'demo-prop-user-1',
        role: ChatMessageRole.user,
        text: 'ขอเบอร์ติดต่อเจ้าของได้ไหมครับ อยากต่อรองราคา',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'demo-prop-sys-1',
        role: ChatMessageRole.system,
        text: _copy.chatEscalateToStaff,
        requiresAdmin: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 1)),
      ),
    ]);
    property.participantUserId = 'demo-user';
    property.adminEscalated = true;
    property.updatedAt = DateTime.now().subtract(const Duration(hours: 2));

    final viewing = _memoryOpenRoom(
      listingId: 'demo-viewing-room',
      listingCode: 'RENT-CD-2026-000042',
      listingTitle: 'The Line Sukhumvit 101 · 2BR',
      projectName: 'The Line Sukhumvit 101',
      allowViewingRequest: true,
    );
    _memoryAppendViewingSummary(viewing, {
      'ชื่อ': 'คุณมิ้นท์',
      'เบอร์': '08x-xxx-5725',
      'งบ': '18,000 – 22,000 บาท/เดือน',
      'นัดดูทรัพย์': '12/6/2569 · 14:00 น.',
      'ทรัพย์': 'RENT-CD-2026-000042',
    });
    viewing.adminReplyDone = false;
    notifyListeners();
  }

  @Deprecated('Use ensureDemoAdminChats only in trial — call refreshAdminInbox instead')
  void ensureDemoAdminChats() => _memoryEnsureDemoAdminChats();

  /// แชทค้นหา/แนะนำทรัพย์ (รวม discovery — ไม่แยก AI room)
  Future<ChatRoom> openDiscoveryRoom() async {
    if (_backendActive) {
      try {
        final room = await _repo.openThread(
          roomKind: 'property',
          listingCode: 'DISCOVERY',
          listingTitle: _copy.chatDiscoveryRoomTitle,
        );
        _rooms[room.id] = room;
        notifyListeners();
        return room;
      } catch (e) {
        debugPrint('openDiscoveryRoom backend: $e');
        throw Exception('ไม่สามารถเปิดแชทได้ กรุณาลองใหม่');
      }
    }
    return _memoryOpenDiscoveryRoom();
  }

  @Deprecated('Use openDiscoveryRoom')
  Future<ChatRoom> openAiSupportRoom() => openDiscoveryRoom();

  Future<ChatRoom> openStaffSupportRoom() async {
    if (_backendActive) {
      final room = await _repo.openThread(
        roomKind: 'staff_support',
        listingCode: 'SUPPORT-STAFF',
        listingTitle: _copy.chatStaffRoomTitle,
      );
      _rooms[room.id] = room;
      notifyListeners();
      return room;
    }
    return _memoryOpenStaffSupportRoom();
  }

  Future<ChatRoom> openRoom({
    required String listingId,
    required String listingCode,
    required String listingTitle,
    String? projectName,
    bool allowViewingRequest = false,
  }) async {
    final cached = roomForListing(listingId);
    if (cached != null) {
      if (allowViewingRequest) cached.allowViewingRequest = true;
      return cached;
    }

    if (_backendActive) {
      try {
        var backendListingId = listingIdForBackend(listingId);
        backendListingId ??=
            await _listingRepo.resolveIdByCode(listingCode);
        final room = await _repo.openThread(
          roomKind: 'property',
          listingId: backendListingId,
          listingCode: listingCode,
          listingTitle: listingTitle,
          projectName: projectName,
          allowViewingRequest: allowViewingRequest,
          welcomeText: _copy.chatPropertyWelcome(
            listingTitle,
            allowViewing: allowViewingRequest,
          ),
        );
        _registerRoom(room, aliasKey: listingId);
        _registerRoom(room, aliasKey: listingCode);
        notifyListeners();
        return room;
      } catch (e) {
        debugPrint('openRoom backend: $e');
        throw Exception('ไม่สามารถเปิดแชทได้ กรุณาลองใหม่');
      }
    }

    return _memoryOpenRoom(
      listingId: listingId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      projectName: projectName,
      allowViewingRequest: allowViewingRequest,
      participantUserId: AuthService.instance.effectiveUserId,
    );
  }

  Future<void> sendUserMessage(ChatRoom room, String text) async {
    var active = _resolveActiveRoom(room);
    await _syncThreadMeta(active);
    active = _resolveActiveRoom(room);
    if (_backendActive && !active.isPersisted) {
      try {
        final persisted = await _repo.openThread(
          roomKind: active.roomKind ?? 'property',
          listingId: listingIdForBackend(active.listingId),
          listingCode: active.listingCode,
          listingTitle: active.listingTitle,
          projectName: active.projectName,
          allowViewingRequest: active.allowViewingRequest,
          welcomeText: _copy.chatPropertyWelcome(
            active.listingTitle,
            allowViewing: active.allowViewingRequest,
          ),
        );
        _registerRoom(persisted, aliasKey: active.listingId);
        _registerRoom(persisted, aliasKey: active.listingCode);
        active = persisted;
      } catch (e) {
        debugPrint('sendUserMessage persist: $e');
        throw Exception('ไม่สามารถส่งข้อความได้ กรุณาลองใหม่');
      }
    }
    if (_backendActive && active.isPersisted) {
      await _repo.sendUserMessage(active, text);
      notifyListeners();
      return;
    }
    await _memorySendUserMessage(active, text);
  }

  /// ให้แน่ใจว่าห้องแชทถูกบันทึกใน Supabase ก่อนส่งฟอร์มนัดดู
  Future<ChatRoom> ensurePersistedRoom(ChatRoom room) async {
    var active = _resolveActiveRoom(room);
    if (_backendActive && !active.isPersisted) {
      try {
        final persisted = await _repo.openThread(
          threadId: active.id.startsWith('__') ? null : active.id,
          roomKind: active.roomKind ?? 'property',
          listingId: listingIdForBackend(active.listingId),
          listingCode: active.listingCode,
          listingTitle: active.listingTitle,
          projectName: active.projectName,
          allowViewingRequest: active.allowViewingRequest,
          welcomeText: _copy.chatPropertyWelcome(
            active.listingTitle,
            allowViewing: active.allowViewingRequest,
          ),
        );
        _registerRoom(persisted, aliasKey: active.listingId);
        _registerRoom(persisted, aliasKey: active.listingCode);
        active = persisted;
      } catch (e) {
        debugPrint('ensurePersistedRoom: $e');
        throw Exception('ไม่สามารถเชื่อมต่อแชทได้ กรุณาลองใหม่');
      }
    }
    return active;
  }

  Future<void> appendViewingSummary(
    ChatRoom room,
    Map<String, String> summary, {
    bool duplicatePhoneSuffix = false,
  }) async {
    final active = await ensurePersistedRoom(room);
    if (_backendActive && active.isPersisted) {
      try {
        await _repo.recordViewing(
          active,
          summary,
          duplicatePhoneSuffix: duplicatePhoneSuffix,
        );
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('appendViewingSummary backend: $e');
        throw Exception('ส่งคำขอนัดดูไม่สำเร็จ กรุณาลองใหม่');
      }
    }
    _memoryAppendViewingSummary(
      active,
      summary,
      duplicatePhoneSuffix: duplicatePhoneSuffix,
    );
  }

  /// ส่งคำขอนัดดูพร้อมแท็กโปรไฟล์ (Phase 24)
  Future<void> submitViewingWithTags(
    ChatRoom room, {
    required ViewingRequest viewingRequest,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required String scheduleLabel,
    required Map<String, String> leadSummary,
  }) async {
    final active = await ensurePersistedRoom(room);
    if (_backendActive && active.isPersisted) {
      try {
        await _repo.recordViewing(active, leadSummary);
      } catch (e) {
        debugPrint('submitViewingWithTags backend: $e');
        throw Exception('ส่งคำขอนัดดูไม่สำเร็จ กรุณาลองใหม่');
      }
    }
    _memorySubmitViewingWithTags(
      active,
      viewingRequest: viewingRequest,
      clientTag: clientTag,
      presenterTag: presenterTag,
      scheduleLabel: scheduleLabel,
      leadSummary: leadSummary,
    );
    await _postHubViewingRecap(
      viewingRequest: viewingRequest,
      clientTag: clientTag,
      presenterTag: presenterTag,
      scheduleLabel: scheduleLabel,
      propertyLabel: '${active.listingCode} · ${active.listingTitle}',
    );
    await ViewingAppointmentRecordService.instance.registerFromViewingForm(
      viewingRequest: viewingRequest,
      clientTag: clientTag,
      presenterTag: presenterTag,
      scheduleLabel: scheduleLabel,
      room: active,
    );
  }

  /// แชทกลางผู้ใช้ — seeker หรือ agent hub
  Future<ChatRoom> ensureParticipantHub() async {
    final uid = AuthService.instance.effectiveUserId ?? 'demo-user';
    final role = await AuthService.instance.fetchProfileRole();
    return ensureHubForUser(uid, agent: role == 'agent');
  }

  ChatRoom ensureHubForUser(String userId, {bool agent = false}) {
    return agent ? _memoryEnsureAgentHub(userId) : _memoryEnsureSeekerHub(userId);
  }

  ChatRoom? participantHubForUser(String userId, {bool agent = false}) {
    final id = agent
        ? ChatServiceIds.agentHub(userId)
        : ChatServiceIds.seekerHub(userId);
    return _rooms[id];
  }

  List<ChatRoom> threadsForUser(String userId, {bool agent = false}) {
    final hubId = agent
        ? ChatServiceIds.agentHub(userId)
        : ChatServiceIds.seekerHub(userId);
    return _dedupedRooms()
        .where((r) => r.id != hubId && _myThreadIds.contains(r.id))
        .toList();
  }

  /// สร้าง/อัปเดต thread ทรัพย์พร้อมทวนคำขอนัดดู (demo seed)
  static bool _returningCustomerDemoSeeded = false;

  /// ลูกค้าเดิมทักห้องใหม่ — มีเคสเก่าที่แอดมิน A รับอยู่ (demo)
  void seedReturningCustomerDemo({
    required String participantUserId,
    required ListingPublic activeListing,
    required ListingPublic newListing,
    required String adminId,
    required String adminName,
  }) {
    if (_returningCustomerDemoSeeded) return;
    _returningCustomerDemoSeeded = true;

    final active = _memoryOpenRoom(
      listingId: activeListing.id,
      listingCode: activeListing.listingCode,
      listingTitle: activeListing.title,
      projectName: activeListing.projectName,
      allowViewingRequest: true,
      participantUserId: participantUserId,
    );
    active.assignedAdminId = adminId;
    active.assignedAdminName = adminName;
    active.assignedAt = DateTime.now().subtract(const Duration(hours: 5));
    active.adminEscalated = true;
    active.status = 'waiting_admin';
    if (!active.messages.any((m) => m.id == 'demo-returning-active')) {
      active.messages.add(
        ChatMessage(
          id: 'demo-returning-active',
          role: ChatMessageRole.user,
          text: 'ขอรายละเอียดเพิ่มและนัดดูห้องนี้ครับ',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      );
    }

    final fresh = _memoryOpenRoom(
      listingId: newListing.id,
      listingCode: newListing.listingCode,
      listingTitle: newListing.title,
      projectName: newListing.projectName,
      allowViewingRequest: true,
      participantUserId: participantUserId,
    );
    fresh.adminEscalated = true;
    fresh.status = 'waiting_admin';
    fresh.category = 'escalation';
    fresh.updatedAt = DateTime.now().subtract(const Duration(minutes: 12));
    if (!fresh.messages.any((m) => m.id == 'demo-returning-new')) {
      fresh.messages.addAll([
        ChatMessage(
          id: 'demo-returning-new',
          role: ChatMessageRole.user,
          text: 'สวัสดีครับ สนใจห้องนี้ด้วยครับ ช่วยแนะนำได้ไหม',
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        ChatMessage(
          id: 'demo-returning-new-sys',
          role: ChatMessageRole.system,
          text: _copy.chatEscalateToStaff,
          requiresAdmin: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
        ),
      ]);
    }
    notifyListeners();
  }

  void seedPropertyViewingRecap({
    required ViewingRequest req,
    required String recapText,
  }) {
    final room = roomForListing(req.listingId) ??
        _memoryOpenRoom(
          listingId: req.listingId,
          listingCode: req.listingCode,
          listingTitle: req.listingTitle,
          projectName: req.projectName,
          allowViewingRequest: true,
          participantUserId: req.createdByUserId,
        );
    if (room.messages.any((m) => m.id == 'demo-vr-${req.id}')) return;
    room.messages.add(ChatMessage(
      id: 'demo-vr-${req.id}',
      role: ChatMessageRole.system,
      text: recapText,
      links: [
        ChatMessageLink.profileTag(req.clientTagCode, req.clientTagCode),
        ChatMessageLink.viewingRequest(req.code, req.code),
      ],
      createdAt: req.createdAt,
    ));
    room.viewingSubmitted = true;
    room.category = 'viewing_request';
    room.adminEscalated = true;
    room.status = 'waiting_admin';
    room.priority = 'high';
    room.updatedAt = req.createdAt;
    notifyListeners();
  }

  /// เพิ่มข้อความระบบใน Hub (ใช้ตอน seed demo)
  void appendHubSystemMessage({
    required String userId,
    required bool agent,
    required ChatMessage message,
  }) {
    final hub = ensureHubForUser(userId, agent: agent);
    hub.messages.add(message);
    if (message.createdAt.isAfter(hub.updatedAt)) {
      hub.updatedAt = message.createdAt;
    }
    notifyListeners();
  }

  Future<void> postAdminMessageToHub(String userId, String text, {bool agent = false}) async {
    final hub = agent
        ? _memoryEnsureAgentHub(userId)
        : _memoryEnsureSeekerHub(userId);
    hub.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-admin',
      role: ChatMessageRole.adminNotice,
      text: text,
    ));
    hub.updatedAt = DateTime.now();
    notifyListeners();
  }

  /// ลูกค้ากดสนใจจอง — แจ้งแอดมินด่วนสูงสุด
  Future<ChatRoom> recordBookingInterest({
    required ListingPublic listing,
    required bool isEnglish,
  }) async {
    final s = AppStrings(isEnglish);
    final summary = {
      s.t('ทรัพย์', 'Property'): '${listing.listingCode} · ${listing.localizedTitle(isEnglish)}',
      if (listing.localizedProjectName(isEnglish) != null)
        s.t('โครงการ', 'Project'): listing.localizedProjectName(isEnglish)!,
      s.t('ราคา', 'Price'): s.priceLabelChat(listing),
      s.t('ความต้องการ', 'Intent'): s.bookingInterestIntent,
    };

    final room = await openRoom(
      listingId: listing.id,
      listingCode: listing.listingCode,
      listingTitle: listing.localizedTitle(isEnglish),
      projectName: listing.localizedProjectName(isEnglish) ?? listing.projectName,
      allowViewingRequest: true,
    );

    if (_backendActive) {
      if (!room.isPersisted) {
        throw Exception('ไม่สามารถเชื่อมต่อแชทได้ กรุณาลองใหม่');
      }
      try {
        await _repo.recordBookingInterest(room, summary);
        await refreshMyThreads();
        notifyListeners();
        _queueOpenRoom(room);
        return room;
      } catch (e) {
        debugPrint('recordBookingInterest backend: $e');
        throw Exception('ส่งความสนใจจองไม่สำเร็จ กรุณาลองใหม่');
      }
    }

    _memoryRecordBookingInterest(room, summary);
    _queueOpenRoom(room);
    return room;
  }

  void _memoryRecordBookingInterest(ChatRoom room, Map<String, String> summary) {
    final lines = summary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
    room.category = 'booking_interest';
    room.priority = 'high';
    room.status = 'waiting_admin';
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.messages.addAll([
      ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-booking',
        role: ChatMessageRole.system,
        text: '${_copy.bookingInterestReceived}\n${_copy.viewingRefNote(room.effectiveTransactionRef, null)}',
        requiresAdmin: true,
      ),
      ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-summary',
        role: ChatMessageRole.system,
        text: '${_copy.chatCustomerSummaryHeader}\n$lines',
        requiresAdmin: true,
      ),
      ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-admin',
        role: ChatMessageRole.adminNotice,
        text: _copy.bookingInterestAdminAlert,
      ),
    ]);
    room.updatedAt = DateTime.now();
    notifyListeners();
  }

  Future<ChatRoom> recordDemandOffer({
    required Map<String, String> summary,
    required String demandPostCode,
    String? demandPostTitle,
    String? transactionRef,
  }) async {
    if (_backendActive) {
      final room = await _repo.recordDemandOffer(
        summary: summary,
        demandPostCode: demandPostCode,
        demandPostTitle: demandPostTitle,
      );
      _rooms[room.id] = room;
      await refreshMyThreads();
      notifyListeners();
      return room;
    }
    return _memoryRecordDemandOffer(
      summary: summary,
      demandPostCode: demandPostCode,
      demandPostTitle: demandPostTitle,
      transactionRef: transactionRef,
    );
  }

  /// เปิดแชทส่งความต้องการหาทรัพย์ให้ทีมงาน
  Future<ChatRoom> recordRequirement(CustomerRequirement req) async {
    final isEnglish = _copy.isEnglish;
    final summary = req.toChatSummary(isEnglish);
    final title = req.localizedTitle(isEnglish);

    if (_backendActive &&
        req.savedToDatabase &&
        req.id.isNotEmpty &&
        !req.id.startsWith('req-demo')) {
      try {
        final room = await _repo.recordRequirement(
          requirementId: req.id,
          summary: summary,
          title: title,
        );
        _rooms[room.id] = room;
        notifyListeners();
        return room;
      } catch (e) {
        debugPrint('recordRequirement backend fallback: $e');
      }
    }

    final roomId = ChatServiceIds.customerRequirement(req.id);
    return _memoryRecordRequirement(
      req,
      summary: summary,
      roomId: roomId,
      title: title,
    );
  }

  Future<ChatRoom?> openRequirementChat(CustomerRequirement req) async {
    if (req.threadId != null && req.threadId!.isNotEmpty) {
      await loadThreadIfMissing(req.threadId!);
      return roomById(req.threadId!);
    }
    if (!req.savedToDatabase || req.id.startsWith('req-demo')) {
      return recordRequirement(req);
    }
    return recordRequirement(req);
  }

  RealtimeChannel? subscribeToThread(ChatRoom room, VoidCallback onUpdate) {
    if (!_backendActive || !room.isPersisted) return null;
    return _repo.subscribeThread(
      room.id,
      (message) {
        if (!room.messages.any((m) => m.id == message.id)) {
          room.messages.add(message);
          room.updatedAt = message.createdAt;
          if (message.role == ChatMessageRole.adminNotice &&
              !_isAutoStaffAck(message.text) &&
              !message.text.startsWith('⚠️') &&
              !_isViewingDetailNotice(message.text)) {
            bumpUnread(room.id);
            final preview = message.text.length > 80
                ? '${message.text.substring(0, 80)}…'
                : message.text;
            InAppNotificationHub.instance.show(
              'ข้อความจากทีม: $preview',
              threadId: room.id,
            );
          }
          onUpdate();
          notifyListeners();
        }
      },
      onThreadUpdate: (thread) {
        _applyThreadMeta(room, thread);
        onUpdate();
        notifyListeners();
      },
    );
  }

  void _applyThreadMeta(ChatRoom room, Map<String, dynamic> thread) {
    if (thread.containsKey('assigned_admin_id')) {
      final aid = thread['assigned_admin_id']?.toString();
      room.assignedAdminId =
          aid != null && aid.isNotEmpty ? aid : null;
    }
    if (thread['assigned_admin_name'] != null) {
      room.assignedAdminName = thread['assigned_admin_name']?.toString();
    }
    if (thread['admin_reply_done'] != null) {
      room.adminReplyDone = thread['admin_reply_done'] == true;
    }
    if (thread['status'] != null) {
      room.status = thread['status']?.toString();
    }
    if (thread['admin_escalated'] != null) {
      room.adminEscalated = thread['admin_escalated'] == true;
    }
    if (thread['user_id'] != null) {
      room.participantUserId = thread['user_id']?.toString();
    }
    if (thread.containsKey('admin_display_name')) {
      final v = thread['admin_display_name']?.toString().trim();
      room.adminDisplayName = v != null && v.isNotEmpty ? v : null;
    }
  }

  Future<void> setAdminDisplayName(ChatRoom room, String? name) async {
    final trimmed = name?.trim();
    room.adminDisplayName =
        trimmed != null && trimmed.isNotEmpty ? trimmed : null;
    await AdminChatLabelService.instance.setLabel(room.id, room.adminDisplayName);
    notifyListeners();
  }

  /// ห้องที่แอดมินมองเห็น — สำหรับค้นหาข้อความ
  List<ChatRoom> allAdminSearchableRooms() {
    return _dedupedRooms()
        .where((r) => _matchesAdminWaitingQueue(r) || _isAdminRelevant(r))
        .toList();
  }

  Future<void> _syncThreadMeta(ChatRoom room) async {
    if (!_backendActive || !room.isPersisted) return;
    try {
      final fresh = await _repo.fetchThreadById(room.id);
      if (fresh == null) return;
      room.assignedAdminId = fresh.assignedAdminId;
      room.assignedAdminName = fresh.assignedAdminName;
      room.adminReplyDone = fresh.adminReplyDone;
      room.status = fresh.status;
      room.adminEscalated = fresh.adminEscalated;
      room.category = fresh.category;
      room.participantUserId = fresh.participantUserId;
    } catch (_) {}
  }

  bool _isHumanHandoff(ChatRoom room) =>
      room.assignedAdminId != null &&
      room.assignedAdminId!.isNotEmpty &&
      !room.adminReplyDone;

  Future<void> loadThreadIfMissing(String threadId) async {
    if (_rooms.containsKey(threadId)) return;
    _ensureCastSimulation();
    if (_rooms.containsKey(threadId)) return;
    if (threadId.startsWith('demo-') || threadId.startsWith('cast-chat-')) {
      return;
    }
    if (!_adminInboxBackendActive) return;
    try {
      final room = await _repo
          .fetchThreadById(threadId)
          .timeout(const Duration(seconds: 4));
      if (room != null) {
        AdminChatLabelService.instance.applyToRoom(room);
        _rooms[threadId] = room;
        notifyListeners();
      }
    } catch (_) {}
  }

  // --- In-memory fallback (trial / demo) ---

  ChatRoom _memoryOpenDiscoveryRoom() {
    const id = ChatServiceIds.discovery;
    final existing = _rooms[id];
    if (existing != null) return existing;

    final room = ChatRoom(
      id: id,
      listingId: '',
      listingCode: 'DISCOVERY',
      listingTitle: _copy.chatDiscoveryRoomTitle,
      transactionRef: ReferenceCodes.demoChatRef(id),
      roomKind: 'property',
      category: 'discovery',
      messages: [
        ChatMessage(
          id: 'welcome-$id',
          role: ChatMessageRole.ai,
          text: _copy.chatDiscoveryWelcome(),
        ),
      ],
    );
    _rooms[id] = room;
    return room;
  }

  ChatRoom _memoryOpenStaffSupportRoom() => _memoryOpenSupportRoom(
        id: staffSupportId,
        title: _copy.chatAdminInquiry,
        code: 'SUPPORT-STAFF',
        welcome: _copy.chatAdminWelcome,
        staff: true,
      );

  ChatRoom _memoryOpenSupportRoom({
    required String id,
    required String title,
    required String code,
    required String welcome,
    bool staff = false,
  }) {
    final existing = _rooms[id];
    if (existing != null) return existing;

    final room = ChatRoom(
      id: id,
      listingId: id,
      listingCode: code,
      listingTitle: title,
      transactionRef: ReferenceCodes.demoChatRef(id),
      roomKind: staff ? 'staff_support' : 'property',
      adminEscalated: staff,
      messages: [
        ChatMessage(
          id: 'welcome-$id',
          role: staff ? ChatMessageRole.adminNotice : ChatMessageRole.ai,
          text: welcome,
        ),
      ],
    );
    _rooms[id] = room;
    return room;
  }

  ChatRoom _memoryOpenRoom({
    required String listingId,
    required String listingCode,
    required String listingTitle,
    String? projectName,
    bool allowViewingRequest = false,
    String? participantUserId,
  }) {
    final existing = _rooms[listingId];
    if (existing != null) {
      if (allowViewingRequest) existing.allowViewingRequest = true;
      if (participantUserId != null &&
          (existing.participantUserId == null ||
              existing.participantUserId!.isEmpty)) {
        existing.participantUserId = participantUserId;
      }
      return existing;
    }

    final room = ChatRoom(
      id: listingId,
      listingId: listingId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      projectName: projectName,
      transactionRef: ReferenceCodes.demoChatRef(listingId),
      roomKind: 'property',
      allowViewingRequest: allowViewingRequest,
      participantUserId: participantUserId,
      messages: [
        ChatMessage(
          id: 'welcome',
          role: ChatMessageRole.ai,
          text: _copy.chatPropertyWelcome(
            listingTitle,
            allowViewing: allowViewingRequest,
          ),
        ),
      ],
    );
    _rooms[listingId] = room;
    notifyListeners();
    return room;
  }

  Future<void> _memorySendUserMessage(ChatRoom room, String text) async {
    final trimmed = text.trim();
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      text: trimmed,
    );
    room.messages.add(userMsg);
    room.adminReplyDone = false;
    room.updatedAt = DateTime.now();

    if (_isHumanHandoff(room)) {
      notifyListeners();
      return;
    }

    final codeListing = await _findListingByCode(trimmed);
    if (codeListing != null) {
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-code',
        role: ChatMessageRole.ai,
        text: _copy.chatListingCodeFound(codeListing.listingCode),
        links: [
          ChatMessageLink(
            label: '${codeListing.listingCode} · ${_copy.priceLabelChat(codeListing)}',
            kind: ChatMessageLinkKind.listing,
            listingId: codeListing.id,
            projectName: codeListing.projectName,
          ),
        ],
      ));
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (_isSensitive(trimmed)) {
      room.adminEscalated = true;
      room.unclearStreak = 0;
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-escalate',
        role: ChatMessageRole.system,
        text: _copy.chatEscalateToStaff,
        requiresAdmin: true,
      ));
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (_isExplicitStaffRequest(trimmed)) {
      room.adminEscalated = true;
      room.unclearStreak = 0;
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-escalate',
        role: ChatMessageRole.system,
        text:
            'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด',
        requiresAdmin: true,
      ));
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (room.isStaffSupport) {
      if (_isExplicitStaffRequest(trimmed)) {
        room.adminEscalated = true;
        room.unclearStreak = 0;
        room.messages.add(ChatMessage(
          id: '${userMsg.id}-escalate',
          role: ChatMessageRole.system,
          text: _copy.chatAdminQueueNotice,
        ));
        room.updatedAt = DateTime.now();
        notifyListeners();
        return;
      }
      if (!room.adminEscalated) {
        final reply = await _discoveryReply(trimmed, room);
        room.messages.add(reply);
        room.unclearStreak = 0;
        room.updatedAt = DateTime.now();
        notifyListeners();
        return;
      }
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-staff',
        role: ChatMessageRole.adminNotice,
        text: _copy.chatStaffAck,
      ));
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (room.isDiscovery || _isDiscoveryIntent(trimmed)) {
      final reply = await _discoveryReply(trimmed, room);
      room.messages.add(reply);
      room.unclearStreak = 0;
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (room.isPropertyListing) {
      room.adminEscalated = true;
      room.status = 'waiting_admin';
      room.unclearStreak = 0;
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-escalate',
        role: ChatMessageRole.system,
        text:
            'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด',
        requiresAdmin: true,
      ));
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    if (room.unclearStreak < 1) {
      room.messages.add(ChatMessage(
        id: '${userMsg.id}-soft',
        role: ChatMessageRole.ai,
        text:
            'ยังไม่แน่ใจคำถามครับ ลองระบุทำlez · งบ · หรือรายละเอียดที่ต้องการเพิ่ม\n'
            'หรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เมื่อต้องการให้ทีมช่วยโดยตรง',
      ));
      room.unclearStreak++;
      room.updatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    room.adminEscalated = true;
    room.unclearStreak = 0;
    room.messages.add(ChatMessage(
      id: '${userMsg.id}-escalate',
      role: ChatMessageRole.system,
      text:
          'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด',
      requiresAdmin: true,
    ));
    room.updatedAt = DateTime.now();
    notifyListeners();
  }

  bool _isExplicitStaffRequest(String text) {
    final q = text.toLowerCase();
    const keys = [
      'ขอคุยกับแอดมิน',
      'ขอคุยกับเจ้าหน้าที่',
      'คุยกับเจ้าหน้าที่',
      'ติดต่อเจ้าหน้าที่',
      'ขอเจ้าหน้าที่',
    ];
    return keys.any((k) => q.contains(k));
  }

  bool _isDiscoveryIntent(String text) {
    final q = text.toLowerCase();
    const keys = [
      'หา', 'แนะนำ', 'ค้นห', 'อยาก', 'โครงการ', 'คอนโด', 'บ้าน',
      'bts', 'mrt', 'ใกล้', 'งบ', 'เช่า', 'ซื้อ', 'ห้องอื่น', 'ตัวอื่น',
      'find', 'search', 'recommend', 'condo', 'rent', 'buy', 'budget', 'near',
      'project', 'looking', 'other unit',
    ];
    if (keys.any((k) => q.contains(k))) return true;
    return RegExp(r'\d[\d,]*').hasMatch(q);
  }

  bool _isGenericFaqFallback(String text) =>
      text.startsWith(_copy.chatAiGenericAck);

  bool _isAutoStaffAck(String text) =>
      text.startsWith('รับข้อความแล้ว') ||
      text.startsWith('Message received');

  bool _isViewingDetailNotice(String text) =>
      text.startsWith('รายละเอียดนัดดู') ||
      text.startsWith('Viewing details');

  String _viewingFromSummary(Map<String, String> summary) {
    for (final e in summary.entries) {
      if (e.key.contains('นัดดู') || e.key.contains('Viewing')) return e.value;
    }
    return '-';
  }

  Future<ListingPublic?> _findListingByCode(String text) async {
    final match = RegExp(r'\b[A-Z]{2,}(?:-[A-Z0-9]+)+\b').firstMatch(text.toUpperCase());
    if (match == null) return null;
    final code = match.group(0)!;
    final listings = await _allListings();
    for (final l in listings) {
      if (l.listingCode.toUpperCase() == code) return l;
    }
    return null;
  }

  Future<ChatMessage> _discoveryReply(String text, ChatRoom room) async {
    final listings = await _allListings();
    var pool = listings;
    final project = room.projectName;
    final q = text.toLowerCase();
    if (project != null &&
        project.isNotEmpty &&
        (q.contains('ห้องอื่น') ||
            q.contains('ในโครงการ') ||
            q.contains('other unit') ||
            q.contains('in project'))) {
      pool = listings.where((l) => l.projectName == project).toList();
    }
    return _aiSupportReplyFromListings(text, pool);
  }

  ChatRoom _memoryEnsureSeekerHub(String userId) {
    final id = ChatServiceIds.seekerHub(userId);
    final cached = _rooms[id];
    if (cached != null) return cached;
    final room = ChatRoom(
      id: id,
      listingId: id,
      listingCode: 'HUB-SEEKER',
      listingTitle: _copy.hubSeekerTitle,
      roomKind: 'seeker_hub',
      category: 'participant_hub',
    );
    _registerRoom(room);
    _myThreadIds.add(id);
    notifyListeners();
    return room;
  }

  ChatRoom _memoryEnsureAgentHub(String userId) {
    final id = ChatServiceIds.agentHub(userId);
    final cached = _rooms[id];
    if (cached != null) return cached;
    final room = ChatRoom(
      id: id,
      listingId: id,
      listingCode: 'HUB-AGENT',
      listingTitle: _copy.hubAgentTitle,
      roomKind: 'agent_hub',
      category: 'participant_hub',
    );
    _registerRoom(room);
    _myThreadIds.add(id);
    notifyListeners();
    return room;
  }

  Future<void> _postHubViewingRecap({
    required ViewingRequest viewingRequest,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required String scheduleLabel,
    required String propertyLabel,
  }) async {
    final hub = await ensureParticipantHub();
    final links = <ChatMessageLink>[
      ChatMessageLink.profileTag(clientTag.code, clientTag.displayLabel),
      ChatMessageLink.viewingRequest(viewingRequest.code, viewingRequest.code),
    ];
    if (presenterTag != null) {
      links.insert(
        0,
        ChatMessageLink.profileTag(presenterTag.code, presenterTag.displayLabel),
      );
    }
    hub.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-hub-recap',
      role: ChatMessageRole.system,
      text: _copy.hubViewingRecap(
        propertyLabel: propertyLabel,
        schedule: scheduleLabel,
        clientCode: clientTag.code,
        viewingCode: viewingRequest.code,
        presenterCode: presenterTag?.code,
      ),
      links: links,
    ));
    hub.updatedAt = DateTime.now();
    notifyListeners();
  }

  void _memorySubmitViewingWithTags(
    ChatRoom room, {
    required ViewingRequest viewingRequest,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required String scheduleLabel,
    required Map<String, String> leadSummary,
  }) {
    final viewing = scheduleLabel;
    final links = <ChatMessageLink>[
      ChatMessageLink.profileTag(clientTag.code, clientTag.displayLabel),
      ChatMessageLink.viewingRequest(viewingRequest.code, viewingRequest.code),
    ];
    if (presenterTag != null) {
      links.add(ChatMessageLink.profileTag(presenterTag.code, presenterTag.displayLabel));
    }

    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-received',
      role: ChatMessageRole.system,
      text: '${_copy.chatViewingReceived}\n${_copy.viewingRefNote(room.effectiveTransactionRef, viewingRequest.code)}',
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-tag-recap',
      role: ChatMessageRole.system,
      text: _copy.viewingTagRecap(
        schedule: scheduleLabel,
        clientCode: clientTag.code,
        viewingCode: viewingRequest.code,
        presenterCode: presenterTag?.code,
      ),
      links: links,
    ));
    final lines = leadSummary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-summary',
      role: ChatMessageRole.system,
      text: '${_copy.chatCustomerSummaryHeader}\n$lines',
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-viewing',
      role: ChatMessageRole.adminNotice,
      text: _copy.chatViewingDetailAck(viewing),
    ));
    room.viewingSubmitted = true;
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.category = 'viewing_request';
    room.status = 'waiting_admin';
    room.priority = 'high';
    room.updatedAt = DateTime.now();
    notifyListeners();
  }

  void _memoryAppendViewingSummary(
    ChatRoom room,
    Map<String, String> summary, {
    bool duplicatePhoneSuffix = false,
  }) {
    final viewing = _viewingFromSummary(summary);
    final lines = summary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');

    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-received',
      role: ChatMessageRole.system,
      text: '${_copy.chatViewingReceived}\n${_copy.viewingRefNote(room.effectiveTransactionRef, null)}',
    ));
    if (duplicatePhoneSuffix) {
      room.messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-dup',
        role: ChatMessageRole.adminNotice,
        text: _copy.chatDuplicatePhoneAlert,
      ));
    }
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-summary',
      role: ChatMessageRole.system,
      text: '${_copy.chatCustomerSummaryHeader}\n$lines',
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-viewing',
      role: ChatMessageRole.adminNotice,
      text: _copy.chatViewingDetailAck(viewing),
    ));
    room.viewingSubmitted = true;
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.category = 'viewing_request';
    room.status = 'waiting_admin';
    room.priority = 'high';
    room.updatedAt = DateTime.now();
    notifyListeners();
  }

  ChatRoom _memoryRecordDemandOffer({
    required Map<String, String> summary,
    required String demandPostCode,
    String? demandPostTitle,
    String? transactionRef,
  }) {
    const id = ChatServiceIds.demandOffer;
    final title = demandPostTitle != null
        ? '${_copy.chatDemandOfferRoomTitle} · $demandPostTitle'
        : _copy.chatDemandOfferRoomTitle;
    final txn = transactionRef ?? ReferenceCodes.demoChatRef(id);

    var room = _rooms[id];
    if (room == null) {
      room = ChatRoom(
        id: id,
        listingId: id,
        listingCode: demandPostCode,
        listingTitle: title,
        transactionRef: txn,
        roomKind: 'staff_support',
        category: 'demand_offer',
        adminEscalated: true,
        status: 'waiting_admin',
        messages: [
          ChatMessage(
            id: 'welcome-$id',
            role: ChatMessageRole.adminNotice,
            text: _copy.chatDemandOfferWelcome,
          ),
        ],
      );
      _rooms[id] = room;
    }

    final lines = summary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-user',
      role: ChatMessageRole.user,
      text: _copy.chatDemandOfferUserSent(demandPostCode),
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-sys',
      role: ChatMessageRole.system,
      text: _copy.offerSubmittedBody,
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-sum',
      role: ChatMessageRole.system,
      text: '${_copy.offerSubmittedSummaryTitle}\n$lines',
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-ack',
      role: ChatMessageRole.adminNotice,
      text: _copy.chatDemandOfferStaffAck,
    ));
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.status = 'waiting_admin';
    room.updatedAt = DateTime.now();
    notifyListeners();
    return room;
  }

  ChatRoom _memoryRecordRequirement(
    CustomerRequirement req, {
    required Map<String, String> summary,
    required String roomId,
    required String title,
  }) {
    final room = ChatRoom(
      id: roomId,
      listingId: roomId,
      listingCode: 'REQ-${req.id}',
      listingTitle: _copy.chatRequirementRoomTitle,
      transactionRef: ReferenceCodes.demoChatRef(roomId),
      roomKind: 'staff_support',
      category: 'customer_requirement',
      adminEscalated: true,
      status: 'waiting_admin',
      messages: [
        ChatMessage(
          id: 'welcome-$roomId',
          role: ChatMessageRole.adminNotice,
          text: _copy.chatRequirementWelcome,
        ),
      ],
    );

    final lines = summary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-user',
      role: ChatMessageRole.user,
      text: _copy.chatRequirementUserSent(title),
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-sys',
      role: ChatMessageRole.system,
      text: _copy.chatRequirementReceived,
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-sum',
      role: ChatMessageRole.system,
      text: '${_copy.chatRequirementSummaryHeader}\n$lines',
    ));
    room.messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-ack',
      role: ChatMessageRole.adminNotice,
      text: _copy.chatRequirementStaffAck,
    ));
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.status = 'waiting_admin';
    room.updatedAt = DateTime.now();
    _rooms[roomId] = room;
    notifyListeners();
    return room;
  }

  bool _isSensitive(String text) {
    final q = text.toLowerCase();
    const keys = [
      'ทิศ', 'ต่อรอง', 'ลดราคา', 'เจ้าของ', 'โทร', 'line', 'ไลน์',
      'เลขห้อง', 'commission', 'คอม',
      'owner', 'phone', 'call', 'negotiat', 'discount', 'unit no',
    ];
    return keys.any((k) => q.contains(k));
  }

  Future<List<ListingPublic>> _allListings() async {
    if (_listingCache != null && _listingCache!.isNotEmpty) return _listingCache!;
    try {
      _listingCache = await _listingRepo.fetchPublished();
    } catch (_) {
      _listingCache = DemoListingsFactory.cached;
    }
    if (_listingCache!.isEmpty) _listingCache = DemoListingsFactory.cached;
    return _listingCache!;
  }

  Future<ChatMessage> _aiSupportReplyFromListings(
    String text,
    List<ListingPublic> listings,
  ) async {
    final q = text.toLowerCase();
    final rent = q.contains('ซื้อ') ||
        q.contains('sale') ||
        q.contains('buy')
        ? false
        : true;
    final budget = _extractBudget(q);

    var matched = listings.where((l) {
      if (rent && l.listingType != 'rent') return false;
      if (!rent &&
          l.listingType != 'sale' &&
          l.listingType != 'sale_installment') {
        return false;
      }
      if (budget != null && l.priceNet > budget * 1.15) return false;
      return _textMatchesListing(q, l);
    }).toList();

    if (matched.isEmpty && budget != null) {
      matched = listings
          .where((l) => rent
              ? l.listingType == 'rent'
              : l.listingType == 'sale' || l.listingType == 'sale_installment')
          .where((l) => l.priceNet <= budget * 1.2)
          .toList()
        ..sort((a, b) => a.priceNet.compareTo(b.priceNet));
    }

    matched = matched.take(3).toList();

    if (matched.isEmpty) {
      return ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-ai',
        role: ChatMessageRole.ai,
        text: _copy.chatNoMatches,
      );
    }

    final links = <ChatMessageLink>[];
    for (final l in matched) {
      links.add(ChatMessageLink(
        label: '${l.listingCode} · ${_copy.priceLabelChat(l)}',
        kind: ChatMessageLinkKind.listing,
        listingId: l.id,
        projectName: l.localizedProjectName(_copy.isEnglish) ?? l.projectName,
      ));
    }

    final project = matched.first.localizedProjectName(_copy.isEnglish) ??
        matched.first.projectName;
    if (project != null && project.isNotEmpty) {
      final inProject = listings
          .where((l) =>
              l.projectName == matched.first.projectName ||
              l.projectNameEn == matched.first.projectNameEn)
          .length;
      if (inProject > 1) {
        links.add(ChatMessageLink(
          label: _copy.seeProjectUnits(inProject, project),
          kind: ChatMessageLinkKind.projectUnits,
          listingId: matched.first.id,
          projectName: matched.first.projectName,
        ));
      }
    }

    final names = matched
        .map((l) => l.localizedProjectName(_copy.isEnglish) ?? l.localizedTitle(_copy.isEnglish))
        .join(', ');
    return ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-ai',
      role: ChatMessageRole.ai,
      text: _copy.chatMatchesFound(names),
      links: links,
    );
  }

  String _propertyAiReply(String text, ChatRoom room) {
    final q = text.toLowerCase();
    if (q.contains('ราคา') ||
        q.contains('เท่าไร') ||
        q.contains('งบ') ||
        q.contains('price') ||
        q.contains('cost') ||
        q.contains('budget')) {
      return _copy.chatAiPriceReply(room.listingCode);
    }
    if (q.contains('สัตว') ||
        q.contains('เลี้ยง') ||
        q.contains('pet')) {
      return _copy.chatAiPetReply;
    }
    if (q.contains('จอด') ||
        q.contains('รถ') ||
        q.contains('park') ||
        q.contains('car')) {
      return _copy.chatAiParkingReply;
    }
    if (q.contains('bts') ||
        q.contains('mrt') ||
        q.contains('ทำเล') ||
        q.contains('location') ||
        q.contains('area')) {
      return _copy.chatAiLocationReply;
    }
    return _copy.chatAiGenericFallback();
  }

  bool _textMatchesListing(String q, ListingPublic l) {
    final hay = [
      l.title,
      l.projectName,
      l.district,
      l.geoZoneSlug,
      l.listingCode,
    ].whereType<String>().join(' ').toLowerCase();

    const zones = {
      'ทองหล่อ': ['thong', 'thonglor', 'ทองหล่อ'],
      'เอกมัย': ['ekkamai', 'เอกมัย'],
      'อโศก': ['asok', 'อโศก'],
      'สุขุมวิท': ['sukhumvit', 'สุขุมวิท'],
      'สาทร': ['sathorn', 'สาทร'],
      'สีลม': ['silom', 'สีลม'],
      'พระโขนง': ['phra', 'พระโขนง'],
      'อารีย์': ['ari', 'อารีย์'],
      'ลาดพร้าว': ['lat', 'ลาดพร้าว'],
    };

    for (final entry in zones.entries) {
      if (q.contains(entry.key) || entry.value.any((v) => q.contains(v))) {
        if (hay.contains(entry.key) ||
            entry.value.any((v) => hay.contains(v))) {
          return true;
        }
      }
    }

    if (q.contains('คอนโด') && l.propertyType == 'condo') return true;
    if (q.contains('บ้าน') && l.propertyType != 'condo') return true;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2);
    return tokens.any((t) => hay.contains(t));
  }

  double? _extractBudget(String q) {
    final m = RegExp(r'(\d[\d,]*)\s*(?:บาท|k|K)?').firstMatch(q);
    if (m == null) return null;
    var raw = m.group(1)!.replaceAll(',', '');
    var v = double.tryParse(raw);
    if (v == null) return null;
    if (q.contains('k') && v < 1000) v *= 1000;
    if (v < 500) v *= 1000;
    return v;
  }
}
