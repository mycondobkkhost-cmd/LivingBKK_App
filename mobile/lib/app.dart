import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'state/user_role_controller.dart';
import 'theme/app_theme.dart';

class LivingBkkApp extends StatelessWidget {
  const LivingBkkApp({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: roleController,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'LivingBKK',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.create(roleController: roleController),
        );
      },
    );
  }
}
