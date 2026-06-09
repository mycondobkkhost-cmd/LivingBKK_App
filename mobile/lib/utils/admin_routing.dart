import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_nav_model.dart';
import '../l10n/app_strings.dart';

/// query `from` — หน้าที่เปิดแชทจาก (เช่น ปฏิทิน) เพื่อย้อนกลับถูกจุด
const kAdminReturnNavKey = 'from';

String adminReturnPath(AdminNavId? nav) {
  if (nav == null || nav == AdminNavId.dashboard) return '/admin';
  return '/admin?nav=${nav.name}';
}

String adminConsoleChatPath({
  required String roomId,
  String? messageId,
  AdminNavId? returnNav,
}) {
  final q = <String, String>{'room': roomId};
  if (messageId != null && messageId.isNotEmpty) q['message'] = messageId;
  if (returnNav != null) q[kAdminReturnNavKey] = returnNav.name;
  return Uri(path: '/admin/console', queryParameters: q).toString();
}

String adminReturnPathFromQuery(String? from) =>
    adminReturnPath(AdminNavId.fromQueryName(from));

/// หน้าแรกหลังบ้านหลังล็อกอิน — ภาพรวมแพลตฟอร์ม (`/admin`)
String adminHomePath({bool preferConsole = false}) =>
    preferConsole ? '/admin/console' : '/admin';

String viewingStaffHomePath() => '/admin?nav=viewingCalendar';

bool isAdminRoute(String path) => path.startsWith('/admin');

/// เมนูที่เอเจ้นพานัดชมเข้าได้ (แอดมินเข้าได้ทุกเมนู)
bool isViewingStaffAllowedNav(AdminNavId? nav) {
  if (nav == null) return false;
  return nav == AdminNavId.viewingCalendar || nav == AdminNavId.appointments;
}

bool isViewingStaffAllowedPath(String path) {
  if (path == '/admin' || path == '/admin/') return true;
  if (path.startsWith('/admin/console')) return true;
  if (path.startsWith('/admin/chat')) return true;
  return false;
}

/// แอดมินเปิดหน้าบ้าน — ต้องมี query นี้ ไม่งั้น router ส่งกลับ `/admin`
const kConsumerPreviewQueryKey = 'preview';
const kConsumerPreviewQueryValue = '1';

bool isConsumerPreviewUri(Uri uri) =>
    uri.queryParameters[kConsumerPreviewQueryKey] == kConsumerPreviewQueryValue;

String consumerPreviewLocation({String path = '/'}) => Uri(
      path: path,
      queryParameters: {kConsumerPreviewQueryKey: kConsumerPreviewQueryValue},
    ).toString();

void goConsumerApp(BuildContext context, {String path = '/'}) {
  context.go(consumerPreviewLocation(path: path));
}

/// ข้อความปุ่มย้อนกลับเมื่อเปิดแชทจากเมนูอื่น (เช่น ปฏิทิน)
String adminChatBackTooltip(AdminNavId? returnNav, AppStrings s) {
  if (returnNav == null) return s.back;
  return s.adminBackToPage(_adminReturnPageLabel(returnNav, s));
}

String _adminReturnPageLabel(AdminNavId nav, AppStrings s) {
  switch (nav) {
    case AdminNavId.dashboard:
      return s.adminTabDashboard;
    case AdminNavId.queue:
      return s.adminNavQueueTitle;
    case AdminNavId.inbox:
      return s.adminTabChat;
    case AdminNavId.leads:
      return s.adminTabLeads;
    case AdminNavId.viewingCalendar:
      return s.adminNavViewingCalendar;
    case AdminNavId.appointments:
      return s.adminTabAppointments;
    case AdminNavId.offers:
      return s.adminTabOffers;
    case AdminNavId.requirements:
      return s.adminNavRequirements;
    case AdminNavId.participant360:
      return s.adminNavParticipant360;
    case AdminNavId.assetRegistry:
      return s.adminNavAssetRegistry;
    case AdminNavId.availabilityAlerts:
      return s.adminNavAvailabilityAlerts;
    case AdminNavId.hiddenRegistry:
      return s.adminNavHiddenRegistry;
    case AdminNavId.inventory:
      return s.adminTabInventory;
    case AdminNavId.import:
      return s.adminTabImport;
    case AdminNavId.moderation:
      return s.adminTabModeration;
    case AdminNavId.projects:
      return s.adminTabProjects;
    case AdminNavId.rentalManagement:
      return s.adminNavRentalManagement;
    case AdminNavId.reports:
      return s.adminTabReports;
    case AdminNavId.boardCreate:
      return s.adminTabCreateBoard;
    case AdminNavId.promos:
      return s.adminTabPromos;
    case AdminNavId.watermark:
      return s.adminTabWatermark;
    case AdminNavId.vault:
      return s.adminNavVault;
    case AdminNavId.accessRequests:
      return s.adminNavAccessRequests;
    case AdminNavId.org:
      return s.adminNavOrg;
  }
}
