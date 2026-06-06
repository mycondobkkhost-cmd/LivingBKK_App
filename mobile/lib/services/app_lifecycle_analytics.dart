import 'dart:math';

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'local_prefs_service.dart';

/// ติดตามติดตั้ง / เปิดแอป / ถอน (เท่าที่ตรวจได้บนเว็บ+PWA)
class AppLifecycleAnalytics {
  AppLifecycleAnalytics._();
  static final instance = AppLifecycleAnalytics._();

  static const _installKey = 'analytics_app_install_reported';
  static const _sessionKey = 'analytics_session_hash';

  Future<void> onAppStart() async {
    await LocalPrefsService.instance.init();
    final hash = await _sessionHash();
    final platform = _platformLabel();

    final installed = await LocalPrefsService.instance.getBool(_installKey);
    if (installed != true) {
      await LocalPrefsService.instance.setBool(_installKey, true);
      AnalyticsService.instance.trackLifecycle(
        eventType: 'app_install',
        sessionHash: hash,
        platform: platform,
        source: kIsWeb ? 'pwa_web' : 'native',
      );
    }

    AnalyticsService.instance.trackLifecycle(
      eventType: 'app_open',
      sessionHash: hash,
      platform: platform,
      source: 'cold_start',
    );
  }

  Future<void> onAppPaused() async {
    await AnalyticsService.instance.flush();
  }

  Future<String> _sessionHash() async {
    var hash = await LocalPrefsService.instance.getString(_sessionKey);
    if (hash == null || hash.isEmpty) {
      hash = _randomHash();
      await LocalPrefsService.instance.setString(_sessionKey, hash);
    }
    return hash;
  }

  String _randomHash() {
    final r = Random();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'other';
    }
  }
}
