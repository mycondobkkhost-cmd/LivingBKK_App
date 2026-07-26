import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/app_perspective.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/demo_cast_session.dart';
import '../services/property_care_notification_service.dart';
import '../services/property_care_repository.dart';
import '../state/session_gate.dart';
import '../state/user_role_controller.dart';
import 'admin_routing.dart';

/// localhost เท่านั้น — ล็อกอินอัตโนมัติจาก `?devRole=seeker|offerer|admin`
/// ใช้คู่กับ `scripts/open-three-role-test.sh` (Chrome profile แยกกัน)
class DevThreeRoleLogin {
  DevThreeRoleLogin._();

  static const paramRole = 'devRole';
  static const paramAuth = 'devAuth';

  static const _demoPassword = 'demo12345';
  static const _seekerEmail = 'demo-seeker@livingbkk.local';
  static const _offererEmail = 'demo-owner@livingbkk.local';
  static const _adminEmail = 'demo-admin@livingbkk.local';

  static bool get isDevHost {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == '127.0.0.1' || host == 'localhost';
  }

  static Future<void> maybeApply({
    required UserRoleController roleController,
    required SessionGate sessionGate,
  }) async {
    if (!kDebugMode || !isDevHost) return;
    if (!sessionGate.loaded) return;

    final uri = Uri.base;
    final role = uri.queryParameters[paramRole]?.trim().toLowerCase();
    if (role == null || role.isEmpty) return;

    final auth = AuthService.instance;
    final useReal = uri.queryParameters[paramAuth] == 'real' && Env.isConfigured;

    try {
      if (useReal && auth.isSignedIn && !auth.isRealSupabaseSession) {
        await auth.signOut();
      } else if (auth.isSignedIn) {
        if (!useReal || auth.isRealSupabaseSession) {
          await _applyDevRolePerspective(role, auth, useReal, roleController);
          if (role == 'admin' && useReal && auth.isRealSupabaseSession) {
            await ChatService.instance.refreshAdminInbox();
          }
          return;
        }
      }
      switch (role) {
        case 'seeker':
          await _signInSeeker(auth, useReal);
          roleController.setRole('customer');
        case 'offerer':
          await _signInOfferer(auth, useReal);
          roleController.setRole('agent');
        case 'admin':
          await _signInAdmin(auth, useReal, roleController);
        default:
          return;
      }
      await sessionGate.markAuthenticated();
      if (role == 'admin' && useReal) {
        await ChatService.instance.refreshAdminInbox();
      }
      if (kDebugMode) {
        debugPrint('[devRole] signed in as $role (${useReal ? 'real' : 'trial'})');
      }
    } catch (e, st) {
      debugPrint('[devRole] login failed for $role: $e\n$st');
    }
  }

  static Future<void> _applyDevRolePerspective(
    String role,
    AuthService auth,
    bool useReal,
    UserRoleController roleController,
  ) async {
    switch (role) {
      case 'seeker':
        roleController.setRole('customer');
      case 'offerer':
        roleController.setRole('agent');
      case 'admin':
        if (useReal && auth.isRealSupabaseSession) {
          final access = await auth.fetchProfileAccess();
          roleController.setPlatformAdmin(access.role == 'admin');
          roleController.setViewingStaff(
            value: access.role == 'viewing_staff',
            slug: access.staffSlug,
            userId: auth.effectiveUserId,
          );
          DemoCastSession.instance.resetActive();
        } else if (auth.isTrialAdmin) {
          roleController.setPlatformAdmin(true);
        }
      default:
        break;
    }
  }

  static Future<void> _signInSeeker(AuthService auth, bool useReal) async {
    if (useReal) {
      await auth.signIn(email: _seekerEmail, password: _demoPassword);
      return;
    }
    await auth.signInAsTrial(role: 'owner');
    PropertyCareRepository.ensureDemoForTrialOwner();
    PropertyCareNotificationService.instance.init();
  }

  static Future<void> _signInOfferer(AuthService auth, bool useReal) async {
    if (useReal) {
      await auth.signIn(email: _offererEmail, password: _demoPassword);
      return;
    }
    await auth.signInAsTrial(role: 'owner');
    PropertyCareRepository.ensureDemoForTrialOwner();
    PropertyCareNotificationService.instance.init();
  }

  static Future<void> _signInAdmin(
    AuthService auth,
    bool useReal,
    UserRoleController roleController,
  ) async {
    if (useReal) {
      await auth.signIn(email: _adminEmail, password: _demoPassword);
      final access = await auth.fetchProfileAccess();
      roleController.setPlatformAdmin(access.role == 'admin');
      roleController.setViewingStaff(
        value: access.role == 'viewing_staff',
        slug: access.staffSlug,
        userId: auth.effectiveUserId,
      );
      // โหมดจริง — ไม่เปิด cast persona (กัน inbox ไม่ดึง Supabase / mine ผิดคน)
      return;
    }
    await auth.signInAsTrial(role: 'admin');
    roleController.setPlatformAdmin(true);
    roleController.setPerspective(AppPerspective.customer);
    if (Env.trialMode && DemoCastSession.hubEnabled) {
      DemoCastSession.instance.activateDefaultCeo(roleController);
    }
  }

  /// URL สำหรับสคริปต์เปิด 3 หน้าต่าง
  static String seekerUrl(String base, {bool real = true}) =>
      _url(base, '/', tab: 'contact', role: 'seeker', real: real);

  static String offererUrl(String base, {bool real = true}) =>
      _url(base, '/', tab: 'board', role: 'offerer', real: real);

  static String adminUrl(String base, {bool real = true}) {
    final q = <String, String>{
      paramRole: 'admin',
      if (real) paramAuth: 'real',
    };
    return Uri.parse('$base/admin/console').replace(queryParameters: q).toString();
  }

  static String _url(
    String base,
    String path, {
    required String tab,
    required String role,
    required bool real,
  }) {
    final q = <String, String>{
      kConsumerPreviewQueryKey: kConsumerPreviewQueryValue,
      kShellTabQueryKey: tab,
      paramRole: role,
      if (real) paramAuth: 'real',
    };
    return Uri.parse(base).replace(path: path, queryParameters: q).toString();
  }
}
