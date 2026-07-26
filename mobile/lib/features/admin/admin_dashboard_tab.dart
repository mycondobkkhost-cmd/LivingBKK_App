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
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';
import '../../widgets/ops/ops_mini_bar_chart.dart';
import 'admin_inbox_preview.dart';
import 'admin_nav_model.dart';
import 'admin_template_theme.dart';

/// ภาพรวมแพลตฟอร์ม — แดชบอร์ดสะอาดแบบตัวอย่าง
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

  int get _queueUnclaimed => ChatService.instance
      .listAdminInbox(bucket: AdminInboxBucket.unclaimed)
      .length;

  int get _queueMine =>
      ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.mine).length;

  void _open(AdminNavId id) => widget.onOpenNav?.call(id);

  List<OpsChartPoint> _leadChartPoints(bool isEnglish) {
    if (_platformStats.isEmpty) return const [];
    return OpsMiniBarChart.fromDailyRows(
      _platformStats,
      isEnglish: isEnglish,
      maxPoints: 7,
      labelBuilder: (date, en) {
        DateTime? d;
        if (date is DateTime) {
          d = date;
        } else if (date != null) {
          d = DateTime.tryParse(date.toString());
        }
        if (d == null) return '—';
        return DateFormat(en ? 'E' : 'E', en ? 'en' : 'th').format(d);
      },
      valuePicker: (row) => (row['lead_count'] as num?)?.toInt() ??
          (row['new_count'] as num?)?.toInt() ??
          0,
    );
  }

  List<_AlertItem> _alerts(AppStrings s) {
    final out = <_AlertItem>[];
    final q = _queueUnclaimed;
    if (q > 0) {
      out.add(
        _AlertItem(
          color: const Color(0xFFE53935),
          text: s.adminOverviewWaitHint(q),
          onTap: () => context.go('/admin/console?filter=unclaimed'),
        ),
      );
    }
    if (_data.leadsNew > 0) {
      out.add(
        _AlertItem(
          color: LivingBkkBrand.accentOrange,
          text: '${s.adminDashKpiLeads}: ${_data.leadsNew}',
          onTap: () => _open(AdminNavId.leads),
        ),
      );
    }
    if (_data.viewingCalendarBadge > 0) {
      out.add(
        _AlertItem(
          color: const Color(0xFF1E88E5),
          text: '${s.adminDashKpiCalendar}: ${_data.viewingCalendarBadge}',
          onTap: () => _open(AdminNavId.viewingCalendar),
        ),
      );
    }
    if (_data.offersPending > 0) {
      out.add(
        _AlertItem(
          color: const Color(0xFF8E24AA),
          text: '${s.adminDashOffers}: ${_data.offersPending}',
          onTap: () => _open(AdminNavId.offers),
        ),
      );
    }
    final mod = _data.moderationImages + _data.moderationFlags;
    if (mod > 0) {
      out.add(
        _AlertItem(
          color: const Color(0xFFD81B60),
          text: s.adminDashModerationSub(
            _data.moderationImages,
            _data.moderationFlags,
          ),
          onTap: () => _open(AdminNavId.moderation),
        ),
      );
    }
    if (_data.availabilityAlertsDue > 0) {
      out.add(
        _AlertItem(
          color: LivingBkkBrand.serviceGreen,
          text: '${s.adminDashKpiAlerts}: ${_data.availabilityAlertsDue}',
          onTap: () => _open(AdminNavId.availabilityAlerts),
        ),
      );
    }
    return out;
  }

  List<_ActivityItem> _activity(AppStrings s) {
    final rooms = [
      ...ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.unclaimed),
      ...ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.mine),
    ];
    rooms.sort((a, b) {
      final at = AdminInboxPreview.previewMessageAtForRoom(a);
      final bt = AdminInboxPreview.previewMessageAtForRoom(b);
      return bt.compareTo(at);
    });
    final fmt = DateFormat(s.isEnglish ? 'HH:mm' : 'HH:mm');
    return rooms.take(6).map((room) {
      final preview = AdminInboxPreview.fromRoom(room, s);
      return _ActivityItem(
        time: fmt.format(preview.previewMessageAt),
        text: preview.titleLine,
        tag: preview.intentLabel,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final wide = useAdminWideShell(context);
    final pad = wide ? 20.0 : 12.0;
    final chartPoints = _leadChartPoints(s.isEnglish);
    final trend = PlatformStatsSummary.fromRows(_platformStats);
    final alerts = _alerts(s);
    final activity = _activity(s);
    final modTotal = _data.moderationImages + _data.moderationFlags;

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final liveQueue = _queueUnclaimed;
        final liveMine = _queueMine;

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 24),
            children: [
              _ColorKpiRow(
                wide: wide,
                items: [
                  _KpiSpec(
                    label: s.adminDashKpiQueue,
                    value: '$liveQueue',
                    footer: liveQueue > 0
                        ? s.adminDashStatusBusy
                        : s.adminDashStatusIdle,
                    color: const Color(0xFFE53935),
                    icon: Icons.forum_outlined,
                    onTap: () =>
                        context.go('/admin/console?filter=unclaimed'),
                  ),
                  _KpiSpec(
                    label: s.adminDashKpiMine,
                    value: '$liveMine',
                    footer: s.adminOverviewQueueMine,
                    color: LivingBkkBrand.accentOrange,
                    icon: Icons.person_outline,
                    onTap: () => context.go('/admin/console'),
                  ),
                  _KpiSpec(
                    label: s.adminDashKpiLeads,
                    value: '${_data.leadsNew}',
                    footer: s.adminDashLeadsSub(_data.leadsTotal),
                    color: const Color(0xFF1E88E5),
                    icon: Icons.person_search_outlined,
                    onTap: () => _open(AdminNavId.leads),
                  ),
                  _KpiSpec(
                    label: s.adminDashKpiCalendar,
                    value: '${_data.viewingCalendarBadge}',
                    footer: s.adminDashAppointments,
                    color: const Color(0xFF8E24AA),
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _open(AdminNavId.viewingCalendar),
                  ),
                  _KpiSpec(
                    label: s.adminDashKpiListings,
                    value: '${_data.listingsPublished}',
                    footer:
                        '${s.adminDashStockTotal} ${_data.listingsTotal}',
                    color: LivingBkkBrand.serviceGreen,
                    icon: Icons.home_work_outlined,
                    onTap: () => _open(AdminNavId.assetRegistry),
                  ),
                  _KpiSpec(
                    label: s.adminDashKpiAlerts,
                    value: '${_data.availabilityAlertsDue}',
                    footer: modTotal > 0
                        ? s.adminDashModerationSub(
                            _data.moderationImages,
                            _data.moderationFlags,
                          )
                        : s.adminDashStatusIdle,
                    color: const Color(0xFFD81B60),
                    icon: Icons.notifications_active_outlined,
                    onTap: () => _open(
                      _data.availabilityAlertsDue > 0
                          ? AdminNavId.availabilityAlerts
                          : AdminNavId.moderation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ChartCard(
                          title: s.adminDashChartTitle,
                          totalLabel:
                              '${s.adminDashChartTotal} ${trend.totalLeads}',
                          points: chartPoints,
                          onOpenReports: () => _open(AdminNavId.reports),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _StatusGridCard(
                          title: s.adminDashStatusTitle,
                          cells: [
                            _StatusCell(
                              label: s.adminDashStatusQueue,
                              busy: liveQueue > 0,
                              count: liveQueue,
                              busyColor: const Color(0xFFE53935),
                              onTap: () => context
                                  .go('/admin/console?filter=unclaimed'),
                            ),
                            _StatusCell(
                              label: s.adminDashStatusCalendar,
                              busy: _data.viewingCalendarBadge > 0,
                              count: _data.viewingCalendarBadge,
                              busyColor: LivingBkkBrand.accentOrange,
                              onTap: () =>
                                  _open(AdminNavId.viewingCalendar),
                            ),
                            _StatusCell(
                              label: s.adminDashStatusOffers,
                              busy: _data.offersPending > 0,
                              count: _data.offersPending,
                              busyColor: const Color(0xFF8E24AA),
                              onTap: () => _open(AdminNavId.offers),
                            ),
                            _StatusCell(
                              label: s.adminDashStatusMod,
                              busy: modTotal > 0,
                              count: modTotal,
                              busyColor: const Color(0xFFD81B60),
                              onTap: () => _open(AdminNavId.moderation),
                            ),
                          ],
                          idleLabel: s.adminDashStatusIdle,
                          busyLabel: s.adminDashStatusBusy,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _ChartCard(
                  title: s.adminDashChartTitle,
                  totalLabel: '${s.adminDashChartTotal} ${trend.totalLeads}',
                  points: chartPoints,
                  onOpenReports: () => _open(AdminNavId.reports),
                ),
                const SizedBox(height: 14),
                _StatusGridCard(
                  title: s.adminDashStatusTitle,
                  cells: [
                    _StatusCell(
                      label: s.adminDashStatusQueue,
                      busy: liveQueue > 0,
                      count: liveQueue,
                      busyColor: const Color(0xFFE53935),
                      onTap: () =>
                          context.go('/admin/console?filter=unclaimed'),
                    ),
                    _StatusCell(
                      label: s.adminDashStatusCalendar,
                      busy: _data.viewingCalendarBadge > 0,
                      count: _data.viewingCalendarBadge,
                      busyColor: LivingBkkBrand.accentOrange,
                      onTap: () => _open(AdminNavId.viewingCalendar),
                    ),
                    _StatusCell(
                      label: s.adminDashStatusOffers,
                      busy: _data.offersPending > 0,
                      count: _data.offersPending,
                      busyColor: const Color(0xFF8E24AA),
                      onTap: () => _open(AdminNavId.offers),
                    ),
                    _StatusCell(
                      label: s.adminDashStatusMod,
                      busy: modTotal > 0,
                      count: modTotal,
                      busyColor: const Color(0xFFD81B60),
                      onTap: () => _open(AdminNavId.moderation),
                    ),
                  ],
                  idleLabel: s.adminDashStatusIdle,
                  busyLabel: s.adminDashStatusBusy,
                ),
              ],
              const SizedBox(height: 14),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StockCard(
                          title: s.adminDashStockTitle,
                          published: _data.listingsPublished,
                          total: _data.listingsTotal,
                          publishedLabel: s.adminDashStockPublished,
                          totalLabel: s.adminDashStockTotal,
                          onTap: () => _open(AdminNavId.assetRegistry),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _AlertsCard(
                          title: s.adminDashAlertsTitle,
                          empty: s.adminDashNoAlerts,
                          items: alerts,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActivityCard(
                          title: s.adminDashActivityTitle,
                          empty: s.adminDashNoActivity,
                          items: activity,
                          onOpenInbox: () => context.go('/admin/console'),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _StockCard(
                  title: s.adminDashStockTitle,
                  published: _data.listingsPublished,
                  total: _data.listingsTotal,
                  publishedLabel: s.adminDashStockPublished,
                  totalLabel: s.adminDashStockTotal,
                  onTap: () => _open(AdminNavId.assetRegistry),
                ),
                const SizedBox(height: 14),
                _AlertsCard(
                  title: s.adminDashAlertsTitle,
                  empty: s.adminDashNoAlerts,
                  items: alerts,
                ),
                const SizedBox(height: 14),
                _ActivityCard(
                  title: s.adminDashActivityTitle,
                  empty: s.adminDashNoActivity,
                  items: activity,
                  onOpenInbox: () => context.go('/admin/console'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _KpiSpec {
  const _KpiSpec({
    required this.label,
    required this.value,
    required this.footer,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String footer;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
}

class _ColorKpiRow extends StatelessWidget {
  const _ColorKpiRow({required this.items, required this.wide});

  final List<_KpiSpec> items;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 34) / 2,
              child: _ColorKpiCard(item: item),
            ),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _ColorKpiCard(item: items[i])),
        ],
      ],
    );
  }
}

class _ColorKpiCard extends StatelessWidget {
  const _ColorKpiCard({required this.item});

  final _KpiSpec item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(AdminTemplateTheme.cardRadius),
      elevation: 0,
      shadowColor: item.color.withOpacity(0.35),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AdminTemplateTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.footer,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTemplateTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTemplateTheme.cardRadius),
        boxShadow: AdminTemplateTheme.cardShadow,
        border: Border.all(color: AdminTheme.border.withOpacity(0.7)),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTemplateTheme.cardRadius),
        child: body,
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.totalLabel,
    required this.points,
    required this.onOpenReports,
  });

  final String title;
  final String totalLabel;
  final List<OpsChartPoint> points;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AdminTemplateTheme.textPrimary,
                  ),
                ),
              ),
              Material(
                color: LivingBkkBrand.brandRedTint,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onOpenReports,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      totalLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LivingBkkBrand.brandRedDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OpsMiniBarChart(
            title: '',
            points: points,
            color: LivingBkkBrand.accentOrange,
            maxBarHeight: 96,
          ),
        ],
      ),
    );
  }
}

