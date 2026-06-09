import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/post_listing_menu_config.dart';
import '../models/app_notification.dart';
import '../state/user_role_controller.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'listing_owner_repository.dart';
import 'property_care_notification_service.dart';

/// ศูนย์แจ้งเตือน — รวม lifecycle ประกาศ + แชท + mock ระบบ (v1)
class NotificationCenterRepository extends ChangeNotifier {
  NotificationCenterRepository._();
  static final NotificationCenterRepository instance = NotificationCenterRepository._();

  final _repo = ListingOwnerRepository();
  List<AppNotification> _items = [];
  bool _loading = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;

  int get unreadCount => _items.where((e) => !e.read).length;

  void setPropertyCareNotifications(List<PropertyCareNotifEntry> entries) {
    _items.removeWhere((e) => e.type == AppNotificationType.propertyCareGrant);
    for (final e in entries) {
      _items.insert(
        0,
        AppNotification(
          id: e.id,
          type: AppNotificationType.propertyCareGrant,
          title: e.title,
          body: e.body,
          createdAt: e.createdAt,
          read: e.read,
          priority: AppNotificationPriority.action,
          route: PostListingMenuConfig.mineShellTabRoute,
          ctaLabel: e.ctaLabel,
        ),
      );
    }
    notifyListeners();
  }

  List<AppNotification> filtered(AppNotificationFilter filter) {
    if (filter == AppNotificationFilter.all) return _items;
    return _items.where((e) => e.type.filter == filter).toList();
  }

  Future<void> refresh({
    required UserRoleController role,
    required bool isEnglish,
  }) async {
    _loading = true;
    notifyListeners();
    final out = <AppNotification>[];
    final now = DateTime.now();

    if (role.isOwner || role.isAgent) {
      try {
        final rows = await _repo.myListings(includeArchived: false);
        for (final row in rows) {
          final id = row['id']?.toString() ?? '';
          final title = row['title']?.toString() ?? (isEnglish ? 'Listing' : 'ประกาศ');
          if (ListingOwnerRepository.needsBumpReminder(row)) {
            final daysLeft = ListingOwnerRepository.daysUntilAutoArchive(row);
            out.add(AppNotification(
              id: 'bump_$id',
              type: AppNotificationType.listingBumpDue,
              title: isEnglish ? 'Confirm still available' : 'ยืนยันว่างเพื่อดันโพสต์',
              body: isEnglish
                  ? '$title — due for bump · $daysLeft days until archive'
                  : '$title — ครบ 7 วัน · เหลือ $daysLeft วันก่อนเก็บอัตโนมัติ',
              createdAt: now.subtract(const Duration(hours: 2)),
              priority: AppNotificationPriority.action,
              route: PostListingMenuConfig.myListingsRoute,
              ctaLabel: isEnglish ? 'Confirm' : 'ยืนยันว่าง',
            ));
          } else if (ListingOwnerRepository.daysSinceBump(row) >= 25) {
            out.add(AppNotification(
              id: 'stale_$id',
              type: AppNotificationType.listingStaleWarning,
              title: isEnglish ? 'Listing expiring soon' : 'ประกาศใกล้ถูกเก็บ',
              body: title,
              createdAt: now.subtract(const Duration(days: 1)),
              priority: AppNotificationPriority.urgent,
              route: PostListingMenuConfig.myListingsRoute,
            ));
          }
        }
      } catch (_) {}
    }

    final chatUnread = ChatService.instance.totalUnreadChats;
    if (chatUnread > 0) {
      out.add(AppNotification(
        id: 'chat_inbox',
        type: AppNotificationType.chatMessage,
        title: isEnglish ? 'New messages' : 'ข้อความใหม่',
        body: isEnglish
            ? '$chatUnread unread conversation(s)'
            : 'มี $chatUnread แชทที่ยังไม่อ่าน',
        createdAt: now.subtract(const Duration(minutes: 5)),
        priority: AppNotificationPriority.action,
        route: '/contact',
      ));
    }

    if (AuthService.instance.isSignedIn) {
      out.add(AppNotification(
        id: 'welcome',
        type: AppNotificationType.systemAnnouncement,
        title: isEnglish ? 'Welcome to RealXtate' : 'ยินดีต้อนรับ RealXtate',
        body: isEnglish
            ? 'Verified listings · Free to post · Full-service support'
            : 'ข้อมูลแม่นยำ • ลงประกาศฟรี • บริการครบวงจร',
        createdAt: now.subtract(const Duration(days: 1)),
        priority: AppNotificationPriority.info,
      ));
    }

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _items = out;
    await PropertyCareNotificationService.instance.sync(isEnglish: isEnglish);
    _loading = false;
    notifyListeners();
  }

  void markRead(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    if (id.startsWith('care_')) {
      unawaited(
        PropertyCareNotificationService.instance
            .markRead(id.replaceFirst('care_', '')),
      );
    }
    notifyListeners();
  }

  void markAllRead() {
    _items = [for (final n in _items) n.copyWith(read: true)];
    notifyListeners();
  }
}
