import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient? get _client => SupabaseService.client;

  Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return Stream.value(const AuthState(AuthChangeEvent.signedOut, null));
    }
    return _client!.auth.onAuthStateChange;
  }

  User? get currentUser => _client?.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<void> signIn({required String email, required String password}) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    await _client!.auth.signInWithPassword(email: email, password: password);
    await _syncProfileRole();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String role = 'seeker',
  }) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    await _client!.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
    await _syncProfileRole();
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  Future<String?> fetchProfileRole() async {
    if (_client == null || currentUser == null) return null;
    final row = await _client!
        .from('profiles')
        .select('role')
        .eq('id', currentUser!.id)
        .maybeSingle();
    return row?['role'] as String?;
  }

  Future<void> updateProfileRole(String role) async {
    if (_client == null || currentUser == null) return;
    await _client!
        .from('profiles')
        .update({'role': role})
        .eq('id', currentUser!.id);
  }

  Future<void> _syncProfileRole() async {
    await fetchProfileRole();
  }

  static bool get authRequired => Env.isConfigured;
}