class _StatusCell {
  const _StatusCell({
    required this.label,
    required this.busy,
    required this.count,
    required this.busyColor,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final int count;
  final Color busyColor;
  final VoidCallback onTap;
}

class _StatusGridCard extends StatelessWidget {
  const _StatusGridCard({
    required this.title,
    required this.cells,
    required this.idleLabel,
    required this.busyLabel,
  });

  final String title;
  final List<_StatusCell> cells;
  final String idleLabel;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdminTemplateTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.35,
            children: [
              for (final cell in cells)
                Material(
                  color: cell.busy
                      ? cell.busyColor
                      : LivingBkkBrand.serviceGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: cell.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cell.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${cell.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: const Color(0xFFE53935), label: busyLabel),
              const SizedBox(width: 12),
              _LegendDot(color: LivingBkkBrand.serviceGreen, label: idleLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AdminTemplateTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.title,
    required this.published,
    required this.total,
    required this.publishedLabel,
    required this.totalLabel,
    required this.onTap,
  });

  final String title;
  final int published;
  final int total;
  final String publishedLabel;
  final String totalLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (published / total).clamp(0.0, 1.0);
    return _DashCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdminTemplateTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _StockBar(
            label: publishedLabel,
            value: published,
            ratio: ratio,
            color: LivingBkkBrand.brandRed,
          ),
          const SizedBox(height: 12),
          _StockBar(
            label: totalLabel,
            value: total,
            ratio: 1,
            color: LivingBkkBrand.accentOrange.withOpacity(0.55),
          ),
        ],
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  const _StockBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AdminTemplateTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AdminTemplateTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AdminTheme.surfaceMuted,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.color,
    required this.text,
    required this.onTap,
  });

  final Color color;
  final String text;
  final VoidCallback onTap;
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.title,
    required this.empty,
    required this.items,
  });

  final String title;
  final String empty;
  final List<_AlertItem> items;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdminTemplateTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              empty,
              style: const TextStyle(
                fontSize: 13,
                color: AdminTemplateTheme.textMuted,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.text,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AdminTemplateTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.time,
    required this.text,
    required this.tag,
  });

  final String time;
  final String text;
  final String tag;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.empty,
    required this.items,
    required this.onOpenInbox,
  });

  final String title;
  final String empty;
  final List<_ActivityItem> items;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      onTap: onOpenInbox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdminTemplateTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              empty,
              style: const TextStyle(
                fontSize: 13,
                color: AdminTemplateTheme.textMuted,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AdminTemplateTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: AdminTemplateTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: LivingBkkBrand.brandRedTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: LivingBkkBrand.brandRedDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
