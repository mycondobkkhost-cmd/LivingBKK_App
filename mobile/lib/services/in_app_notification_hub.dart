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
  bool _openMineTabOnNextShell = false;
  int? _pendingShellTab;

  /// MainShell จะสลับไปแท็บข้อความเมื่อกลับมาหน้าหลัก
  bool get openContactTabOnNextShell => _openContactTabOnNextShell;
  bool get openMineTabOnNextShell => _openMineTabOnNextShell;

  void requestShellTab(int index) {
    _pendingShellTab = index;
    notifyListeners();
  }

  int? takePendingShellTab() {
    final tab = _pendingShellTab;
    _pendingShellTab = null;
    return tab;
  }

  void requestOpenContactTab() {
    _openContactTabOnNextShell = true;
    notifyListeners();
  }

  void requestOpenMineTab() {
    _openMineTabOnNextShell = true;
    notifyListeners();
  }

  void clearPendingNavigation() {
    _openContactTabOnNextShell = false;
    _openMineTabOnNextShell = false;
    _pendingShellTab = null;
  }

  void show(
    String message, {
    bool countAsUnread = true,
    String? threadId,
    Duration displayDuration = const Duration(seconds: 7),
  }) {
    _bannerMessage = message;
    if (countAsUnread && (threadId == null || threadId.isEmpty)) _unreadChat++;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(displayDuration, () {
      _bannerMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// แจ้งเตือนทั่วไปด้านบน — ไม่เพิ่ม badge แชท
  void showMessage(
    String message, {
    Duration displayDuration = const Duration(seconds: 7),
  }) =>
      show(
        message,
        countAsUnread: false,
        displayDuration: displayDuration,
      );

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
