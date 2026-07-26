import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'admin_nav_model.dart';

/// โซนหลักหลังบ้าน — ออกแบบสำหรับองค์กรขนาดใหญ่ (module-first)
enum AdminEnterpriseZone {
  command,
  comms,
  calendar,
  operations,
  assets,
  rental,
  system,
  vault,
}

AdminEnterpriseZone adminZoneForNav(AdminNavId id) {
  switch (id) {
    case AdminNavId.dashboard:
      return AdminEnterpriseZone.command;
    case AdminNavId.queue:
    case AdminNavId.leads:
    case AdminNavId.inbox:
      return AdminEnterpriseZone.comms;
    case AdminNavId.viewingCalendar:
    case AdminNavId.appointments:
      return AdminEnterpriseZone.calendar;
    case AdminNavId.offers:
    case AdminNavId.requirements:
    case AdminNavId.participant360:
      return AdminEnterpriseZone.operations;
    case AdminNavId.assetRegistry:
    case AdminNavId.availabilityAlerts:
    case AdminNavId.hiddenRegistry:
    case AdminNavId.inventory:
    case AdminNavId.import:
    case AdminNavId.moderation:
    case AdminNavId.projects:
      return AdminEnterpriseZone.assets;
    case AdminNavId.rentalManagement:
      return AdminEnterpriseZone.rental;
    case AdminNavId.reports:
    case AdminNavId.boardCreate:
    case AdminNavId.promos:
    case AdminNavId.watermark:
      return AdminEnterpriseZone.system;
    case AdminNavId.vault:
    case AdminNavId.accessRequests:
    case AdminNavId.org:
      return AdminEnterpriseZone.vault;
  }
}

List<AdminEnterpriseZone> adminVisibleZones(AdminNavConfig config) {
  if (config.isViewingStaffOnly) {
    return const [AdminEnterpriseZone.calendar];
  }
  final zones = [
    AdminEnterpriseZone.command,
    AdminEnterpriseZone.comms,
    AdminEnterpriseZone.calendar,
    AdminEnterpriseZone.operations,
    AdminEnterpriseZone.assets,
    AdminEnterpriseZone.rental,
    AdminEnterpriseZone.system,
  ];
  if (config.canSeeVault) zones.add(AdminEnterpriseZone.vault);
  return zones;
}

List<AdminNavItem> adminZoneNavItems(
  AdminEnterpriseZone zone,
  AdminNavConfig config,
  AppStrings s,
) {
  switch (zone) {
    case AdminEnterpriseZone.command:
      return [
        AdminNavItem(
          id: AdminNavId.dashboard,
          labelTh: s.adminTabDashboard,
          labelEn: 'Command center',
          icon: Icons.dashboard_outlined,
        ),
      ];
    case AdminEnterpriseZone.comms:
      final queue = config.queueUnclaimedCount;
      final mine = config.inboxMineCount;
      final leads = config.overview.leadsNew;
      return [
        AdminNavItem(
          id: AdminNavId.queue,
          labelTh: s.adminNavQueueTitle,
          labelEn: 'Unclaimed queue',
          icon: Icons.notification_important_outlined,
          badgeCount: queue,
          urgent: queue > 0,
        ),
        AdminNavItem(
          id: AdminNavId.inbox,
          labelTh: s.adminTabChat,
          labelEn: 'My inbox',
          icon: Icons.inbox_outlined,
          badgeCount: mine,
          urgent: mine > 0,
        ),
        AdminNavItem(
          id: AdminNavId.leads,
          labelTh: s.adminTabLeads,
          labelEn: 'Leads',
          icon: Icons.support_agent_outlined,
          badgeCount: leads,
          urgent: leads > 0,
        ),
      ];
    case AdminEnterpriseZone.calendar:
      return [
        AdminNavItem(
          id: AdminNavId.viewingCalendar,
          labelTh: s.adminNavViewingCalendar,
          labelEn: 'Viewing calendar',
          icon: Icons.calendar_month_outlined,
          badgeCount: config.overview.viewingCalendarBadge,
          urgent: config.overview.viewingCalendarBadge > 0,
        ),
        AdminNavItem(
          id: AdminNavId.appointments,
          labelTh: s.adminTabAppointmentsList,
          labelEn: 'Viewing list & map',
          icon: Icons.map_outlined,
          subIndent: 1,
        ),
      ];
    case AdminEnterpriseZone.operations:
      return config
          .groupItems(AdminNavGroup.customers, s)
          .where(
            (item) =>
                item.id != AdminNavId.viewingCalendar &&
                item.id != AdminNavId.appointments,
          )
          .toList();
    case AdminEnterpriseZone.assets:
      return config.groupItems(AdminNavGroup.assets, s);
    case AdminEnterpriseZone.rental:
      return config.groupItems(AdminNavGroup.rentalManagement, s);
    case AdminEnterpriseZone.system:
      return config.groupItems(AdminNavGroup.system, s);
    case AdminEnterpriseZone.vault:
      return config.groupItems(AdminNavGroup.vault, s);
  }
}

