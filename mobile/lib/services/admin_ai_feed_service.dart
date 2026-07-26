import 'package:flutter/foundation.dart';

import 'admin_ai_feed_repository.dart';

/// สถานะ AI Feed แอดมิน — จำนวน open + refresh หลัง realtime
class AdminAiFeedService extends ChangeNotifier {
  AdminAiFeedService._();
  static final instance = AdminAiFeedService._();

  int _openCount = 0;
  bool _loading = false;

  int get openCount => _openCount;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _openCount = await AdminAiFeedRepository.instance.fetchOpenCount();
    } catch (_) {
      _openCount = 0;
    }
    _loading = false;
    notifyListeners();
  }

  void decrementOpen() {
    if (_openCount > 0) {
      _openCount -= 1;
      notifyListeners();
    }
  }
}
