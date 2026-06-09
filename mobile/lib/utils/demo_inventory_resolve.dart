import '../config/env.dart';
import '../data/admin_demo_data.dart';
import '../services/auth_service.dart';
import '../services/demo_cast_bootstrap.dart';

/// ในโหมดตัวอย่าง — map RXT code → demo-inv-* (กัน UUID จริงจาก Supabase ไม่ตรงกับเคสจำลอง)
String resolveDemoInventoryId(
  String inventoryId, {
  String? inventoryCode,
}) {
  if (inventoryId.startsWith('demo-')) return inventoryId;
  if (!_demoWorld) return inventoryId;
  final byCode = AdminDemoData.inventoryIdForCode(inventoryCode);
  if (byCode != null) return byCode;
  return inventoryId;
}

bool get _demoWorld =>
    Env.adminDemoCases &&
    (DemoCastBootstrap.shouldUseCastWorld ||
        AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend);
