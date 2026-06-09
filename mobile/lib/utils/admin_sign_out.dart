import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../state/session_gate.dart';

Future<void> performAdminSignOut(BuildContext context) async {
  await AuthService.instance.signOut();
  await SessionGate.instance?.resetToWelcome();
  if (!context.mounted) return;
  context.go('/login');
}
