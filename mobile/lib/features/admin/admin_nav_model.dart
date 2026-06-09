import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/chat_service.dart';

/// รหัสหน้าหลังบ้าน — แทน TabBar 13 แท็บเดิม
enum AdminNavId {
  queue,
  leads,
  inbox,
  dashboard,
  inventory,
  import,
  moderation,
  projects,
  appointments,
  viewingCalendar,
  offers,
  requirements,
  reports,
  boardCreate,
  promos,
  watermark,
  vault,
  assetRegistry,
  availabilityAlerts,
  hiddenRegistry,
  rentalManagement,
  participant360,
  accessRequests,
  org,
  ;

  static AdminNavId? fromQueryName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final id in AdminNavId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}

/// กลุ่มเมนูแบบดรอปดาวน์ (ไม่รวมปักหมุดเร่งด่วน)
enum AdminNavGroup {
  assets,
  rentalManagement,
  customers,
  system,
  vault,
}

class AdminNavItem {
  const AdminNavItem({
    required this.id,
    required this.labelTh,
    required this.labelEn,
    required this.icon,
    this.badgeCount = 0,
    this.urgent = false,
    this.ceoOnly = false,
    /// ซับเมนูใต้รายการหลัก (เช่น คลังทรัพย์ > แจ้งเตือนกำลังจะว่าง)
    this.subIndent = 0,
    this.children = const [],
  });

  final AdminNavId id;
  final String labelTh;
  final String labelEn;
  final IconData icon;
  final int badgeCount;
  final bool urgent;
  final bool ceoOnly;
  final int subIndent;
  final List<AdminNavItem> children;

  String label(bool isEn) => isEn ? labelEn : labelTh;

  Iterable<AdminNavItem> flatten() sync* {
    yield this;
    for (final child in children) {
      yield* child.flatten();
    }
  }
}

/// สร้างรายการนำทางตาม tier + KPI
class AdminNavConfig {
  const AdminNavConfig({
    required this.tier,
    required this.overview,
  });

  final String tier;
  final AdminDashboardOverview overview;

  bool get isCeo => tier == 'ceo';
  bool get isSuper => tier == 'super' || isCeo;
  bool get canSeeVault => isSuper;
  bool get isViewingStaffOnly => tier == 'staff';

