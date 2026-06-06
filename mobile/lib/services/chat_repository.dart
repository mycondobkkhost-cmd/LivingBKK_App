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
    };

    try {
      final res =
          await client.functions.invoke('chat-open-thread', body: payload);
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'chat-open-thread failed');
      }
      return _roomFromPayload(data);
    } catch (_) {
      return _openThreadDirect(
        threadId: threadId,
        roomKind: roomKind,
        listingId: listingId,
        listingCode: listingCode,
        listingTitle: listingTitle ?? '',
        projectName: projectName,
        allowViewingRequest: allowViewingRequest,
        welcomeText: welcomeText,
      );
    }
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

    // แชททรัพย์ — เข้าคิวแอดมินทันที (ไม่ให้ chat-turn ตอบ FAQ แทน)
    if (room.isPropertyListing) {
      await _sendUserMessageDirect(room, trimmed);
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
      'text': trimmed,
    };

    try {
      final res = await client.functions.invoke('chat-turn', body: payload);
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'chat-turn failed');
      }
      _mergeTurnResponse(room, data);
    } catch (_) {
      await _sendUserMessageDirect(room, trimmed);
    }
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
        .or('status.eq.resolved,admin_reply_done.eq.true')
        .gte('last_message_at', cutoff)
        .order('last_message_at', ascending: false)
        .limit(50);
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
    try {
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
    } catch (_) {
      await _recordViewingDirect(
        room,
        summary,
        duplicatePhoneSuffix: duplicatePhoneSuffix,
      );
    }
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

  Future<void> _recordViewingDirect(
    ChatRoom room,
    Map<String, String> summary, {
    bool duplicatePhoneSuffix = false,
  }) async {
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser!.id;

    final threadRow = await client
        .from('chat_threads')
        .select('*')
        .eq('id', room.id)
        .eq('user_id', uid)
        .maybeSingle();
    if (threadRow == null) {
      throw Exception('Thread not found');
    }
    final thread = Map<String, dynamic>.from(threadRow);
    final txnRef = thread['transaction_ref']?.toString();
    final viewing = summary['นัดดูทรัพย์'] ?? summary['Viewing'] ?? '-';
    final lines = summary.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');

    final inserts = <Map<String, dynamic>>[
      {
        'thread_id': room.id,
        'role': 'system',
        'text':
            'ระบบได้รับคำขอของคุณแล้ว\n'
            'ทีมงานจะติดต่อกลับหาคุณโดยเร็วที่สุด บางกรณีอาจเป็นการโทรติดต่อกลับ'
            '${txnRef != null && txnRef.isNotEmpty ? '\nเลขอ้างอิง: $txnRef' : ''}',
      },
    ];
    if (duplicatePhoneSuffix) {
      inserts.add({
        'thread_id': room.id,
        'role': 'admin_notice',
        'text':
            '⚠️ แจ้งทีมงาน: พบ 4 ตัวท้ายเบอร์ลูกค้าซ้ำในระบบ — รอตรวจสอบ',
      });
    }
    inserts.addAll([
      {
        'thread_id': room.id,
        'role': 'system',
        'text': 'สรุปโปรไฟล์ลูกค้า\n$lines',
      },
      {
        'thread_id': room.id,
        'role': 'admin_notice',
        'text':
            'รายละเอียดนัดดู: $viewing\n'
            'เจ้าหน้าที่จะยืนยันนัดและประสานงานให้ครับ',
      },
    ]);

    final rows = await client
        .from('chat_messages')
        .insert(inserts)
        .select('*');

    final messages = <ChatMessage>[];
    for (final row in rows as List) {
      if (row is Map) {
        messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(row)));
      }
    }

    final updated = await client
        .from('chat_threads')
        .update({
          'viewing_submitted': true,
          'admin_escalated': true,
          'admin_reply_done': false,
          'category': 'viewing_request',
          'status': 'waiting_admin',
          'priority': 'high',
        })
        .eq('id', room.id)
        .select('*')
        .single();

    _applyViewingPayload(room, {
      'thread': updated,
      'messages': messages.map((m) => {
            'id': m.id,
            'role': _roleToString(m.role),
            'text': m.text,
            'created_at': m.createdAt.toUtc().toIso8601String(),
            'requires_admin': m.requiresAdmin,
            'links': m.links.map((l) => l.toJson()).toList(),
          }),
    });
  }

  String _roleToString(ChatMessageRole role) {
    switch (role) {
      case ChatMessageRole.ai:
        return 'ai';
      case ChatMessageRole.system:
        return 'system';
      case ChatMessageRole.adminNotice:
        return 'admin_notice';
      case ChatMessageRole.user:
        return 'user';
    }
  }

  /// หาแชทที่ผูกกับ Lead (thread_id หรือ listing_code + seeker)
  Future<String?> resolveThreadIdForLead(Map<String, dynamic> lead) async {
    final direct = lead['thread_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;
    final code = lead['listing_code']?.toString();
    final seekerId = lead['seeker_id']?.toString();
    if (code == null || code.isEmpty || seekerId == null) return null;

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

  Future<String?> _resolveListingUuid(String? listingCode) async {
    if (listingCode == null || listingCode.isEmpty) return null;
    final client = SupabaseService.client!;
    final row = await client
        .from('listings')
        .select('id')
        .eq('listing_code', listingCode)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<ChatRoom> _openThreadDirect({
    String? threadId,
    required String roomKind,
    String? listingId,
    String? listingCode,
    required String listingTitle,
    String? projectName,
    bool allowViewingRequest = false,
    String? welcomeText,
  }) async {
    final client = SupabaseService.client!;
    final uid = client.auth.currentUser!.id;

    if (threadId != null) {
      final existing = await client
          .from('chat_threads')
          .select('*')
          .eq('id', threadId)
          .eq('user_id', uid)
          .maybeSingle();
      if (existing != null) {
        final messages = await _fetchMessages(threadId);
        return ChatRoom.fromThreadJson(
          Map<String, dynamic>.from(existing),
          messages,
        );
      }
    }

    var backendListingId = listingIdForBackend(listingId);
    backendListingId ??= await _resolveListingUuid(listingCode);
    final isDiscovery = roomKind == 'property' && backendListingId == null;

    var query = client.from('chat_threads').select('*').eq('user_id', uid);
    if (roomKind == 'property' && backendListingId != null) {
      query = query
          .eq('listing_id', backendListingId)
          .eq('room_kind', 'property');
    } else if (roomKind == 'property' && listingCode != null) {
      query = query.eq('listing_code', listingCode).eq('room_kind', 'property');
    } else {
      query = query.eq('room_kind', roomKind);
    }

    final existing = await query.maybeSingle();
    if (existing != null) {
      final id = existing['id']?.toString();
      final messages = id == null ? <ChatMessage>[] : await _fetchMessages(id);
      return ChatRoom.fromThreadJson(
        Map<String, dynamic>.from(existing),
        messages,
      );
    }

    final allowViewing = allowViewingRequest && !isDiscovery;
    var category = isDiscovery ? 'discovery' : 'property_faq';
    if (roomKind == 'staff_support') category = 'staff_support';

    final created = await client
        .from('chat_threads')
        .insert({
          'user_id': uid,
          'room_kind': roomKind,
          'listing_id': backendListingId,
          'listing_code': listingCode,
          'listing_title': listingTitle,
          'project_name': projectName,
          'category': category,
          'allow_viewing_request': allowViewing,
          'admin_escalated': roomKind == 'staff_support',
          'status': roomKind == 'staff_support' ? 'waiting_admin' : 'open',
        })
        .select('*')
        .single();

    final welcome = welcomeText ??
        (listingTitle.isNotEmpty
            ? 'สวัสดีครับ ผมผู้ช่วย PROPPITER สำหรับ $listingTitle\n'
                'ถามรายละเอียดทรัพย์นี้ได้เลย — หากต้องการนัดดูห้อง กด「ขอนัดดูห้อง」ด้านล่างเมื่อพร้อมครับ'
            : 'สวัสดีครับ ผมผู้ช่วย PROPPITER พร้อมช่วยเหลือครับ');

    final welcomeRole = roomKind == 'staff_support' ? 'admin_notice' : 'ai';
    await client.from('chat_messages').insert({
      'thread_id': created['id'],
      'role': welcomeRole,
      'text': welcome,
      'links': [],
    });

    final messages = await _fetchMessages(created['id']?.toString() ?? '');
    return ChatRoom.fromThreadJson(
      Map<String, dynamic>.from(created),
      messages,
    );
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

  Future<void> _sendUserMessageDirect(ChatRoom room, String text) async {
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

    final escalate = _isExplicitStaffRequest(text);
    final unclearStreak = escalate ? 0 : room.unclearStreak + 1;
    // ข้อความแรกของลูกค้าในแชททรัพย์ → เข้าคิวแอดมิน (ไม่รอ 2 รอบ)
    final shouldEscalate =
        escalate || unclearStreak >= 1 || room.isPropertyListing;

    late final String replyText;
    late final String replyRole;
    if (shouldEscalate) {
      replyText =
          'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด';
      replyRole = 'system';
    } else {
      replyText =
          'ยังไม่แน่ใจคำถามนี้ครับ — ลองระบุงบ/ทำเล/ประเภทห้อง หรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เพื่อให้ทีมงานช่วยต่อครับ';
      replyRole = 'ai';
    }

    final replyRow = await client
        .from('chat_messages')
        .insert({
          'thread_id': room.id,
          'role': replyRole,
          'text': replyText,
          'requires_admin': shouldEscalate,
        })
        .select('*')
        .single();

    final reply =
        ChatMessage.fromJson(Map<String, dynamic>.from(replyRow));
    if (!room.messages.any((m) => m.id == reply.id)) {
      room.messages.add(reply);
    }

    final patch = <String, dynamic>{
      'admin_reply_done': false,
      'unclear_streak': unclearStreak,
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      if (shouldEscalate) ...{
        'admin_escalated': true,
        'status': 'waiting_admin',
        'category': 'escalation',
        'priority': 'high',
      },
    };

    final updated = await client
        .from('chat_threads')
        .update(patch)
        .eq('id', room.id)
        .select('*')
        .single();

    _applyThreadPatch(room, Map<String, dynamic>.from(updated));
    if (shouldEscalate) {
      room.category = 'escalation';
      room.adminEscalated = true;
      room.status = 'waiting_admin';
      room.priority = 'high';
    }
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
}
