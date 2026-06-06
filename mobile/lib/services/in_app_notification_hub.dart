import 'dart:async';

import 'package:flutter/foundation.dart';

/// แจ้งเตือนในแอป — แบนเนอร์ด้านบน + badge แชท
class InAppNotificationHub extends ChangeNotifier {
  static final InAppNotificationHub instance = InAppNotificationHub._();
  InAppNotificationHub._();

  int _unreadChat = 0;
  String? _bannerMessage;
  Timer? _dismissTimer;

  int get unreadChatCount => _unreadChat;
  String? get bannerMessage => _bannerMessage;
  bool _openContactTabOnNextShell = false;

  /// MainShell จะสลับไปแท็บข้อความเมื่อกลับมาหน้าหลัก
  bool get openContactTabOnNextShell => _openContactTabOnNextShell;

  void requestOpenContactTab() {
    _openContactTabOnNextShell = true;
    notifyListeners();
  }

  void clearPendingNavigation() {
    _openContactTabOnNextShell = false;
  }

  void show(String message, {bool countAsUnread = true, String? threadId}) {
    _bannerMessage = message;
    if (countAsUnread && (threadId == null || threadId.isEmpty)) _unreadChat++;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 6), () {
      _bannerMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void dismissBanner() {
    _bannerMessage = null;
    _dismissTimer?.cancel();
    notifyListeners();
  }

  void clearUnread() {
    _unreadChat = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
