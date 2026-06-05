import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// In-app notifications via Supabase Realtime (no FCM required).
class RealtimeService {
  RealtimeChannel? _leadChannel;
  RealtimeChannel? _userChatChannel;
  RealtimeChannel? _adminChatChannel;
  RealtimeChannel? _adminLeadsChannel;
  final _controller = StreamController<String>.broadcast();

  Stream<String> get messages => _controller.stream;

  Future<void> subscribeToMyLeads() async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    await _unsubscribeLeads();

    _leadChannel = SupabaseService.client!.channel('leads-$uid');
    void onLead(PostgresChangePayload payload) {
      final record = payload.newRecord;
      if (record['assigned_to']?.toString() != uid) return;
      final code = record['listing_code'] ?? '';
      _controller.add('มี Lead มอบหมาย: $code');
    }

    void onAppointment(PostgresChangePayload payload) {
      final record = payload.newRecord;
      if (record['assigned_to']?.toString() != uid) return;
      final code = record['listing_code'] ?? '';
      final date = record['scheduled_date'] ?? '';
      _controller.add('นัดชม: $code · $date');
    }

    _leadChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'leads',
          callback: onLead,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'leads',
          callback: onLead,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'appointments',
          callback: onAppointment,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          callback: onAppointment,
        )
        .subscribe();
  }

  /// แจ้งยูสเซอร์เมื่อทีมตอบแชท (ในแอป — คู่กับ FCM นอกแอป)
  Future<void> subscribeToMyChatReplies() async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    await _unsubscribeUserChat();

    void onChatMessage(PostgresChangePayload payload) {
      final record = payload.newRecord;
      final role = record['role']?.toString();
      if (role != 'admin_notice') return;
      final preview = record['text']?.toString() ?? '';
      final short = preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;
      _controller.add('ข้อความจากทีม: $short');
    }

    _userChatChannel = SupabaseService.client!.channel('user-chat-$uid');
    _userChatChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: onChatMessage,
        )
        .subscribe();
  }

  /// แจ้งแอดมินเมื่อมี Lead ใหม่ (นัดดู / สนใจทรัพย์)
  Future<void> subscribeToAdminLeads({required bool enabled}) async {
    await _unsubscribeAdminLeads();
    if (!enabled || !SupabaseService.isReady) return;

    void onLead(PostgresChangePayload payload) {
      final record = payload.newRecord;
      if (record.isEmpty) return;
      final code = record['listing_code']?.toString() ?? 'Lead';
      final name = record['seeker_nickname']?.toString() ?? '';
      final label = name.isEmpty ? code : '$code · $name';
      _controller.add('Lead ใหม่ — $label');
    }

    _adminLeadsChannel = SupabaseService.client!.channel('admin-leads');
    _adminLeadsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'leads',
          callback: onLead,
        )
        .subscribe();
  }

  /// แจ้งแอดมินเมื่อมีแชทเข้าคิว / มอบหมาย
  Future<void> subscribeToAdminChatOps({
    required bool enabled,
    required String adminUserId,
  }) async {
    await _unsubscribeAdminChat();
    if (!enabled || !SupabaseService.isReady || adminUserId.isEmpty) return;

    void onThread(PostgresChangePayload payload) {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final status = record['status']?.toString();
      if (status == 'resolved') return;

      final code = record['listing_code']?.toString() ?? 'Support';
      final assigned = record['assigned_admin_id']?.toString();
      final viewing = record['viewing_submitted'] == true;
      final category = record['category']?.toString() ?? '';
      final threadStatus = record['status']?.toString() ?? '';
      final priority = record['priority']?.toString() ?? 'normal';
      final unclear = (record['unclear_streak'] as num?)?.toInt() ?? 0;
      final adminReplyDone = record['admin_reply_done'] == true;

      final needsOps = _threadNeedsOps(
        category: category,
        status: threadStatus,
        priority: priority,
        viewingSubmitted: viewing,
        unclearStreak: unclear,
        adminReplyDone: adminReplyDone,
      );
      if (!needsOps) return;

      if (assigned == null || assigned.isEmpty) {
        _controller.add('แชทรอรับงาน — $code');
        return;
      }
      if (assigned == adminUserId) {
        _controller.add('งานของคุณ — $code');
        return;
      }
      _controller.add('มีคนรับงานแล้ว — $code');
    }

    _adminChatChannel = SupabaseService.client!.channel('admin-chat-$adminUserId');
    _adminChatChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_threads',
          callback: onThread,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_threads',
          callback: onThread,
        )
        .subscribe();
  }

  bool _threadNeedsOps({
    required String category,
    required String status,
    required String priority,
    required bool viewingSubmitted,
    required int unclearStreak,
    required bool adminReplyDone,
  }) {
    if (viewingSubmitted && !adminReplyDone) return true;
    if (category == 'escalation' || category == 'viewing_request') return true;
    if (category == 'demand_offer' && status == 'waiting_admin') return true;
    if (category == 'staff_support' && status == 'waiting_admin') return true;
    if (status == 'waiting_admin' && priority == 'high') return true;
    if (status == 'waiting_admin' && unclearStreak >= 2) return true;
    return false;
  }

  Future<void> _unsubscribeLeads() async {
    if (_leadChannel != null && SupabaseService.isReady) {
      await SupabaseService.client!.removeChannel(_leadChannel!);
      _leadChannel = null;
    }
  }

  Future<void> _unsubscribeUserChat() async {
    if (_userChatChannel != null && SupabaseService.isReady) {
      await SupabaseService.client!.removeChannel(_userChatChannel!);
      _userChatChannel = null;
    }
  }

  Future<void> _unsubscribeAdminLeads() async {
    if (_adminLeadsChannel != null && SupabaseService.isReady) {
      await SupabaseService.client!.removeChannel(_adminLeadsChannel!);
      _adminLeadsChannel = null;
    }
  }

  Future<void> _unsubscribeAdminChat() async {
    if (_adminChatChannel != null && SupabaseService.isReady) {
      await SupabaseService.client!.removeChannel(_adminChatChannel!);
      _adminChatChannel = null;
    }
  }

  Future<void> unsubscribe() async {
    await _unsubscribeLeads();
    await _unsubscribeUserChat();
    await _unsubscribeAdminChat();
    await _unsubscribeAdminLeads();
  }

  void dispose() {
    unsubscribe();
    _controller.close();
  }
}
