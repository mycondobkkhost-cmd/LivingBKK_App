import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/demand_board_menu_config.dart';
import '../models/demand_post.dart';
import '../shell/main_shell_scope.dart';
/// นำทางเมนูบอร์ดหาทรัพย์ — ใช้แทน `context.push('/requirements/...')` ตรงๆ
abstract final class DemandBoardNavigation {
  static void openBoardTab(BuildContext context, {bool fromHome = false}) {
    MainShellScope.maybeOf(context)?.selectTab(
      DemandBoardMenuConfig.boardTabIndex,
      boardFromHome: fromHome,
    );
  }

  /// เปิดฟอร์มความต้องการ — หน้าปลายทางจะแสดงป้อปอัพล็อกอินเอง
  static void openCreateRequirement(
    BuildContext context, {
    String? sourceThreadId,
  }) {
    context.push(
      DemandBoardMenuConfig.createRequirementRoute,
      extra: sourceThreadId,
    );
  }

  static void openMyRequirements(BuildContext context) {
    context.push(DemandBoardMenuConfig.myRequirementsRoute);
  }

  static void openSavedBoard(BuildContext context) {
    context.push(DemandBoardMenuConfig.savedBoardRoute);
  }

  static void openPostDetail(
    BuildContext context, {
    required DemandPost post,
  }) {
    context.push(
      DemandBoardMenuConfig.boardDetailRoute(post.id),
      extra: post,
    );
  }

  static void openSubmitOffer(
    BuildContext context, {
    required DemandPost post,
  }) {
    context.push(
      DemandBoardMenuConfig.boardOfferRoute(post.id),
      extra: post,
    );
  }

  static void onProfileEntry(BuildContext context, DemandBoardMenuEntry entry) {
    if (entry.opensBoardTab) {
      openBoardTab(context);
      return;
    }
    final route = entry.route;
    if (route == DemandBoardMenuConfig.createRequirementRoute) {
      openCreateRequirement(context);
      return;
    }
    if (route != null) context.push(route);
  }
}
