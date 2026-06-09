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
  bool _viewingStaff = false;
  String? _staffSlug;
  String? _staffUserId;

  AppPerspective get perspective => _perspective;
  bool get isPlatformAdmin => _platformAdmin;
  bool get isViewingStaff => _viewingStaff;
  String? get staffSlug => _staffSlug;
  String? get staffUserId => _staffUserId;
  bool get canAccessBackOffice => _platformAdmin || _viewingStaff;

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

  void setViewingStaff({
    required bool value,
    String? slug,
    String? userId,
  }) {
    if (_viewingStaff == value &&
        _staffSlug == slug &&
        _staffUserId == userId) {
      return;
    }
    _viewingStaff = value;
    _staffSlug = slug;
    _staffUserId = userId;
    _notifySafely();
  }

  void clearBackOfficeAccess() {
    setPlatformAdmin(false);
    setViewingStaff(value: false, slug: null, userId: null);
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
