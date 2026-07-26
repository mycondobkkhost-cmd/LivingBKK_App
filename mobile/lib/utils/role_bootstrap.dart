import '../services/auth_service.dart';
import '../services/demo_cast_session.dart';
import '../state/user_role_controller.dart';

/// โหลดสิทธิ์จาก session ก่อน router ทำงาน — กัน /admin/console เด้งกลับ /admin
Future<void> bootstrapUserRole(UserRoleController roleController) async {
  final auth = AuthService.instance;
  if (!auth.isSignedIn) return;

  if (auth.isTrialSignedIn) {
    final trialRole = auth.trialRole ?? 'owner';
    roleController.setPlatformAdmin(trialRole == 'admin');
    roleController.setRole(trialRole);
    if (trialRole == 'admin' && DemoCastSession.hubEnabled) {
      DemoCastSession.instance.activateDefaultCeo(roleController);
    }
    return;
  }

  try {
    final access = await auth.fetchProfileAccess();
    roleController.setPlatformAdmin(access.role == 'admin');
    roleController.setViewingStaff(
      value: access.role == 'viewing_staff',
      slug: access.staffSlug,
      userId: auth.effectiveUserId,
    );
    if (access.role == 'admin' && DemoCastSession.hubEnabled) {
      DemoCastSession.instance.activateDefaultCeo(roleController);
    }
  } catch (_) {}
}
