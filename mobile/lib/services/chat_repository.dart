import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/listing_ids.dart';
import '../models/admin_chat_ops.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'supabase_service.dart';

class ChatRepository {
  Future<ChatRoom> openThread({
    String? threadId,
    required String roomKind,
    String? listingId,
    String? listingCode,
    String? listingTitle,
    String? projectName,
    bool allowViewingRequest = false,
    String? welcomeText,
  }) async {
    final client = SupabaseService.client!;
    final payload = {
      if (threadId != null) 'thread_id': threadId,
      'room_kind': roomKind,
      if (listingIdForBackend(listingId) != null)
        'listing_id': listingIdForBackend(listingId),
      if (listingCode != null) 'listing_code': listingCode,
      'listing_title': listingTitle ?? '',
      if (projectName != null) 'project_name': projectName,
      'allow_viewing_request': allowViewingRequest,
      if (welcomeText != null) 'welcome_text': welcomeText,
    };

    final res = await client.functions.invoke('chat-open-thread', body: payload);
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-open-thread failed');
    }
    return _roomFromPayload(data);
  }

  Future<List<ChatRoom>> fetchMyThreads() async {
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return [];

    final threads = await client
        .from('chat_threads')
        .select('*')
        .eq('user_id', uid)
        .order('last_message_at', ascending: false);

    return _roomsWithMessages(threads as List);
  }

  Future<List<ChatRoom>> fetchAdminInbox({bool includeResolved = false}) async {
    final client = SupabaseService.client!;

    List<dynamic> rows;
    if (includeResolved) {
      rows = await client
          .from('chat_threads')
          .select('*')
          .or(
            'status.eq.waiting_admin,viewing_submitted.eq.true,admin_escalated.eq.true,'
            'category.in.(staff_support,escalation,viewing_request,booking_interest)',
          )
          .order('priority', ascending: false)
          .order('last_message_at', ascending: false)
          .limit(100);
    } else {
      // ใช้ view ที่กรองเฉพาะห้องที่มีข้อความลูกค้า + ต้องการทีมงาน
      rows = await client
          .from('chat_admin_inbox')
          .select('*')
          .order('priority', ascending: false)
          .order('last_message_at', ascending: false)
          .limit(100);
    }

    return _roomsWithMessages(rows as List, inboxPreview: true);
  }

  Future<ChatRoom?> fetchThreadById(String threadId) async {
    if (threadId.startsWith('demo-') || threadId.startsWith('cast-chat-')) {
      return null;
    }
    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;
    final thread = await client
        .from('chat_threads')
        .select('*')
        .eq('id', threadId)
        .maybeSingle();
    if (thread == null) return null;

    final messages = await _fetchMessages(threadId);
    return ChatRoom.fromThreadJson(
      Map<String, dynamic>.from(thread),
      messages,
    );
  }

  Future<void> sendUserMessage(ChatRoom room, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (await isHumanHandoffThread(room.id)) {
      await _sendUserMessageHumanOnly(room, trimmed);
      return;
    }

    final client = SupabaseService.client!;
    final payload = {
      'thread_id': room.id,
      'room_kind': room.roomKind ?? 'property',
      'listing_id': null,
      'listing_code': room.listingCode,
      'listing_title': room.listingTitle,
      if (room.projectName != null) 'project_name': room.projectName,
      'allow_viewing_request': room.allowViewingRequest,
      'force_admin_handoff': room.isPropertyListing,
      'text': trimmed,
    };

    final res = await client.functions.invoke('chat-turn', body: payload);
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-turn failed');
    }
    _mergeTurnResponse(room, data);
  }

  Future<ChatRoom> recordRequirement({
    required String requirementId,
    required Map<String, String> summary,
    required String title,
  }) async {
    final client = SupabaseService.client!;
    final res = await client.functions.invoke(
      'chat-record-requirement',
      body: {
        'requirement_id': requirementId,
        'summary': summary,
        'title': title,
      },
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-record-requirement failed');
    }
    return _roomFromPayload(data);
  }

  Future<void> sendAdminReply(
    ChatRoom room,
    String text, {
    bool resolve = false,
    List<Map<String, dynamic>> links = const [],
  }) async {
    final client = SupabaseService.client!;
    try {
      final res = await client.functions.invoke(
        'chat-admin-reply',
        body: {
          'thread_id': room.id,
          'text': text,
          'resolve': resolve,
          if (links.isNotEmpty) 'links': links,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'chat-admin-reply failed');
      }

      final msg = data['message'];
      if (msg is Map) {
        room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(msg)));
      }
      final thread = data['thread'];
      if (thread is Map) {
        _applyThreadPatch(room, Map<String, dynamic>.from(thread));
      }
      room.adminReplyDone = resolve;
      room.updatedAt = DateTime.now();
    } catch (_) {
      await _sendAdminReplyDirect(
        room,
        text,
        resolve: resolve,
        links: links,
      );
    }
  }

  Future<void> _sendAdminReplyDirect(
    ChatRoom room,
    String text, {
    bool resolve = false,
    List<Map<String, dynamic>> links = const [],
  }) async {
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser!.id;
    final row = await client
        .from('chat_messages')
        .insert({
          'thread_id': room.id,
          'role': 'admin_notice',
          'text': text.trim(),
          'links': links,
          'sender_id': uid,
        })
        .select('*')
        .single();
    room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(row)));
    final patch = <String, dynamic>{
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      if (resolve) ...{
        'status': 'resolved',
        'admin_reply_done': true,
        'admin_escalated': false,
      },
    };
    final updated = await client
        .from('chat_threads')
        .update(patch)
        .eq('id', room.id)
        .select('*')
        .single();
    _applyThreadPatch(room, Map<String, dynamic>.from(updated));
    if (resolve) {
      room.adminReplyDone = true;
      room.adminEscalated = false;
      room.status = 'resolved';
    }
    room.updatedAt = DateTime.now();
  }

  Future<void> updateAdminDisplayName(String threadId, String? name) async {
    final client = SupabaseService.client;
    if (client == null) return;
    await client.from('chat_threads').update({
      'admin_display_name': name,
    }).eq('id', threadId);
  }

  Future<void> markResolved(ChatRoom room) async {
    final client = SupabaseService.client!;
    await client.from('chat_threads').update({
      'status': 'resolved',
      'admin_escalated': false,
      'admin_reply_done': true,
    }).eq('id', room.id);
    room.adminEscalated = false;
    room.adminReplyDone = true;
    room.status = 'resolved';
    room.updatedAt = DateTime.now();
  }

  Future<ChatRoom> claimThread(String threadId) async {
    final client = SupabaseService.client!;
    try {
      final res = await client.functions.invoke(
        'chat-claim',
        body: {'thread_id': threadId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'chat-claim failed');
      }
      final thread = data['thread'];
      if (thread is! Map) throw Exception('invalid claim response');
      return ChatRoom.fromThreadJson(
        Map<String, dynamic>.from(thread),
        await _fetchMessages(threadId),
      );
    } catch (_) {
      return _claimThreadDirect(threadId);
    }
  }

  Future<ChatRoom> assignThread(String threadId, String assigneeId) async {
    final client = SupabaseService.client!;
    try {
      final res = await client.functions.invoke(
        'chat-assign',
        body: {'thread_id': threadId, 'assignee_id': assigneeId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'chat-assign failed');
      }
      final thread = data['thread'];
      if (thread is! Map) throw Exception('invalid assign response');
      return ChatRoom.fromThreadJson(
        Map<String, dynamic>.from(thread),
        await _fetchMessages(threadId),
      );
    } catch (_) {
      return _assignThreadDirect(threadId, assigneeId);
    }
  }

  Future<ChatRoom> _claimThreadDirect(String threadId) async {
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser!.id;
    final row = await client
        .from('chat_threads')
        .select('*')
        .eq('id', threadId)
        .single();
    final thread = Map<String, dynamic>.from(row);
    final existing = thread['assigned_admin_id']?.toString();
    if (existing != null &&
        existing.isNotEmpty &&
        existing != uid) {
      throw Exception('มีคนรับงานแล้ว');
    }
    if (existing == uid) {
      return ChatRoom.fromThreadJson(thread, await _fetchMessages(threadId));
    }
    final updated = await client
        .from('chat_threads')
        .update({
          'assigned_admin_id': uid,
          'assigned_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', threadId)
        .select('*')
        .single();
    return ChatRoom.fromThreadJson(
      Map<String, dynamic>.from(updated),
      await _fetchMessages(threadId),
    );
  }

  Future<ChatRoom> _assignThreadDirect(
    String threadId,
    String assigneeId,
  ) async {
    final client = SupabaseService.client!;
    final updated = await client
        .from('chat_threads')
        .update({
          'assigned_admin_id': assigneeId,
          'assigned_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', threadId)
        .select('*')
        .single();
    return ChatRoom.fromThreadJson(
      Map<String, dynamic>.from(updated),
      await _fetchMessages(threadId),
    );
  }

  Future<String?> fetchAdminDisplayName(String? adminId) async {
    if (adminId == null || adminId.isEmpty || !SupabaseService.isReady) {
      return null;
    }
    final row = await SupabaseService.client!
        .from('profiles')
        .select('display_name')
        .eq('id', adminId)
        .maybeSingle();
    return row?['display_name'] as String?;
  }

  Future<List<AdminPeer>> fetchTeamAdmins() async {
    final client = SupabaseService.client!;
    final rows = await client
        .from('profiles')
        .select('id, display_name')
        .eq('role', 'admin')
        .eq('is_active', true)
        .order('display_name');
    return (rows as List)
        .whereType<Map>()
        .map(
          (r) => AdminPeer(
            id: r['id']?.toString() ?? '',
            displayName: (r['display_name']?.toString().trim().isNotEmpty ?? false)
                ? r['display_name'].toString()
                : 'Admin',
          ),
        )
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<List<ChatRoom>> fetchAdminResolved() async {
    final client = SupabaseService.client!;
    final cutoff = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
    final rows = await client
        .from('chat_threads')
        .select('*')
        .eq('status', 'resolved')
        .gte('last_message_at', cutoff)
        .order('last_message_at', ascending: false)
        .limit(50);
    return _roomsWithMessages(rows as List, inboxPreview: true);
  }

  /// เคสที่รับงานแล้วแต่ยังไม่ปิด — ไม่อยู่ใน chat_admin_inbox หลังตอบครั้งแรก
  Future<List<ChatRoom>> fetchAdminOpenAssigned() async {
    final client = SupabaseService.client!;
    final cutoff = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
    final rows = await client
        .from('chat_threads')
        .select('*')
        .neq('status', 'resolved')
        .not('assigned_admin_id', 'is', null)
        .gte('last_message_at', cutoff)
        .order('last_message_at', ascending: false)
        .limit(100);
    return _roomsWithMessages(rows as List, inboxPreview: true);
  }

  Future<ChatRoom> recordDemandOffer({
    required Map<String, String> summary,
    required String demandPostCode,
    String? demandPostTitle,
  }) async {
    final client = SupabaseService.client!;
    final res = await client.functions.invoke(
      'chat-record-demand-offer',
      body: {
        'summary': summary,
        'demand_post_code': demandPostCode,
        if (demandPostTitle != null) 'demand_post_title': demandPostTitle,
      },
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-record-demand-offer failed');
    }
    return _roomFromPayload(data);
  }

  Future<void> recordViewing(
    ChatRoom room,
    Map<String, String> summary, {
    bool duplicatePhoneSuffix = false,
  }) async {
    final client = SupabaseService.client!;
    final res = await client.functions.invoke(
      'chat-record-viewing',
      body: {
        'thread_id': room.id,
        'summary': summary,
        'duplicate_phone_suffix': duplicatePhoneSuffix,
      },
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-record-viewing failed');
    }
    _applyViewingPayload(room, data);
  }

  void _applyViewingPayload(ChatRoom room, Map<String, dynamic> data) {
    final messages = data['messages'];
    if (messages is List) {
      for (final m in messages) {
        if (m is Map) {
          final parsed =
              ChatMessage.fromJson(Map<String, dynamic>.from(m));
          if (!room.messages.any((x) => x.id == parsed.id)) {
            room.messages.add(parsed);
          }
        }
      }
    }
    final thread = data['thread'];
    if (thread is Map) {
      _applyThreadPatch(room, Map<String, dynamic>.from(thread));
    }
    room.viewingSubmitted = true;
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.category = 'viewing_request';
    room.status = 'waiting_admin';
    room.priority = 'high';
    room.updatedAt = DateTime.now();
  }

  /// หาแชทที่ผูกกับ Lead (thread_id หรือ listing_code + seeker)
  Future<String?> resolveThreadIdForLead(Map<String, dynamic> lead) async {
    final direct = lead['thread_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final leadId = lead['id']?.toString();
    if (leadId != null && leadId.startsWith('demo-lead')) {
      return 'demo-lead-chat-$leadId';
    }

    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;
    final code = lead['listing_code']?.toString();
    var seekerId = lead['seeker_id']?.toString();

    if ((seekerId == null || seekerId.isEmpty) && leadId != null && leadId.isNotEmpty) {
      try {
        final row = await client
            .from('leads')
            .select('seeker_id, thread_id, listing_code')
            .eq('id', leadId)
            .maybeSingle();
        seekerId = row?['seeker_id']?.toString() ?? seekerId;
        final tid = row?['thread_id']?.toString();
        if (tid != null && tid.isNotEmpty) return tid;
      } catch (_) {}
    }

    if (code == null || code.isEmpty || seekerId == null || seekerId.isEmpty) {
      return null;
    }

    final row = await client
        .from('chat_threads')
        .select('id')
        .eq('listing_code', code)
        .eq('user_id', seekerId)
        .order('last_message_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id']?.toString();
  }

  /// แชทลูกค้าจริงสำหรับ Lead — ไม่สร้างห้องของแอดมิน
  Future<ChatRoom?> fetchCustomerThreadForLead({
    Map<String, dynamic>? lead,
    String? leadId,
    String? listingCode,
    String? seekerPhone,
  }) async {
    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;

    Map<String, dynamic>? resolved = lead;
    if (resolved == null && leadId != null && leadId.isNotEmpty) {
      try {
        resolved = await client
            .from('leads')
            .select()
            .eq('id', leadId)
            .maybeSingle();
      } catch (_) {}
    }

    if (resolved != null) {
      final threadId = await resolveThreadIdForLead(resolved);
      if (threadId != null && threadId.isNotEmpty) {
        return fetchThreadById(threadId);
      }
    }

    final code = listingCode?.trim().isNotEmpty == true
        ? listingCode!.trim()
        : resolved?['listing_code']?.toString();
    var seekerId = resolved?['seeker_id']?.toString();
    final phone = seekerPhone?.trim().isNotEmpty == true
        ? seekerPhone!.trim()
        : resolved?['seeker_phone']?.toString();

    if ((seekerId == null || seekerId.isEmpty) &&
        phone != null &&
        phone.isNotEmpty &&
        code != null &&
        code.isNotEmpty) {
      try {
        final row = await client
            .from('leads')
            .select('seeker_id, thread_id')
            .eq('listing_code', code)
            .eq('seeker_phone', phone)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        seekerId = row?['seeker_id']?.toString() ?? seekerId;
        final tid = row?['thread_id']?.toString();
        if (tid != null && tid.isNotEmpty) {
          return fetchThreadById(tid);
        }
      } catch (_) {}
    }

    if (code != null && code.isNotEmpty && seekerId != null && seekerId.isNotEmpty) {
      try {
        final row = await client
            .from('chat_threads')
            .select('id')
            .eq('listing_code', code)
            .eq('user_id', seekerId)
            .order('last_message_at', ascending: false)
            .limit(1)
            .maybeSingle();
        final tid = row?['id']?.toString();
        if (tid != null && tid.isNotEmpty) {
          return fetchThreadById(tid);
        }
      } catch (_) {}
    }

    if (code != null && code.isNotEmpty) {
      try {
        final rows = await client
            .from('chat_threads')
            .select('id')
            .eq('listing_code', code)
            .eq('viewing_submitted', true)
            .order('last_message_at', ascending: false)
            .limit(1);
        if (rows is List && rows.isNotEmpty) {
          final tid = rows.first['id']?.toString();
          if (tid != null && tid.isNotEmpty) {
            return fetchThreadById(tid);
          }
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> recordBookingInterest(
    ChatRoom room,
    Map<String, String> summary,
  ) async {
    final client = SupabaseService.client!;
    final res = await client.functions.invoke(
      'chat-record-booking-interest',
      body: {
        'thread_id': room.id,
        'summary': summary,
      },
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-record-booking-interest failed');
    }

    final messages = data['messages'];
    if (messages is List) {
      for (final m in messages) {
        if (m is Map) {
          room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }
    final thread = data['thread'];
    if (thread is Map) {
      _applyThreadPatch(room, Map<String, dynamic>.from(thread));
    }
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.category = 'booking_interest';
    room.status = 'waiting_admin';
    room.priority = 'high';
    room.updatedAt = DateTime.now();
  }

  RealtimeChannel subscribeThread(
    String threadId,
    void Function(ChatMessage message) onMessage, {
    void Function(Map<String, dynamic> thread)? onThreadUpdate,
  }) {
    final client = SupabaseService.client!;
    final channel = client.channel('chat-thread-$threadId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'thread_id',
        value: threadId,
      ),
      callback: (payload) {
        final record = payload.newRecord;
        onMessage(ChatMessage.fromJson(Map<String, dynamic>.from(record)));
      },
    );
    if (onThreadUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'chat_threads',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: threadId,
        ),
        callback: (payload) {
          onThreadUpdate(Map<String, dynamic>.from(payload.newRecord));
        },
      );
    }
    channel.subscribe();
    return channel;
  }

  Future<bool> isHumanHandoffThread(String threadId) async {
    final client = SupabaseService.client!;
    final row = await client
        .from('chat_threads')
        .select('assigned_admin_id, admin_reply_done')
        .eq('id', threadId)
        .maybeSingle();
    if (row == null) return false;
    final aid = row['assigned_admin_id']?.toString();
    return aid != null &&
        aid.isNotEmpty &&
        row['admin_reply_done'] != true;
  }

  Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel == null || !SupabaseService.isReady) return;
    await SupabaseService.client!.removeChannel(channel);
  }

  ChatRoom _roomFromPayload(Map<String, dynamic> data) {
    final thread = Map<String, dynamic>.from(data['thread'] as Map);
    final rawMessages = data['messages'] as List? ?? [];
    final messages = rawMessages
        .whereType<Map>()
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return ChatRoom.fromThreadJson(thread, messages);
  }

  Future<List<ChatMessage>> _fetchMessages(String threadId) async {
    final client = SupabaseService.client!;
    final rows = await client
        .from('chat_messages')
        .select('*')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (rows as List)
        .whereType<Map>()
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<ChatRoom>> _roomsWithMessages(
    List rows, {
    bool inboxPreview = false,
  }) async {
    final rooms = <ChatRoom>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final thread = Map<String, dynamic>.from(row);
      final id = thread['id']?.toString();
      if (id == null) continue;

      List<ChatMessage> messages;
      if (inboxPreview && thread['last_message_text'] != null) {
        messages = [
          ChatMessage(
            id: 'preview-$id',
            role: _roleFromString(thread['last_message_role']?.toString() ?? 'user'),
            text: thread['last_message_text']?.toString() ?? '',
            createdAt: thread['last_message_at'] != null
                ? DateTime.tryParse(thread['last_message_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
          ),
        ];
      } else {
        messages = await _fetchMessages(id);
      }

      rooms.add(ChatRoom.fromThreadJson(thread, messages));
    }
    return rooms;
  }

  ChatMessageRole _roleFromString(String raw) {
    switch (raw) {
      case 'ai':
        return ChatMessageRole.ai;
      case 'system':
        return ChatMessageRole.system;
      case 'admin_notice':
        return ChatMessageRole.adminNotice;
      default:
        return ChatMessageRole.user;
    }
  }

  void _mergeTurnResponse(ChatRoom room, Map<String, dynamic> data) {
    final userMsg = data['user_message'];
    if (userMsg is Map) {
      final parsed = ChatMessage.fromJson(Map<String, dynamic>.from(userMsg));
      if (!room.messages.any((m) => m.id == parsed.id)) {
        room.messages.add(parsed);
      }
    }
    final replies = data['replies'];
    if (replies is List) {
      for (final r in replies) {
        if (r is Map) {
          final parsed = ChatMessage.fromJson(Map<String, dynamic>.from(r));
          if (!room.messages.any((m) => m.id == parsed.id)) {
            room.messages.add(parsed);
          }
        }
      }
    }
    final thread = data['thread'];
    if (thread is Map) {
      _applyThreadPatch(room, Map<String, dynamic>.from(thread));
    }
    room.updatedAt = DateTime.now();
  }

  Future<void> _sendUserMessageHumanOnly(ChatRoom room, String text) async {
    if (text.isEmpty) return;
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser!.id;

    final userRow = await client
        .from('chat_messages')
        .insert({
          'thread_id': room.id,
          'role': 'user',
          'text': text,
          'sender_id': uid,
        })
        .select('*')
        .single();

    final userMsg =
        ChatMessage.fromJson(Map<String, dynamic>.from(userRow));
    if (!room.messages.any((m) => m.id == userMsg.id)) {
      room.messages.add(userMsg);
    }

    final updated = await client
        .from('chat_threads')
        .update({
          'admin_reply_done': false,
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', room.id)
        .select('*')
        .single();
    _applyThreadPatch(room, Map<String, dynamic>.from(updated));
    room.updatedAt = DateTime.now();
  }

  /// ส่งคำขอนัดดู (โปรไฟล์ไม่มีเบอร์/ไลน์เต็ม) ไปแชทเจ้าของ
  Future<void> notifyOwnerViewingRequest({
    required String ownerUserId,
    required String listingCode,
    required String messageText,
    required String leadId,
    String? listingId,
    String? listingTitle,
    String? projectName,
  }) async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client!;
    final adminId = client.auth.currentUser?.id;

    Map<String, dynamic>? threadRow;
    final backendListingId = listingIdForBackend(listingId);
    if (backendListingId != null) {
      threadRow = await client
          .from('chat_threads')
          .select('*')
          .eq('user_id', ownerUserId)
          .eq('listing_id', backendListingId)
          .maybeSingle();
    }
    if (threadRow == null) {
      threadRow = await client
          .from('chat_threads')
          .select('*')
          .eq('user_id', ownerUserId)
          .eq('listing_code', listingCode)
          .order('last_message_at', ascending: false)
          .limit(1)
          .maybeSingle();
    }

    late final String threadId;
    if (threadRow != null) {
      threadId = threadRow['id']?.toString() ?? '';
    } else {
      final created = await client
          .from('chat_threads')
          .insert({
            'user_id': ownerUserId,
            'room_kind': 'property',
            if (backendListingId != null) 'listing_id': backendListingId,
            'listing_code': listingCode,
            'listing_title': listingTitle ?? listingCode,
            if (projectName != null) 'project_name': projectName,
            'category': 'viewing_request',
            'status': 'waiting_admin',
            'priority': 'high',
            'admin_escalated': true,
            'admin_reply_done': false,
            'viewing_submitted': true,
          })
          .select('*')
          .single();
      threadId = created['id']?.toString() ?? '';
    }

    if (threadId.isEmpty) throw Exception('owner_thread_failed');

    await client.from('chat_messages').insert({
      'thread_id': threadId,
      'role': 'admin_notice',
      'text': messageText,
      if (adminId != null) 'sender_id': adminId,
      'requires_admin': false,
    });

    await client.from('chat_threads').update({
      'category': 'viewing_request',
      'status': 'waiting_admin',
      'viewing_submitted': true,
      'admin_escalated': true,
      'admin_reply_done': false,
      'priority': 'high',
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', threadId);

    try {
      await client.from('leads').update({
        'status': 'routed',
        'assigned_to': ownerUserId,
      }).eq('id', leadId);
    } catch (_) {}
  }

  void _applyThreadPatch(ChatRoom room, Map<String, dynamic> thread) {
    room.adminEscalated = thread['admin_escalated'] == true;
    room.viewingSubmitted = thread['viewing_submitted'] == true;
    room.allowViewingRequest = thread['allow_viewing_request'] == true;
    room.adminReplyDone = thread['admin_reply_done'] == true;
    if (thread['status'] != null) {
      room.status = thread['status']?.toString();
    }
    if (thread['category'] != null) {
      room.category = thread['category']?.toString();
    }
    if (thread['priority'] != null) {
      room.priority = thread['priority']?.toString();
    }
    if (thread.containsKey('assigned_admin_id')) {
      final aid = thread['assigned_admin_id']?.toString();
      room.assignedAdminId =
          aid != null && aid.isNotEmpty ? aid : null;
    }
    if (thread['assigned_admin_name'] != null) {
      room.assignedAdminName = thread['assigned_admin_name']?.toString();
    }
    if (thread['assigned_at'] != null) {
      room.assignedAt = DateTime.tryParse(thread['assigned_at'].toString());
    }
    if (thread['unclear_streak'] != null) {
      room.unclearStreak = (thread['unclear_streak'] as num).toInt();
    }
    if (thread['last_message_at'] != null) {
      room.updatedAt =
          DateTime.tryParse(thread['last_message_at'].toString()) ??
              room.updatedAt;
    }
  }

  /// แจ้งลูกค้าในแชท (ข้อความระบบ — ไม่ขึ้นคิวแอดมิน)
  Future<void> postCustomerSystemNotice({
    required ChatRoom room,
    required String text,
    List<ChatMessageLink> links = const [],
  }) async {
    if (!SupabaseService.isReady || text.trim().isEmpty) return;
    final client = SupabaseService.client!;
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'thread_id': room.id,
      'role': 'system',
      'text': text.trim(),
      'requires_admin': false,
    };
    if (links.isNotEmpty) {
      payload['links'] = links.map((l) => l.toJson()).toList();
    }
    final row = await client
        .from('chat_messages')
        .insert(payload)
        .select('*')
        .single();
    room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(row)));
    await client.from('chat_threads').update({
      'last_message_at': now,
    }).eq('id', room.id);
    room.updatedAt = DateTime.now();
  }

  /// ข้อความหลังนัดดู — โน้ตภายในแอดมิน + ข้อความระบบให้ลูกค้าเห็น
  Future<void> postViewingFollowUpNotice({
    required ChatRoom room,
    String? internalNoteText,
    String? systemNoticeText,
    required bool keepOpen,
  }) async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser?.id;
    final now = DateTime.now().toUtc().toIso8601String();

    if (internalNoteText != null && internalNoteText.trim().isNotEmpty) {
      final internal = await client
          .from('chat_messages')
          .insert({
            'thread_id': room.id,
            'role': 'admin_notice',
            'text': '${ChatMessage.adminInternalPrefix}${internalNoteText.trim()}',
            if (uid != null) 'sender_id': uid,
            'requires_admin': true,
          })
          .select('*')
          .single();
      room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(internal)));
    }

    if (keepOpen &&
        systemNoticeText != null &&
        systemNoticeText.trim().isNotEmpty) {
      final system = await client
          .from('chat_messages')
          .insert({
            'thread_id': room.id,
            'role': 'system',
            'text': systemNoticeText.trim(),
            'requires_admin': true,
          })
          .select('*')
          .single();
      room.messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(system)));
    }

    final patch = keepOpen
        ? {
            'status': 'waiting_admin',
            'admin_escalated': true,
            'admin_reply_done': false,
            'viewing_submitted': true,
            'category': 'viewing_request',
            'priority': 'high',
            'last_message_at': now,
          }
        : {
            'status': 'resolved',
            'admin_escalated': false,
            'admin_reply_done': true,
            'last_message_at': now,
          };

    final updated = await client
        .from('chat_threads')
        .update(patch)
        .eq('id', room.id)
        .select('*')
        .single();

    _applyThreadPatch(room, Map<String, dynamic>.from(updated));
    if (keepOpen) {
      room.adminReplyDone = false;
      room.adminEscalated = true;
      room.viewingSubmitted = true;
      room.category = 'viewing_request';
      room.status = 'waiting_admin';
      room.priority = 'high';
    } else {
      room.adminReplyDone = true;
      room.adminEscalated = false;
      room.status = 'resolved';
    }
    room.updatedAt = DateTime.now();
  }
}
