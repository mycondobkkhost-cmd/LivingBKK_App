import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/brand_settings.dart';
import 'supabase_service.dart';

/// Loads official brand settings from Supabase (falls back to bundled defaults).
class BrandService extends ChangeNotifier {
  BrandService._();
  static final instance = BrandService._();

  BrandSettings _settings = BrandSettings.defaults;
  bool _loaded = false;

  BrandSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (!Env.isConfigured || !SupabaseService.isReady) {
      _loaded = true;
      return;
    }

    try {
      final row = await SupabaseService.client!
          .from('app_brand_settings')
          .select()
          .eq('id', 'default')
          .maybeSingle();

      if (row != null) {
        _settings = BrandSettings.fromJson(Map<String, dynamic>.from(row));
      }
    } catch (e) {
      debugPrint('BrandService.load: $e');
    }

    _loaded = true;
    notifyListeners();
  }
}
