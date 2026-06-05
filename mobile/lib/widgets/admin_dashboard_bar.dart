import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/admin_dashboard_overview.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';

/// แถบ KPI ด้านบนศูนย์แอดมิน — กดเพื่อไปแท็บที่เกี่ยวข้อง
class AdminDashboardBar extends StatelessWidget {
  const AdminDashboardBar({
    super.key,
    required this.data,
    required this.onJump,
    this.compact = false,
  });

  final AdminDashboardOverview data;
  final void Function(int tabIndex) onJump;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tiles = [
      _Tile(s.adminDashProjects, data.projects, 9, Icons.apartment_outlined),
      _Tile(s.adminDashListings, data.listingsPublished, -1, Icons.home_work_outlined,
          subtitle: s.adminDashListingsSub(data.listingsTotal)),
      _Tile(s.adminDashLeads, data.leadsNew, 3, Icons.support_agent_outlined,
          subtitle: s.adminDashLeadsSub(data.leadsTotal), alert: data.leadsNew > 0),
      _Tile(s.adminDashChat, data.chatWaiting, 1, Icons.chat_bubble_outline,
          alert: data.chatWaiting > 0),
      _Tile(s.adminDashAppointments, data.appointmentsPending, 4, Icons.event_outlined,
          alert: data.appointmentsPending > 0),
      _Tile(s.adminDashOffers, data.offersPending, 2, Icons.local_offer_outlined,
          alert: data.offersPending > 0),
      _Tile(s.adminDashModeration, data.moderationImages + data.moderationFlags, 6,
          Icons.shield_outlined,
          subtitle: s.adminDashModerationSub(data.moderationImages, data.moderationFlags),
          alert: data.moderationImages + data.moderationFlags > 0),
      _Tile(s.adminDashImports, data.importsPending, 8, Icons.cloud_download_outlined,
          alert: data.importsPending > 0),
    ];

    return Material(
      color: LivingBkkBrand.adminBg,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, compact ? 8 : 12, 12, compact ? 8 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  s.adminDashboardBarTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const Spacer(),
                if (data.attentionTotal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s.adminDashNeedsAction(data.attentionTotal),
                      style: TextStyle(fontSize: 11, color: AppTheme.error, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: compact ? 72 : 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = tiles[i];
                  return _KpiChip(
                    label: t.label,
                    value: t.value,
                    subtitle: t.subtitle,
                    icon: t.icon,
                    alert: t.alert,
                    onTap: t.tabIndex >= 0 ? () => onJump(t.tabIndex) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.label, this.value, this.tabIndex, this.icon,
      {this.subtitle, this.alert = false});
  final String label;
  final int value;
  final int tabIndex;
  final IconData icon;
  final String? subtitle;
  final bool alert;
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final String? subtitle;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 118,
        decoration: BoxDecoration(
          color: alert ? AppTheme.error.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert ? AppTheme.error.withOpacity(0.35) : AppTheme.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: alert ? AppTheme.error : AppTheme.primary),
                const Spacer(),
                Text(
                  '$value',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: alert ? AppTheme.error : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withOpacity(0.85)),
              ),
          ],
        ),
      ),
    );
  }
}
