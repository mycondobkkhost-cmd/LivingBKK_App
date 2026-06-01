import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_service.dart';
import 'state/user_role_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final roleController = UserRoleController();
  runApp(LivingBkkApp(roleController: roleController));
}
