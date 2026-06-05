import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) async {
    final client = SupabaseService.client!;
    final payload = {
      if (threadId != null) 'thread_id': threadId,
      'room_kind': roomKind,
      if (listingId != null) 'listing_id': listingId,
      if (listingCode != null) 'listing_code': listingCode,
      'listing_title': listingTitle ?? '',
      if (projectName != null) 'project_name': projectName,
      'allow_viewing_request': allowViewingRequest,
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
            'status.eq.waiting_admin,viewing_submitted.eq.true,admin_escalated.eq.true,category.in.(staff_support,escalation,viewing_request)',
          )
          .order('priority', ascending: false)
          .order('last_message_at', ascending: false)
          .limit(100);
    } else {
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
    final client = SupabaseService.client!;
    final payload = {
      'thread_id': room.id,
      'room_kind': room.roomKind ?? 'property',
      'listing_id': room.isPropertyListing ? room.listingId : null,
      'listing_code': room.listingCode,
      'listing_title': room.listingTitle,
      if (room.projectName != null) 'project_name': room.projectName,
      'allow_viewing_request': room.allowViewingRequest,
      'text': text,
    };

    final res = await client.functions.invoke('chat-turn', body: payload);
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'chat-turn failed');
    }

    _mergeTurnResponse(room, data);
  }

  Future<void> sendAdminReply(
    ChatRoom room,
    String text, {
    bool resolve = false,
  }) async {
    final client = SupabaseService.client!;
    final res = await client.functions.invoke(
      'chat-admin-reply',
      body: {
        'thread_id': room.id,
        'text': text,
        'resolve': resolve,
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
    room.adminReplyDone = true;
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
  }

  Future<ChatRoom> assignThread(String threadId, String assigneeId) async {
    final client = SupabaseService.client!;
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
    room.viewingSubmitted = true;
    room.adminEscalated = true;
    room.adminReplyDone = false;
    room.updatedAt = DateTime.now();
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
    void Function(ChatMessage message) onMessage,
  ) {
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
    ).subscribe();
    return channel;
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

  void _applyThreadPatch(ChatRoom room, Map<String, dynamic> thread) {
    room.adminEscalated = thread['admin_escalated'] == true;
    room.viewingSubmitted = thread['viewing_submitted'] == true;
    room.allowViewingRequest = thread['allow_viewing_request'] == true;
    room.adminReplyDone = thread['admin_reply_done'] == true;
    if (thread['status'] != null) {
      room.status = thread['status']?.toString();
    }
    if (thread['assigned_admin_id'] != null) {
      room.assignedAdminId = thread['assigned_admin_id']?.toString();
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
