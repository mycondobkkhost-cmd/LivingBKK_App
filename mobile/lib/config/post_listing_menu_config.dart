import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_perspective.dart';
import '../state/user_role_controller.dart';

/// จุดตั้งค่าเมนู「โพส์ประกาศลงทรัพย์」— แก้ที่นี่ที่เดียว แล้วทั้งแอปอ้างอิง
abstract final class PostListingMenuConfig {
  /// เส้นทาง GoRouter สำหรับฟอร์มลงประกาศ
  static const createRoute = '/listing/create';

  /// ประกาศของฉัน / ยืนยันว่าง
  static const myListingsRoute = '/listings/mine';

  /// ทรัพย์ที่แอดมินมอบให้ดูแล
  static const caredPropertiesRoute = '/listings/cared';

  /// แท็บล่าง — จัดการประกาศของคุณ (แทนบันทึกเดิม)
  static const manageListingsShellTabIndex = 1;

  /// นำทางจากศูนย์แจ้งเตือน → แท็บของฉัน (ไม่ใช่ route GoRouter)
  static const mineShellTabRoute = 'shell://mine';

  /// มุมมองที่เห็นเมนูลงประกาศ (ตาม business-rules: Owner + Agent)
  static const postPerspectives = <AppPerspective>{
    AppPerspective.owner,
    AppPerspective.agent,
  };

  /// แสดงแถบโปรโมตบนหน้าแรก (ชวนลงประกาศ) แม้ยังเป็นมุมมองลูกค้า
  static const showHomePromoForAllPerspectives = true;

  /// แสดงการ์ด「ลงประกาศฟรี」ใน Quick actions หน้าแรก
  static const showHomeQuickPostCard = true;

  static bool showsForPerspective(AppPerspective perspective) =>
      postPerspectives.contains(perspective);

  static bool showsFor(UserRoleController role) =>
      showsForPerspective(role.perspective);

  static bool showHomePromo(UserRoleController role) =>
      showHomePromoForAllPerspectives || showsFor(role);

  static bool showHomeQuickPost(UserRoleController role) =>
      showHomeQuickPostCard;

  /// รายการเมนูในโปรไฟล์ (ลำดับบนลงล่าง)
  static List<PostListingMenuEntry> profileEntries(AppStrings s) => [
        PostListingMenuEntry(
          id: 'create',
          icon: Icons.add_home_work_outlined,
          title: s.postListingProperty,
          route: createRoute,
        ),
        PostListingMenuEntry(
          id: 'mine',
          icon: Icons.list_alt_outlined,
          title: s.myListingsConfirm,
          route: myListingsRoute,
        ),
        PostListingMenuEntry(
          id: 'cared',
          icon: Icons.home_work_outlined,
          title: s.myCaredPropertiesMenu,
          route: caredPropertiesRoute,
        ),
      ];
}

/// รายการเมนูเดียว — ใช้ในโปรไฟล์หรือ sheet อื่น
class PostListingMenuEntry {
  const PostListingMenuEntry({
    required this.id,
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
  });

  final String id;
  final IconData icon;
  final String title;
  final String route;
  final String? subtitle;
}
