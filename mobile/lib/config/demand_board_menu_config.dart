import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_perspective.dart';
import '../state/user_role_controller.dart';

/// จุดตั้งค่าเมนู「บอร์ดหาทรัพย์」และความต้องการลูกค้า — แก้ที่นี่ที่เดียว
abstract final class DemandBoardMenuConfig {
  /// แท็บล่าง「บอร์ด」ใน [MainShell] (หน้าแรก=0, บันทึก=1, บอร์ด=2)
  static const boardTabIndex = 2;

  /// ฟีดประกาศหาทรัพย์ — ทุกมุมมอง (business-rules §6)
  static const boardFeedPerspectives = AppPerspective.values;

  /// ส่งความต้องการ → รอแอดมินเผยแพร่บนบอร์ด
  static const requirementPerspectives = <AppPerspective>{
    AppPerspective.customer,
  };

  /// เจ้าของ/นายหน้า — เสนอทรัพย์บนประกาศบอร์ด
  static const offerPerspectives = <AppPerspective>{
    AppPerspective.owner,
    AppPerspective.agent,
  };

  static const createRequirementRoute = '/requirements/create';
  static const myRequirementsRoute = '/requirements/mine';
  static const savedBoardRoute = '/board/saved';

  static String boardDetailRoute(String postId) => '/board/$postId';
  static String boardOfferRoute(String postId) => '/board/$postId/offer';

  /// การ์ด「ช่วยหาทรัพย์ฟรี」ใน Quick actions หน้าแรก
  static const showHomeQuickRequirementCard = true;

  /// การ์ด「บอร์ดหาทรัพย์」ใน Quick actions หน้าแรก
  static const showHomeQuickBoardCard = true;

  /// แถบจัดการความต้องการใต้ช่องค้นหา (มุมมองลูกค้า)
  static const showCustomerRequirementBanner = true;

  /// แถวโปรโมต「บอกความต้องการ」คู่กับลงประกาศ
  static const showHomePromoRequirementTile = true;

  static bool showsBoardFeedFor(UserRoleController role) =>
      boardFeedPerspectives.contains(role.perspective);

  static bool showsRequirementsFor(UserRoleController role) =>
      requirementPerspectives.contains(role.perspective);

  static bool showsOffersFor(UserRoleController role) =>
      offerPerspectives.contains(role.perspective);

  static bool showHomeQuickRequirement(UserRoleController role) =>
      showHomeQuickRequirementCard;

  static bool showHomeQuickBoard(UserRoleController role) =>
      showHomeQuickBoardCard && showsBoardFeedFor(role);

  static bool showRequirementBanner(UserRoleController role) =>
      showCustomerRequirementBanner && showsRequirementsFor(role);

  static bool showPromoRequirementTile(UserRoleController role) =>
      showHomePromoRequirementTile;

  /// รายการเมนูโปรไฟล์ — แยกตามมุมมอง
  static List<DemandBoardMenuEntry> profileEntries(
    AppStrings s,
    UserRoleController role,
  ) {
    final savedEntry = DemandBoardMenuEntry(
      id: 'board_saved',
      icon: Icons.favorite_border,
      title: s.savedDemandBoardTitle,
      route: savedBoardRoute,
    );

    if (showsRequirementsFor(role)) {
      return [
        savedEntry,
        DemandBoardMenuEntry(
          id: 'requirement_create',
          icon: Icons.manage_search_outlined,
          title: s.requirementTellTitle,
          route: createRequirementRoute,
        ),
        DemandBoardMenuEntry(
          id: 'requirement_mine',
          icon: Icons.fact_check_outlined,
          title: s.myRequirementsTitle,
          route: myRequirementsRoute,
        ),
        DemandBoardMenuEntry(
          id: 'board_feed',
          icon: Icons.campaign_outlined,
          title: s.homeQuickBoardTitle,
          opensBoardTab: true,
        ),
      ];
    }
    if (showsOffersFor(role)) {
      return [
        savedEntry,
        DemandBoardMenuEntry(
          id: 'board_feed',
          icon: Icons.campaign_outlined,
          title: s.menuDemandBoard,
          opensBoardTab: true,
        ),
      ];
    }
    if (showsBoardFeedFor(role)) {
      return [savedEntry];
    }
    return [];
  }
}

/// รายการเมนูเดียว — ใช้ในโปรไฟล์หรือ sheet อื่น
class DemandBoardMenuEntry {
  const DemandBoardMenuEntry({
    required this.id,
    required this.icon,
    required this.title,
    this.route,
    this.subtitle,
    this.opensBoardTab = false,
  }) : assert(route != null || opensBoardTab);

  final String id;
  final IconData icon;
  final String title;
  final String? route;
  final String? subtitle;
  final bool opensBoardTab;
}
