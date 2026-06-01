import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

typedef LeadNotification = void Function(String message);

/// In-app notifications via Supabase Realtime (no FCM required).
class RealtimeService {
  RealtimeChannel? _channel;
  final _controller = StreamController<String>.broadcast();

  Stream<String> get messages => _controller.stream;

  Future<void> subscribeToMyLeads() async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    await unsubscribe();

    _channel = SupabaseService.client!.channel('leads-$uid');
    void onLead(PostgresChangePayload payload) {
      final record = payload.newRecord;
      if (record['assigned_to']?.toString() != uid) return;
      final code = record['listing_code'] ?? '';
      _controller.add('มี Lead มอบหมาย: $code');
    }

    _channel!
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
        .subscribe();
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      await SupabaseService.client!.removeChannel(_channel!);
      _channel = null;
    }
  }

  void dispose() {
    unsubscribe();
    _controller.close();
  }
}