int adminZoneBadgeCount(AdminEnterpriseZone zone, AdminNavConfig config) {
  switch (zone) {
    case AdminEnterpriseZone.command:
      return config.overview.attentionTotal;
    case AdminEnterpriseZone.comms:
      return config.queueUnclaimedCount +
          config.inboxMineCount +
          config.overview.leadsNew;
    case AdminEnterpriseZone.calendar:
      return config.overview.viewingCalendarBadge;
    case AdminEnterpriseZone.operations:
      return config.badgeForGroup(AdminNavGroup.customers) -
          config.overview.viewingCalendarBadge;
    case AdminEnterpriseZone.assets:
      return config.badgeForGroup(AdminNavGroup.assets);
    case AdminEnterpriseZone.rental:
      return 0;
    case AdminEnterpriseZone.system:
      return 0;
    case AdminEnterpriseZone.vault:
      return 0;
  }
}

bool adminZoneUrgent(AdminEnterpriseZone zone, AdminNavConfig config) {
  switch (zone) {
    case AdminEnterpriseZone.comms:
      return config.queueUnclaimedCount > 0;
    case AdminEnterpriseZone.calendar:
      return config.overview.viewingCalendarBadge > 0;
    case AdminEnterpriseZone.operations:
      return config.overview.offersPending > 0 ||
          config.overview.customerRequirementsPending > 0;
    case AdminEnterpriseZone.assets:
      return config.badgeForGroup(AdminNavGroup.assets) > 0;
    default:
      return adminZoneBadgeCount(zone, config) > 0;
  }
}

String adminZoneLabel(AdminEnterpriseZone zone, AppStrings s) {
  switch (zone) {
    case AdminEnterpriseZone.command:
      return s.adminZoneCommand;
    case AdminEnterpriseZone.comms:
      return s.adminZoneComms;
    case AdminEnterpriseZone.calendar:
      return s.adminZoneCalendar;
    case AdminEnterpriseZone.operations:
      return s.adminZoneOperations;
    case AdminEnterpriseZone.assets:
      return s.adminZoneAssets;
    case AdminEnterpriseZone.rental:
      return s.adminZoneRental;
    case AdminEnterpriseZone.system:
      return s.adminZoneSystem;
    case AdminEnterpriseZone.vault:
      return s.adminZoneVault;
  }
}

IconData adminZoneIcon(AdminEnterpriseZone zone) {
  switch (zone) {
    case AdminEnterpriseZone.command:
      return Icons.hub_outlined;
    case AdminEnterpriseZone.comms:
      return Icons.forum_outlined;
    case AdminEnterpriseZone.calendar:
      return Icons.calendar_month_outlined;
    case AdminEnterpriseZone.operations:
      return Icons.handshake_outlined;
    case AdminEnterpriseZone.assets:
      return Icons.domain_outlined;
    case AdminEnterpriseZone.rental:
      return Icons.real_estate_agent_outlined;
    case AdminEnterpriseZone.system:
      return Icons.tune_outlined;
    case AdminEnterpriseZone.vault:
      return Icons.shield_outlined;
  }
}

/// KPI สรุปบน top bar
class AdminEnterpriseKpi {
  const AdminEnterpriseKpi({
    required this.label,
    required this.value,
    this.alert = false,
  });

  final String label;
  final int value;
  final bool alert;
}

List<AdminEnterpriseKpi> adminEnterpriseKpis(AdminNavConfig config, AppStrings s) {
  final o = config.overview;
  return [
    AdminEnterpriseKpi(
      label: s.adminOverviewQueueUnclaimed,
      value: config.queueUnclaimedCount,
      alert: config.queueUnclaimedCount > 0,
    ),
    AdminEnterpriseKpi(
      label: s.adminDashLeads,
      value: o.leadsNew,
      alert: o.leadsNew > 0,
    ),
    AdminEnterpriseKpi(
      label: s.adminDashChat,
      value: o.chatWaiting,
      alert: o.chatWaiting > 0,
    ),
    AdminEnterpriseKpi(
      label: s.adminNavViewingCalendar,
      value: o.viewingCalendarBadge,
      alert: o.viewingCalendarBadge > 0,
    ),
  ];
}
