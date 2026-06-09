import '../config/env.dart';
import '../data/demo_cast_catalog.dart';
import '../services/admin_repository.dart';
import '../services/appointment_repository.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/demo_cast_session.dart';
import '../data/demo_viewing_record_seed.dart';
import '../data/hub_demo_seed.dart';
import '../services/admin_comp_card_service.dart';
import '../services/profile_tag_service.dart';
import '../services/viewing_request_service.dart';
import '../services/local_prefs_service.dart';
import '../services/viewing_appointment_record_service.dart';
import '../state/user_role_controller.dart';

/// รีเซ็ตเคสจำลองเก่า + เปิดโหมดตัวละครใหม่
abstract final class DemoCastBootstrap {
  /// เพิ่มเมื่อเปลี่ยนชุดจำลอง — บังคับล้าง cache เก่าในเครื่อง
  static const simulationEpoch = 22;
  static const _epochKey = 'demo_cast_simulation_epoch';

  /// โหมดทดลองแยก — หลังบ้านใช้เฉพาะข้อมูลจำลอง (ไม่ผสม KPI/แชทจาก Supabase)
  static bool get shouldUseCastWorld =>
      Env.adminDemoCases && DemoCastSession.hubEnabled;

  static bool get isolatedAdminTrial => shouldUseCastWorld;

  static Future<void> ensureReady({UserRoleController? roleController}) async {
    if (!DemoCastSession.hubEnabled) return;

    await LocalPrefsService.instance.init();
    final stored = await LocalPrefsService.instance.getInt(_epochKey);
    if (stored != simulationEpoch) {
      await resetAll(roleController: roleController);
      await LocalPrefsService.instance.setInt(_epochKey, simulationEpoch);
      return;
    }

    if (roleController != null && !DemoCastSession.instance.hasActiveCast) {
      DemoCastSession.instance.activateDefaultCeo(roleController);
    }
    ChatService.instance.reloadCastSimulation();
  }

  /// รีเซ็ตนัดชม + แชทจำลอง — คืนเคสรอมอบหมาย/ยืนยันให้ทดสอบใหม่
  static Future<void> resetViewingTrialCases({
    UserRoleController? roleController,
  }) async {
    await resetAll(roleController: roleController);
    ChatService.instance.reloadCastSimulation();
    await AdminCompCardService.instance.ensureSeeded();
  }

  static Future<void> resetAll({UserRoleController? roleController}) async {
    await AppointmentRepository.ensureDemoSeedCurrent(force: true);
    await ViewingAppointmentRecordService.instance.clearAll();
    ProfileTagService.instance.resetDemo();
    AdminCompCardService.instance.resetDemo();
    ViewingRequestService.instance.resetDemo();
    HubDemoSeed.reset();
    HubDemoSeed.ensure();
    await AdminCompCardService.instance.ensureSeeded(force: true);
    DemoViewingRecordSeed.reset();
    ChatService.instance.resetCastSimulation();

    DemoCastSession.instance.resetActive();
    if (roleController != null) {
      DemoCastSession.instance.activateDefaultCeo(roleController, force: true);
    }
  }

  static bool get isSharedAdminSession {
    final email = AuthService.instance.currentUser?.email?.trim().toLowerCase();
    return email == DemoCastCatalog.sharedEntryEmail ||
        email == AdminRepository.demoAdminEmail;
  }
}
