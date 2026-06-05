import 'package:flutter/foundation.dart';

import '../models/platform_exclusive_settings.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// โหลดตั้งค่า Exclusive / ดันฟีด — cache ในแอป
class PlatformSettingsService extends ChangeNotifier {
  PlatformSettingsService._();
  static final PlatformSettingsService instance = PlatformSettingsService._();

  PlatformExclusiveSettings _exclusive = PlatformExclusiveSettings.defaults;
  bool _loaded = false;

  PlatformExclusiveSettings get exclusive => _exclusive;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (!SupabaseService.isReady || AuthService.instance.trialSimulatesBackend) {
      _exclusive = PlatformExclusiveSettings.defaults;
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final row = await SupabaseService.client!
          .from('app_platform_settings')
          .select()
          .eq('id', 'default')
          .maybeSingle();
      if (row != null) {
        _exclusive = PlatformExclusiveSettings.fromJson(row);
      }
    } catch (_) {
      _exclusive = PlatformExclusiveSettings.defaults;
    }
    _loaded = true;
    notifyListeners();
  }

  void applyExclusive(PlatformExclusiveSettings value) {
    _exclusive = value;
    notifyListeners();
  }
}
