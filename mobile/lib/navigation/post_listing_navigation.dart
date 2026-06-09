import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/post_listing_menu_config.dart';
import '../services/auth_service.dart';
import '../shell/main_shell_scope.dart';
import '../widgets/auth/auth_gate.dart';

/// นำทางเมนูลงประกาศ — ใช้แทน `context.push('/listing/create')` ตรงๆ
abstract final class PostListingNavigation {
  static void openCreate(BuildContext context) {
    context.push(PostListingMenuConfig.createRoute);
  }

  static void openMyListings(BuildContext context) {
    context.push(PostListingMenuConfig.myListingsRoute);
  }

  /// เปิดแท็บ「จัดการประกาศของคุณ」— ใช้จากหน้าแรกแทนเปิดฟอร์มตรงๆ
  static void openManageHub(BuildContext context) {
    final scope = MainShellScope.maybeOf(context);
    if (scope != null) {
      scope.selectTab(PostListingMenuConfig.manageListingsShellTabIndex);
      return;
    }
    openMyListings(context);
  }

  /// เปิดฟอร์มลงประกาศ — ต้องล็อกอิน/สมัครจริง (โหมดทดลองไม่ได้)
  static Future<void> openCreateWithAuthGate(BuildContext context) async {
    await AuthGate.runIfAllowed(
      context,
      () => openCreate(context),
      redirectRoute: PostListingMenuConfig.createRoute,
    );
  }
}
