import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/app_perspective.dart';

/// มุมมองหน้าหลัก + สิทธิ์แอดมินระบบ (แยกจากบัญชีทั่วไป)
class UserRoleController extends ChangeNotifier {
  UserRoleController({
    AppPerspective perspective = AppPerspective.customer,
  }) : _perspective = perspective;

  AppPerspective _perspective;
  bool _platformAdmin = false;

  AppPerspective get perspective => _perspective;
  bool get isPlatformAdmin => _platformAdmin;

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void setPerspective(AppPerspective value) {
    if (_perspective == value) return;
    _perspective = value;
    _notifySafely();
  }

  void setPlatformAdmin(bool value) {
    if (_platformAdmin == value) return;
    _platformAdmin = value;
    _notifySafely();
  }

  /// ใช้กับโค้ดเดิมที่อ้าง role เป็น string
  String get role {
    switch (_perspective) {
      case AppPerspective.customer:
        return 'seeker';
      case AppPerspective.agent:
        return 'agent';
      case AppPerspective.owner:
        return 'owner';
    }
  }

  bool get isAgent => _perspective == AppPerspective.agent;
  bool get isOwner => _perspective == AppPerspective.owner;
  bool get isCustomer => _perspective == AppPerspective.customer;

  bool get canManageLeads =>
      isAgent || isOwner || _platformAdmin;

  /// คงไว้สำหรับโค้ดเก่า — แปลงเป็นมุมมอง ไม่เขียน role ลง DB
  void setRole(String value) {
    switch (value) {
      case 'agent':
        setPerspective(AppPerspective.agent);
        break;
      case 'owner':
        setPerspective(AppPerspective.owner);
        break;
      case 'admin':
        setPlatformAdmin(true);
        break;
      default:
        setPerspective(AppPerspective.customer);
    }
  }
}