  /// รอรับงาน — ตรงกับแท็บ「รอรับงาน (n)」ใน inbox
  int get queueUnclaimedCount =>
      ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.unclaimed).length;

  /// งานของฉัน — ตรงกับแท็บ「งานของฉัน (n)」
  int get inboxMineCount =>
      ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.mine).length;

  /// ชื่อหน้าตามเมนูที่เลือก — ใช้แถบหัวข้อโหมดคอม
  String labelForNav(AdminNavId id, AppStrings s) {
    for (final item in pinnedItems(s)) {
      if (item.id == id) return item.label(s.isEnglish);
    }
    for (final group in visibleGroups) {
      for (final item in groupItems(group, s)) {
        for (final flat in item.flatten()) {
          if (flat.id == id) return flat.label(s.isEnglish);
        }
      }
    }
    return s.adminLivingBkk;
  }

  /// รวม badge ทุกเมนู (ปักหมุด + กลุ่ม) สำหรับไอคอนเมนู
  int menuBadgeCount(AppStrings s) {
    var total = 0;
    for (final item in pinnedItems(s)) {
      total += item.badgeCount;
    }
    for (final group in visibleGroups) {
      total += badgeForGroup(group);
    }
    return total;
  }

  /// ปักหมุด — ห้ามซ่อนในดรอปดาวน์
  List<AdminNavItem> pinnedItems(AppStrings s) {
    if (isViewingStaffOnly) {
      return [
        AdminNavItem(
          id: AdminNavId.viewingCalendar,
          labelTh: s.adminNavViewingCalendar,
          labelEn: 'Viewing calendar',
          icon: Icons.calendar_month_outlined,
          badgeCount: overview.viewingCalendarBadge,
          urgent: overview.viewingCalendarBadge > 0,
        ),
      ];
    }
    final queue = queueUnclaimedCount;
    final mine = inboxMineCount;
    final leads = overview.leadsNew;
    return [
      AdminNavItem(
        id: AdminNavId.dashboard,
        labelTh: s.adminTabDashboard,
        labelEn: 'Platform overview',
        icon: Icons.dashboard_outlined,
      ),
      AdminNavItem(
        id: AdminNavId.viewingCalendar,
        labelTh: s.adminNavViewingCalendar,
        labelEn: 'Viewing calendar',
        icon: Icons.calendar_month_outlined,
        badgeCount: overview.viewingCalendarBadge,
        urgent: overview.viewingCalendarBadge > 0,
      ),
      AdminNavItem(
        id: AdminNavId.queue,
        labelTh: 'รอรับงาน',
        labelEn: 'Queue',
        icon: Icons.notification_important_outlined,
        badgeCount: queue,
        urgent: queue > 0,
      ),
      AdminNavItem(
        id: AdminNavId.leads,
        labelTh: s.adminTabLeads,
        labelEn: 'Leads',
        icon: Icons.support_agent_outlined,
        badgeCount: leads,
        urgent: leads > 0,
      ),
      AdminNavItem(
        id: AdminNavId.inbox,
        labelTh: s.adminTabChat,
        labelEn: 'Chat',
        icon: Icons.chat_bubble_outline,
        badgeCount: mine,
        urgent: mine > 0,
      ),
    ];
  }

  int badgeForGroup(AdminNavGroup group) {
    switch (group) {
      case AdminNavGroup.assets:
        return overview.importsPending +
            overview.moderationImages +
            overview.moderationFlags +
            overview.availabilityAlertsDue;
      case AdminNavGroup.customers:
        return overview.viewingCalendarBadge +
            overview.offersPending +
            overview.customerRequirementsPending;
      case AdminNavGroup.system:
        return 0;
      case AdminNavGroup.rentalManagement:
        return 0;
      case AdminNavGroup.vault:
        return 0;
    }
  }

  List<AdminNavItem> groupItems(AdminNavGroup group, AppStrings s) {
    switch (group) {
      case AdminNavGroup.rentalManagement:
        return [
          AdminNavItem(
            id: AdminNavId.rentalManagement,
            labelTh: s.adminNavRentalManagement,
            labelEn: 'Rental management',
            icon: Icons.real_estate_agent_outlined,
          ),
        ];
      case AdminNavGroup.assets:
        return [
          AdminNavItem(
            id: AdminNavId.assetRegistry,
            labelTh: s.adminNavAssetRegistry,
            labelEn: 'Asset registry',
            icon: Icons.table_rows_outlined,
            children: [
              AdminNavItem(
                id: AdminNavId.availabilityAlerts,
                labelTh: s.adminNavAvailabilityAlerts,
                labelEn: 'Becoming available',
                icon: Icons.event_available_outlined,
                badgeCount: overview.availabilityAlertsDue,
                subIndent: 1,
              ),
              AdminNavItem(
                id: AdminNavId.hiddenRegistry,
                labelTh: s.adminNavHiddenRegistry,
                labelEn: 'Hidden vault',
                icon: Icons.visibility_off_outlined,
                subIndent: 1,
              ),
            ],
          ),
          AdminNavItem(
            id: AdminNavId.inventory,
            labelTh: s.adminTabInventory,
            labelEn: 'Inventory',
            icon: Icons.inventory_2_outlined,
          ),
          AdminNavItem(
            id: AdminNavId.import,
            labelTh: s.adminTabImport,
            labelEn: 'Import',
            icon: Icons.cloud_download_outlined,
            badgeCount: overview.importsPending,
          ),
          AdminNavItem(
            id: AdminNavId.moderation,
            labelTh: s.adminTabModeration,
            labelEn: 'Moderation',
            icon: Icons.shield_outlined,
            badgeCount: overview.moderationImages + overview.moderationFlags,
          ),
          AdminNavItem(
            id: AdminNavId.projects,
            labelTh: s.adminTabProjects,
            labelEn: 'Projects',
            icon: Icons.apartment_outlined,
          ),
        ];
      case AdminNavGroup.customers:
        return [
          AdminNavItem(
            id: AdminNavId.participant360,
            labelTh: s.adminNavParticipant360,
            labelEn: 'Participant 360°',
            icon: Icons.account_tree_outlined,
          ),
          AdminNavItem(
            id: AdminNavId.viewingCalendar,
            labelTh: s.adminNavViewingCalendar,
            labelEn: 'Viewing calendar',
            icon: Icons.calendar_month_outlined,
            badgeCount: overview.viewingCalendarBadge,
          ),
          AdminNavItem(
            id: AdminNavId.appointments,
            labelTh: s.adminTabAppointmentsList,
            labelEn: 'Viewing list & map',
            icon: Icons.event_outlined,
            subIndent: 1,
          ),
          AdminNavItem(
            id: AdminNavId.offers,
            labelTh: s.adminTabOffers,
            labelEn: 'Offers',
            icon: Icons.local_offer_outlined,
            badgeCount: overview.offersPending,
          ),
          AdminNavItem(
            id: AdminNavId.requirements,
            labelTh: s.adminNavRequirements,
            labelEn: 'Requirements',
            icon: Icons.assignment_outlined,
            badgeCount: overview.customerRequirementsPending,
          ),
        ];
      case AdminNavGroup.system:
        return [
          AdminNavItem(
            id: AdminNavId.reports,
            labelTh: s.adminTabReports,
            labelEn: 'Reports',
            icon: Icons.bar_chart_outlined,
          ),
          AdminNavItem(
            id: AdminNavId.boardCreate,
            labelTh: s.adminTabCreateBoard,
            labelEn: 'Create board',
            icon: Icons.post_add_outlined,
          ),
          AdminNavItem(
            id: AdminNavId.promos,
            labelTh: s.adminTabPromos,
            labelEn: 'Promos',
            icon: Icons.campaign_outlined,
          ),
          AdminNavItem(
            id: AdminNavId.watermark,
            labelTh: s.adminTabWatermark,
            labelEn: 'Watermark',
            icon: Icons.branding_watermark_outlined,
          ),
        ];
      case AdminNavGroup.vault:
        if (!canSeeVault) return [];
        return [
          AdminNavItem(
            id: AdminNavId.vault,
            labelTh: s.adminNavVault,
            labelEn: 'Vault',
            icon: Icons.lock_outline,
          ),
          AdminNavItem(
            id: AdminNavId.accessRequests,
            labelTh: s.adminNavAccessRequests,
            labelEn: 'Access requests',
            icon: Icons.key_outlined,
          ),
          if (isCeo)
            AdminNavItem(
              id: AdminNavId.org,
              labelTh: s.adminNavOrg,
              labelEn: 'Organization',
              icon: Icons.groups_outlined,
              ceoOnly: true,
            ),
        ];
    }
  }

  String groupLabel(AdminNavGroup group, AppStrings s) {
    switch (group) {
      case AdminNavGroup.assets:
        return s.adminNavGroupAssets;
      case AdminNavGroup.rentalManagement:
        return s.adminNavGroupRentalManagement;
      case AdminNavGroup.customers:
        return s.adminNavGroupCustomers;
      case AdminNavGroup.system:
        return s.adminNavGroupSystem;
      case AdminNavGroup.vault:
        return s.adminNavGroupVault;
    }
  }

  IconData groupIcon(AdminNavGroup group) {
    switch (group) {
      case AdminNavGroup.assets:
        return Icons.home_work_outlined;
      case AdminNavGroup.rentalManagement:
        return Icons.real_estate_agent_outlined;
      case AdminNavGroup.customers:
        return Icons.people_outline;
      case AdminNavGroup.system:
        return Icons.settings_outlined;
      case AdminNavGroup.vault:
        return Icons.admin_panel_settings_outlined;
    }
  }

  List<AdminNavId> navIdsInGroup(AdminNavGroup group) {
    switch (group) {
      case AdminNavGroup.assets:
        return [
          AdminNavId.assetRegistry,
          AdminNavId.availabilityAlerts,
          AdminNavId.hiddenRegistry,
          AdminNavId.inventory,
          AdminNavId.import,
          AdminNavId.moderation,
          AdminNavId.projects,
        ];
      case AdminNavGroup.rentalManagement:
        return [AdminNavId.rentalManagement];
      case AdminNavGroup.customers:
        return [
          AdminNavId.participant360,
          AdminNavId.viewingCalendar,
          AdminNavId.appointments,
          AdminNavId.offers,
          AdminNavId.requirements,
        ];
      case AdminNavGroup.system:
        return [
          AdminNavId.reports,
          AdminNavId.boardCreate,
          AdminNavId.promos,
          AdminNavId.watermark,
        ];
      case AdminNavGroup.vault:
        if (!canSeeVault) return [];
        final ids = [AdminNavId.vault, AdminNavId.accessRequests];
        if (isCeo) ids.add(AdminNavId.org);
        return ids;
    }
  }

  List<AdminNavGroup> get visibleGroups {
    if (isViewingStaffOnly) return const [];
    final groups = [
      AdminNavGroup.assets,
      AdminNavGroup.rentalManagement,
      AdminNavGroup.customers,
      AdminNavGroup.system,
    ];
    if (canSeeVault) groups.add(AdminNavGroup.vault);
    return groups;
  }

  /// แมป KPI bar (index เดิม) → nav id
  static AdminNavId? fromLegacyTabIndex(int index) {
    switch (index) {
      case 0:
        return AdminNavId.dashboard;
      case 1:
        return AdminNavId.inbox;
      case 2:
        return AdminNavId.offers;
      case 3:
        return AdminNavId.leads;
      case 4:
        return AdminNavId.viewingCalendar;
      case 5:
        return AdminNavId.reports;
      case 6:
        return AdminNavId.moderation;
      case 7:
        return AdminNavId.inventory;
      case 8:
        return AdminNavId.boardCreate;
      case 9:
        return AdminNavId.import;
      case 10:
        return AdminNavId.projects;
      default:
        return null;
    }
  }
}
