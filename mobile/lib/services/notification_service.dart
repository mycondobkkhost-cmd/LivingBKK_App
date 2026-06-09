import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../firebase/firebase_bootstrap.dart';
import 'supabase_service.dart';

/// Push token storage + FCM (see mobile/docs/FCM_SETUP.md).
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static void Function(String message)? onForegroundMessage;

  /// type: chat_reply | listing_bump | listing_archived | rental_payment_*
  static void Function(String type, Map<String, String> data)? onNotificationOpen;

  bool _registered = false;

  /// Call after sign-in. Web uses Realtime only; mobile registers FCM when configured.
  Future<void> registerIfPossible() async {
    if (_registered) return;
    if (!SupabaseService.isReady || !Env.isConfigured) return;

    if (kIsWeb) {
      _registered = true;
      return;
    }

    if (!Env.firebaseEnabled) {
      _registered = true;
      return;
    }

    try {
      final ready = await FirebaseBootstrap.init();
      if (!ready) {
        _registered = true;
        return;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'RealXtate';
        final body = message.notification?.body ?? '';
        final text = body.isEmpty ? title : '$title · $body';
        onForegroundMessage?.call(text);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _dispatchOpen(message);
      });

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _dispatchOpen(initial);
      }

      messaging.onTokenRefresh.listen(saveFcmToken);

      final token = await messaging.getToken();
      if (token != null) await saveFcmToken(token);
    } catch (e) {
      debugPrint('FCM registration skipped: $e');
    }

    _registered = true;
  }

  void _dispatchOpen(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    if (type.isEmpty || onNotificationOpen == null) return;
    onNotificationOpen!(type, Map<String, String>.from(data));
  }

  Future<void> saveFcmToken(String token) async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    await SupabaseService.client!
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', uid);
  }

  Future<void> clearOnSignOut() async {
    _registered = false;
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await SupabaseService.client!
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', uid);
    } catch (_) {}

    if (!kIsWeb && Env.firebaseEnabled) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }
  }
}
