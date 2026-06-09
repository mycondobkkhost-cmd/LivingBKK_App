import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../models/property_care_summary.dart';
import 'auth_service.dart';
import 'in_app_notification_hub.dart';
import 'local_prefs_service.dart';
import 'notification_center_repository.dart';
import 'property_care_repository.dart';

/// แจ้งเตือนมอบสิทธิ์ดูแลทรัพย์ — badge กระดิ่ง + toast มุมบนขวา
class PropertyCareNotificationService extends ChangeNotifier {
  PropertyCareNotificationService._();
  static final PropertyCareNotificationService instance =
      PropertyCareNotificationService._();

  static const _readKey = 'property_care_notif_read_v1';

  String? _toastMessage;
  Timer? _toastTimer;
  int _unread = 0;
  Set<String> _readIds = {};

  String? get toastMessage => _toastMessage;
  int get unreadCount => _unread;

  /// งานที่ต้องทำ — รอรับสิทธิ์ / เติมข้อมูล (badge แท็บของฉัน)
  int _actionRequired = 0;
  int get actionRequiredCount => _actionRequired;

  Future<void> init() async {
    await LocalPrefsService.instance.init();
    _readIds = (await LocalPrefsService.instance.getStringList(_readKey)).toSet();
    await sync(isEnglish: false);
  }

  Future<void> sync({required bool isEnglish}) async {
    if (!AuthService.instance.isSignedIn) {
      _unread = 0;
      _actionRequired = 0;
      notifyListeners();
      return;
    }
    await PropertyCareRepository.ensureDemoForTrialOwner();
    final all = await PropertyCareRepository.instance.summariesForCurrentUser();
    final pending = all.where((s) => s.needsClaim || s.needsOwnerData).toList();
    _actionRequired = pending.length;
    _unread = pending.where((s) => !_readIds.contains(s.right.id)).length;
    notifyListeners();
    await _pushToNotificationCenter(pending, isEnglish: isEnglish);
  }

  Future<void> onGrantToUser({
    required String userId,
    required String inventoryCode,
    required bool isEnglish,
  }) async {
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid != userId) return;

    final s = AppStrings(isEnglish);
    _toastMessage = null;
    _toastTimer?.cancel();

    InAppNotificationHub.instance.requestOpenMineTab();
    await sync(isEnglish: isEnglish);
    notifyListeners();
  }

  void dismissToast() {
    _toastMessage = null;
    _toastTimer?.cancel();
    notifyListeners();
  }

  Future<void> markRead(String rightId) async {
    _readIds.add(rightId);
    await LocalPrefsService.instance.setStringSet(_readKey, _readIds);
    await sync(isEnglish: false);
  }

  Future<void> markAllRead() async {
    final all = await PropertyCareRepository.instance.summariesForCurrentUser();
    for (final s in all) {
      _readIds.add(s.right.id);
    }
    await LocalPrefsService.instance.setStringSet(_readKey, _readIds);
    await sync(isEnglish: false);
  }

  Future<void> _pushToNotificationCenter(
    List<PropertyCareSummary> pending, {
    required bool isEnglish,
  }) async {
    final s = AppStrings(isEnglish);
    final repo = NotificationCenterRepository.instance;
    repo.setPropertyCareNotifications(
      pending
          .where((x) => x.needsClaim)
          .map(
            (x) => PropertyCareNotifEntry(
              id: 'care_${x.right.id}',
              rightId: x.right.id,
              title: s.careNotifTitle,
              body: s.careNotifBody(x.inventoryCode ?? 'RXT'),
              ctaLabel: s.careNotifCta,
              read: _readIds.contains(x.right.id),
              createdAt: x.right.grantedAt ?? DateTime.now(),
            ),
          )
          .toList(),
    );
  }
}

class PropertyCareNotifEntry {
  const PropertyCareNotifEntry({
    required this.id,
    required this.rightId,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String rightId;
  final String title;
  final String body;
  final String ctaLabel;
  final bool read;
  final DateTime createdAt;
}
