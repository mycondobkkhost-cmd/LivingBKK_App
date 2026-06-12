import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../models/platform_stats_summary.dart';
import '../../services/admin_repository.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';
import '../../widgets/admin_attention_badge.dart';
import '../../widgets/admin_dashboard_bar.dart';
import 'admin_inbox_preview.dart';
import 'admin_nav_model.dart';

/// ภาพรวมแพลตฟอร์ม — หน้าแรกหลังบ้าน (กระชับ ไม่เน้นไอคอน)
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key, this.onOpenNav});

  final void Function(AdminNavId id)? onOpenNav;

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _admin = AdminRepository();
  bool _loading = true;
  AdminDashboardOverview _data = const AdminDashboardOverview();
  List<Map<String, dynamic>> _platformStats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await ChatService.instance.refreshAdminInbox();
    final overview = await _admin.fetchDashboardOverview();
    final stats = await _admin.platformStatsHistory(days: 7);
    if (!mounted) return;
    setState(() {
      _data = overview;
      _platformStats = stats;
      _loading = false;
    });
  }

  int get _queueUnclaimed =>
      ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.unclaimed).length;

  int get _queueMine =>
      ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.mine).length;

  Duration? _longestWait(AppStrings s) {
    final rooms =
        ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.unclaimed);
    if (rooms.isEmpty) return null;
    var oldest = DateTime.now();
    for (final r in rooms) {
      final at = AdminInboxPreview.previewMessageAtForRoom(r);
      if (at.isBefore(oldest)) oldest = at;
    }
    return DateTime.now().difference(oldest);
  }

  String _formatWait(Duration d, AppStrings s) {
    if (d.inDays >= 1) {
      return s.adminOverviewWaitDays(d.inDays, d.inHours % 24);
    }
    if (d.inHours >= 1) {
      return s.adminOverviewWaitHours(d.inHours, d.inMinutes % 60);
    }
    return s.adminOverviewWaitMinutes(d.inMinutes);
  }

  void _open(AdminNavId id) => widget.onOpenNav?.call(id);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final trend = PlatformStatsSummary.fromRows(_platformStats);
    final modTotal = _data.moderationImages + _data.moderationFlags;
    final attention = _data.attentionTotal;

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final liveQueue = _queueUnclaimed;
        final liveMine = _queueMine;
        final liveWait = _longestWait(s);

        final wide = useAdminWideShell(context);

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(wide ? 20 : 12, wide ? 16 : 8, wide ? 20 : 12, 16),
            children: [
              _CommandCenterHeader(
                attention: attention,
                liveQueue: liveQueue,
              ),
              const SizedBox(height: 14),
              _EnterpriseMetricsRow(
                liveQueue: liveQueue,
                liveMine: liveMine,
                leadsNew: _data.leadsNew,
                chatWaiting: _data.chatWaiting,
                calendarBadge: _data.viewingCalendarBadge,
                offersPending: _data.offersPending,
                onQueue: () => context.go('/admin/console?filter=unclaimed'),
                onInbox: () => context.go('/admin/console'),
                onLeads: () => _open(AdminNavId.leads),
                onCalendar: () => _open(AdminNavId.viewingCalendar),
              ),
              const SizedBox(height: 14),
              AdminDashboardBar(
                data: _data,
                onJump: _open,
              ),
              const SizedBox(height: 10),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OpsConsoleCard(
                        queueCount: liveQueue,
                        mineCount: liveMine,
                        onOpen: () => context.go('/admin/console'),
                        onOpenQueue: () =>
                            context.go('/admin/console?filter=unclaimed'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CalendarLaunchCard(
                        badgeCount: _data.viewingCalendarBadge,
                        pending: _data.appointmentsPending,
                        onOpen: () => _open(AdminNavId.viewingCalendar),
                      ),
                    ),
                  ],
                )
              else ...[
                _OpsConsoleCard(
                queueCount: liveQueue,
                mineCount: liveMine,
                onOpen: () => context.go('/admin/console'),
                onOpenQueue: () =>
                    context.go('/admin/console?filter=unclaimed'),
              ),
              const SizedBox(height: 8),
                _CalendarLaunchCard(
                  badgeCount: _data.viewingCalendarBadge,
                  pending: _data.appointmentsPending,
                  onOpen: () => _open(AdminNavId.viewingCalendar),
                ),
              ],
              const SizedBox(height: 10),
              if (attention > 0 || liveQueue > 0)
                _AlertStrip(
                  text: liveQueue > 0
                      ? s.adminOverviewAlertQueue(liveQueue, attention)
                      : s.adminDashNeedsAction(attention),
                  onTap: () {
                    if (liveQueue > 0) {
                      context.go('/admin/console?filter=unclaimed');
                    } else {
                      _open(AdminNavId.leads);
                    }
                  },
                ),
              _Section(
                title: s.adminOverviewSectionUrgent,
                children: [
                  _Row(
                    label: s.adminOverviewQueueUnclaimed,
                    value: liveQueue,
                    alert: liveQueue > 0,
                    onTap: () => context.go('/admin/console?filter=unclaimed'),
                  ),
                  _Row(
                    label: s.adminOverviewQueueMine,
                    value: liveMine,
                    alert: liveMine > 0,
                    onTap: () => context.go('/admin/console'),
                  ),
                  _Row(
                    label: s.adminDashLeads,
                    value: _data.leadsNew,
                    suffix: s.adminDashLeadsSub(_data.leadsTotal),
                    alert: _data.leadsNew > 0,
                    onTap: () => _open(AdminNavId.leads),
                  ),
                  _Row(
                    label: s.adminDashChat,
                    value: _data.chatWaiting,
                    alert: _data.chatWaiting > 0,
                    onTap: () => _open(AdminNavId.inbox),
                  ),
                ],
              ),
              _Section(
                title: s.adminOverviewSectionPending,
                children: [
                  _Row(
                    label: s.adminDashAppointments,
                    value: _data.appointmentsPending,
                    alert: _data.appointmentsPending > 0,
                    onTap: () => _open(AdminNavId.viewingCalendar),
                  ),
                  _Row(
                    label: s.adminDashOffers,
                    value: _data.offersPending,
                    alert: _data.offersPending > 0,
                    onTap: () => _open(AdminNavId.offers),
                  ),
                  _Row(
                    label: s.adminDashRequirements,
                    value: _data.customerRequirementsPending,
                    alert: _data.customerRequirementsPending > 0,
                    onTap: () => _open(AdminNavId.requirements),
                  ),
                  _Row(
                    label: s.adminDashImports,
                    value: _data.importsPending,
                    alert: _data.importsPending > 0,
                    onTap: () => _open(AdminNavId.import),
                  ),
                ],
              ),
              _Section(
                title: s.adminOverviewSectionRisk,
                children: [
                  _Row(
                    label: s.adminDashModImages,
                    value: _data.moderationImages,
                    alert: _data.moderationImages > 0,
                    onTap: () => _open(AdminNavId.moderation),
                  ),
                  _Row(
                    label: s.adminDashModFlags,
                    value: _data.moderationFlags,
                    alert: _data.moderationFlags > 0,
                    onTap: () => _open(AdminNavId.moderation),
                  ),
                  if (modTotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4),
                      child: Text(
                        s.adminDashModerationSub(
                          _data.moderationImages,
                          _data.moderationFlags,
                        ),
                        style: AdminTheme.caption.copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ),
              _Section(
                title: s.adminOverviewSectionWait,
                children: [
                  _Row(
                    label: s.adminOverviewLongestWaitLabel,
                    value: null,
                    textValue: liveWait != null
                        ? _formatWait(liveWait, s)
                        : s.adminOverviewNoWait,
                    alert: liveWait != null && liveWait.inHours >= 2,
                    onTap: liveQueue > 0
                        ? () => _open(AdminNavId.queue)
                        : null,
                  ),
                  if (liveQueue > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4),
                      child: Text(
                        s.adminOverviewWaitHint(liveQueue),
                        style: AdminTheme.caption.copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ),
              if (_platformStats.isNotEmpty) ...[
                _Section(
                  title: s.adminOverviewSectionUsage,
                  children: [
                    _Row(
                      label: s.adminReportFunnelLeads,
                      value: trend.totalLeads,
                      onTap: () => _open(AdminNavId.reports),
                    ),
                    _Row(
                      label: s.adminReportFunnelAccepted,
                      value: trend.totalAccepted,
                      suffix: s.adminReportRatePercent(
                        (trend.leadAcceptRate * 100).round(),
                      ),
                      onTap: () => _open(AdminNavId.reports),
                    ),
                    _Row(
                      label: s.adminReportFunnelAppts,
                      value: trend.totalAppointments,
                      onTap: () => _open(AdminNavId.reports),
                    ),
                    _Row(
                      label: s.adminReportFunnelConfirmed,
                      value: trend.totalConfirmed,
                      suffix: s.adminReportRatePercent(
                        (trend.apptConfirmRate * 100).round(),
                      ),
                      onTap: () => _open(AdminNavId.reports),
                    ),
                    _Row(
                      label: s.adminOverviewNewUsers7d,
                      value: trend.totalNewLeads,
                      onTap: () => _open(AdminNavId.reports),
                    ),
                  ],
                ),
              ],
              _Section(
                title: s.adminDashSectionCatalog,
                children: [
                  _MiniGrid(cells: [
                    _MiniCell(s.adminDashProjects, _data.projects),
                    _MiniCell(s.adminDashListings, _data.listingsPublished),
                    _MiniCell(s.adminDashUsers, _data.usersTotal),
                    _MiniCell(s.adminDashDemandPosts, _data.demandPostsOpen),
                  ]),
                  const SizedBox(height: 6),
                  _Row(
                    label: s.adminDashListings,
                    value: null,
                    textValue: s.adminDashListingsSub(_data.listingsTotal),
                    onTap: () => _open(AdminNavId.inventory),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _LinkChip(
                    label: s.adminOpenReportsCenter,
                    onTap: () => _open(AdminNavId.reports),
                  ),
                  _LinkChip(
                    label: s.adminOpenConsole,
                    onTap: () => context.go('/admin/console'),
                  ),
                ],
              ),
              if (_data.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    s.adminDashUpdated(
                      DateFormat('HH:mm').format(_data.updatedAt!.toLocal()),
                    ),
                    style: AdminTheme.caption.copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 18, color: AppTheme.error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title,
                style: AdminTheme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                  color: LivingBkkBrand.purplePrimary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.value,
    this.textValue,
    this.suffix,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final int? value;
  final String? textValue;
  final String? suffix;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final display = textValue ?? (value != null ? '$value' : '—');
    final color = alert ? AppTheme.error : AdminTheme.text;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: AdminTheme.textMuted),
              ),
            ),
            if (suffix != null) ...[
              Text(
                suffix!,
                style: AdminTheme.caption.copyWith(fontSize: 10),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              display,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AdminTheme.textMuted.withOpacity(0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.cells});

  final List<_MiniCell> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }
}

class _MiniCell extends StatelessWidget {
  const _MiniCell(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AdminTheme.caption.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CommandCenterHeader extends StatelessWidget {
  const _CommandCenterHeader({
    required this.attention,
    required this.liveQueue,
  });

  final int attention;
  final int liveQueue;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final urgent = liveQueue > 0 || attention > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.adminCommandCenterTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AdminTheme.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.adminCommandCenterSubtitle,
                style: AdminTheme.hint.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        if (urgent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Text(
              liveQueue > 0
                  ? s.adminInboxTabUnclaimed(liveQueue)
                  : s.adminDashNeedsAction(attention),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _EnterpriseMetricsRow extends StatelessWidget {
  const _EnterpriseMetricsRow({
    required this.liveQueue,
    required this.liveMine,
    required this.leadsNew,
    required this.chatWaiting,
    required this.calendarBadge,
    required this.offersPending,
    required this.onQueue,
    required this.onInbox,
    required this.onLeads,
    required this.onCalendar,
  });

  final int liveQueue;
  final int liveMine;
  final int leadsNew;
  final int chatWaiting;
  final int calendarBadge;
  final int offersPending;
  final VoidCallback onQueue;
  final VoidCallback onInbox;
  final VoidCallback onLeads;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900 ? 5 : 2;
        final cellW = (constraints.maxWidth - (cols - 1) * 8) / cols;
        final metrics = [
          _MetricCell(
            label: context.s.adminOverviewQueueUnclaimed,
            value: liveQueue,
            alert: liveQueue > 0,
            icon: Icons.notification_important_outlined,
            onTap: onQueue,
          ),
          _MetricCell(
            label: context.s.adminOverviewQueueMine,
            value: liveMine,
            alert: liveMine > 0,
            icon: Icons.inbox_outlined,
            onTap: onInbox,
          ),
          _MetricCell(
            label: context.s.adminDashLeads,
            value: leadsNew,
            alert: leadsNew > 0,
            icon: Icons.support_agent_outlined,
            onTap: onLeads,
          ),
          _MetricCell(
            label: context.s.adminDashChat,
            value: chatWaiting,
            alert: chatWaiting > 0,
            icon: Icons.forum_outlined,
            onTap: onInbox,
          ),
          _MetricCell(
            label: context.s.adminNavViewingCalendar,
            value: calendarBadge,
            alert: calendarBadge > 0,
            icon: Icons.calendar_month_outlined,
            onTap: onCalendar,
          ),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (m) => SizedBox(
                  width: cellW.clamp(120, constraints.maxWidth),
                  child: m,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.alert,
    required this.icon,
    this.onTap,
  });

  final String label;
  final int value;
  final bool alert;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = alert ? AppTheme.error : LivingBkkBrand.purplePrimary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alert
                  ? AppTheme.error.withOpacity(0.25)
                  : AdminTheme.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const Spacer(),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: accent,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AdminTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpsConsoleCard extends StatelessWidget {
  const _OpsConsoleCard({
    required this.queueCount,
    required this.mineCount,
    required this.onOpen,
    required this.onOpenQueue,
  });

  final int queueCount;
  final int mineCount;
  final VoidCallback onOpen;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final urgent = queueCount > 0;
    return Card(
      color: urgent
          ? AppTheme.error.withOpacity(0.06)
          : LivingBkkBrand.purplePrimary.withOpacity(0.06),
      child: InkWell(
        onTap: urgent ? onOpenQueue : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 10, bottom: 2),
                child: AdminAttentionIconBadge(
                  count: queueCount,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (urgent ? AppTheme.error : LivingBkkBrand.purplePrimary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      color: urgent ? AppTheme.error : LivingBkkBrand.purplePrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.adminOpsOpenConsole,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      urgent
                          ? s.adminInboxTabUnclaimed(queueCount)
                          : s.adminOpsConsoleCardHint,
                      style: AdminTheme.caption,
                    ),
                    if (mineCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        s.adminInboxTabMine(mineCount),
                        style: AdminTheme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: urgent ? AppTheme.error : LivingBkkBrand.purplePrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLaunchCard extends StatelessWidget {
  const _CalendarLaunchCard({
    required this.badgeCount,
    required this.pending,
    required this.onOpen,
  });

  final int badgeCount;
  final int pending;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      color: LivingBkkBrand.purplePrimary.withOpacity(0.06),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 10, bottom: 2),
                child: AdminAttentionIconBadge(
                  count: badgeCount,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LivingBkkBrand.purplePrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: LivingBkkBrand.purplePrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.adminCalendarOpenFromDashboard,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.adminCalendarDashboardHint(pending),
                      style: AdminTheme.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: LivingBkkBrand.purplePrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
