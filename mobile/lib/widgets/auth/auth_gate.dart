import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_required_dialog.dart';

/// ตรวจบัญชีจริงก่อนทำรายการ — แสดงป้อปอัพกลางจอ (ปิดได้)
abstract final class AuthGate {
  static bool get canProceed => AuthService.instance.canCreateListing;

  /// คืน `true` เมื่อมีบัญชีจริงพร้อมดำเนินการต่อ
  static Future<bool> requireRealAccount(
    BuildContext context, {
    String? redirectRoute,
  }) async {
    if (canProceed) return true;
    await AuthRequiredDialog.show(
      context,
      redirectRoute: redirectRoute,
    );
    return canProceed;
  }

  static Future<void> runIfAllowed(
    BuildContext context,
    VoidCallback action, {
    String? redirectRoute,
  }) async {
    if (!await requireRealAccount(context, redirectRoute: redirectRoute)) {
      return;
    }
    if (context.mounted) action();
  }
}
