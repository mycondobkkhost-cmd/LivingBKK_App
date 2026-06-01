import 'supabase_service.dart';

/// Placeholder for FCM — wire firebase_messaging in Phase 4.4.
class NotificationService {
  Future<void> saveFcmToken(String token) async {
    if (!SupabaseService.isReady) return;
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return;

    await SupabaseService.client!
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', uid);
  }

  Future<void> registerPlaceholder() async {
    // TODO: FirebaseMessaging.instance.getToken() → saveFcmToken
  }
}
