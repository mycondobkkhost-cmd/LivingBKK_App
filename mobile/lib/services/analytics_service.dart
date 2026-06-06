import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// ส่ง product events ขึ้น server (batch) — รองรับ scale ผ่าน analytics_events + rollup
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final _queue = <Map<String, dynamic>>[];
  Timer? _flushTimer;
  bool _flushing = false;

  static const _lifecycleEvents = {
    'app_install',
    'app_open',
    'app_uninstall',
    'client_error',
  };

  void _ensureTimer() {
    _flushTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  void track({
    required String eventType,
    String? listingId,
    String? district,
    String? geoZoneSlug,
    String? listingType,
    String? propertyType,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    if (AuthService.instance.trialSimulatesBackend) return;
    if (!Env.isConfigured || !SupabaseService.isReady) return;
    if (SupabaseService.client?.auth.currentUser == null) return;

    _enqueue({
      'event_type': eventType,
      if (listingId != null) 'listing_id': listingId,
      if (district != null) 'district': district,
      if (geoZoneSlug != null) 'geo_zone_slug': geoZoneSlug,
      if (listingType != null) 'listing_type': listingType,
      if (propertyType != null) 'property_type': propertyType,
      if (source != null) 'source': source,
      if (metadata != null) 'metadata': metadata,
    });
  }

  void trackLifecycle({
    required String eventType,
    required String sessionHash,
    required String platform,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    if (AuthService.instance.trialSimulatesBackend) return;
    if (!Env.isConfigured || !SupabaseService.isReady) return;

    _enqueue({
      'event_type': eventType,
      'session_hash': sessionHash,
      'source': source ?? platform,
      'metadata': {
        'platform': platform,
        ...?metadata,
      },
    }, public: true);
  }

  void trackClientError({
    required String errorKey,
    required String message,
    String? route,
    Map<String, dynamic>? metadata,
  }) {
    if (!Env.isConfigured || !SupabaseService.isReady) return;

    _enqueue({
      'event_type': 'client_error',
      'source': 'client',
      'metadata': {
        'error_key': errorKey,
        'message': message,
        if (route != null) 'route': route,
        'platform': _platformLabel(),
        ...?metadata,
      },
    }, public: true);
  }

  void trackListingView({
    required String listingId,
    String? district,
    String? listingType,
    String? source,
  }) {
    track(
      eventType: 'listing_view',
      listingId: listingId,
      district: district,
      listingType: listingType,
      source: source ?? 'detail',
    );
  }

  void trackListingShare({
    required String listingId,
    String? district,
    String? listingType,
  }) {
    track(
      eventType: 'listing_share',
      listingId: listingId,
      district: district,
      listingType: listingType,
      source: 'share',
    );
  }

  void trackChatStart({
    required String listingId,
    String? district,
    String? listingType,
  }) {
    track(
      eventType: 'chat_start',
      listingId: listingId,
      district: district,
      listingType: listingType,
      source: 'chat',
    );
  }

  void _enqueue(Map<String, dynamic> event, {bool public = false}) {
    final type = event['event_type'] as String?;
    if (!public && (type == null || !_lifecycleEvents.contains(type))) {
      if (SupabaseService.client?.auth.currentUser == null) return;
    }
    _queue.add(event);
    if (_queue.length >= 20) {
      unawaited(flush());
    } else {
      _ensureTimer();
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'other';
    }
  }

  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;
    if (!Env.isConfigured || !SupabaseService.isReady) return;

    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();

    try {
      await SupabaseService.client!.functions.invoke(
        'analytics-track',
        body: {'events': batch},
      );
    } catch (_) {
      if (_queue.length < 200) {
        _queue.insertAll(0, batch);
      }
    } finally {
      _flushing = false;
    }
  }
}
