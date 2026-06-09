import 'package:flutter/foundation.dart';

import '../data/demo_cast_catalog.dart';
import '../models/app_perspective.dart';
import '../models/demo_cast_persona.dart';
import '../services/admin_repository.dart';
import '../services/auth_service.dart';
import '../state/user_role_controller.dart';
import 'supabase_service.dart';

/// สลับตัวละครภายในหลังบ้าน — ใช้หลังล็อกอิน demo-admin
class DemoCastSession extends ChangeNotifier {
  DemoCastSession._();
  static final DemoCastSession instance = DemoCastSession._();

  DemoCastPersona? _active;

  DemoCastPersona? get active => _active;
  bool get hasActiveCast => _active != null;

  static bool get hubEnabled {
    final auth = AuthService.instance;
    if (auth.isTrialSignedIn &&
        auth.trialRole == 'admin' &&
        auth.trialDisplayName != null) {
      return true;
    }
    final email = auth.currentUser?.email?.trim().toLowerCase();
    if (email == DemoCastCatalog.sharedEntryEmail ||
        email == AdminRepository.demoAdminEmail) {
      return true;
    }
    return false;
  }

  String? get effectiveAdminId =>
      _active?.profileId ?? SupabaseService.client?.auth.currentUser?.id;

  String? displayLabel(bool isEn) {
    if (_active == null) return null;
    return '${_active!.displayName(isEn)} · ${_active!.kind.labelTh(isEn)}';
  }

  bool authenticateAndActivate({
    required String castId,
    required String password,
    required UserRoleController roleController,
  }) {
    if (!hubEnabled) return false;
    final persona = DemoCastCatalog.authenticate(
      castId: castId,
      password: password,
    );
    if (persona == null) return false;
    _active = persona;
    _applyTo(roleController, persona);
    notifyListeners();
    return true;
  }

  void activateDefaultCeo(UserRoleController roleController, {bool force = false}) {
    if (!hubEnabled || (!force && _active != null)) return;
    final ceo = DemoCastCatalog.find('ceo-01');
    if (ceo == null) return;
    _active = ceo;
    _applyTo(roleController, ceo);
    notifyListeners();
  }

  void resetActive() {
    _active = null;
    notifyListeners();
  }

  void clear(UserRoleController roleController) {
    _active = null;
    roleController.setPlatformAdmin(true);
    roleController.setViewingStaff(value: false, slug: null, userId: null);
    notifyListeners();
  }

  void _applyTo(UserRoleController rc, DemoCastPersona p) {
    switch (p.kind) {
      case DemoCastKind.guide:
        rc.setPlatformAdmin(false);
        rc.setViewingStaff(
          value: true,
          slug: p.staffSlug,
          userId: p.profileId,
        );
        rc.setPerspective(AppPerspective.customer);
      case DemoCastKind.seeker:
        rc.setPlatformAdmin(false);
        rc.setViewingStaff(value: false, slug: null, userId: null);
        rc.setPerspective(AppPerspective.customer);
      case DemoCastKind.broker:
        rc.setPlatformAdmin(false);
        rc.setViewingStaff(value: false, slug: null, userId: null);
        rc.setPerspective(AppPerspective.agent);
      case DemoCastKind.owner:
        rc.setPlatformAdmin(false);
        rc.setViewingStaff(value: false, slug: null, userId: null);
        rc.setPerspective(AppPerspective.owner);
      case DemoCastKind.ceo:
      case DemoCastKind.sup:
      case DemoCastKind.lead:
      case DemoCastKind.admin:
        rc.setPlatformAdmin(true);
        rc.setViewingStaff(value: false, slug: null, userId: null);
        rc.setPerspective(AppPerspective.customer);
    }
  }

  String? adminTierOverride() => _active?.kind.adminTier;

  bool get isViewingGuideCast => _active?.kind == DemoCastKind.guide;

  bool get isBackOfficeCast =>
      _active == null || _active!.kind.isBackOfficeStaff;

  bool get isStaffTierCast {
    final k = _active?.kind;
    return k == DemoCastKind.ceo ||
        k == DemoCastKind.sup ||
        k == DemoCastKind.lead ||
        k == DemoCastKind.admin;
  }
}
