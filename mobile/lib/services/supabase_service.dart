import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Env.load();
    if (!Env.isConfigured) return;

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static bool get isReady => client != null;
}
