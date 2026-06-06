import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../data/error_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/analytics_period_stats.dart';
import '../../models/analytics_platform_daily.dart';
import '../../models/platform_stats_summary.dart';
import '../../services/admin_repository.dart';
import '../../services/analytics_admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/ops/ops_funnel_strip.dart';
import '../../widgets/ops/ops_mini_bar_chart.dart';
import '../../widgets/ops/ops_period_chips.dart';
import '../../widgets/ops/ops_summary_metrics.dart';

/// ศูนย์รายงานครบชุด — รองรับ scale ผ่าน rollup tables
class AdminAnalyticsHub extends StatefulWidget {
  const AdminAnalyticsHub({super.key});

  @override
  State<AdminAnalyticsHub> createState() => _AdminAnalyticsHubState();
}

class _AdminAnalyticsHubState extends State<AdminAnalyticsHub>
    with SingleTickerProviderStateMixin {
  final _analytics = AnalyticsAdminRepository();
  final _admin = AdminRepository();
  late final TabController _tabs;

  int _days = 14;
  int _periodHours = 24;
  bool _densePeriod = true;
  bool _loading = true;
  bool _refreshingRollup = false;
  List<AnalyticsPlatformDaily> _platform = [];
  List<AnalyticsPlatformDaily> _previous = [];
  List<AnalyticsPeriodStats> _periodStats = [];
  List<AnalyticsDistrictRow> _districts = [];
  List<AnalyticsChatDailyRow> _chat = [];
  List<AnalyticsListingDailyRow> _listings = [];
  List<ClientErrorSummaryRow> _errors = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final platform = await _analytics.platformDaily(days: _days);
    final prev = await _analytics.platformDaily(days: _days * 2);
    final previous = prev.length > _days ? prev.sublist(_days) : <AnalyticsPlatformDaily>[];
    final districts = await _analytics.districtBreakdown(days: _days);
    final chat = await _analytics.chatBreakdown(days: _days);
    final listings = await _analytics.topListings(days: _days);
    final period = await _analytics.periodStats(periodHours: _periodHours, buckets: 14);
    final errors = await _analytics.errorSummary();
    if (!mounted) return;
    setState(() {
      _platform = platform;
      _previous = previous;
      _periodStats = period;
      _districts = districts;
      _chat = chat;
      _listings = listings;
      _errors = errors;
      _loading = false;
    });
  }

  Future<void> _rollupRefresh() async {
    setState(() => _refreshingRollup = true);
    await _analytics.refreshRollups(days: _days);
    await _analytics.refreshPeriodRollups(periodHours: _periodHours, buckets: 14);
    await _load();
    if (!mounted) return;
    setState(() => _refreshingRollup = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminAnalyticsRefreshed)),
    );
  }

  Future<void> _copyTsv() async {
    final tsv = await _admin.buildPlatformStatsTsv(days: _days);
    await Clipboard.setData(ClipboardData(text: tsv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminTsvCopied)),
    );
  }

  AnalyticsPeriodTotals get _current => AnalyticsPeriodTotals(rows: _platform);
  AnalyticsPeriodTotals get _prior => AnalyticsPeriodTotals(rows: _previous);

  String _delta(int current, int prior, AppStrings s) {
    if (prior == 0) return current > 0 ? s.adminAnalyticsDeltaNew : '—';
    final pct = ((current - prior) / prior * 100).round();
    return s.adminAnalyticsDeltaPct(pct);
  }

  String _pct(double rate, AppStrings s) =>
      s.adminReportRatePercent((rate * 100).round());

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AdminTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.adminReportsCenterTitle,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    if (_refreshingRollup)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: s.adminAnalyticsRefreshRollup,
                        icon: const Icon(Icons.sync),
                        onPressed: _rollupRefresh,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  Env.isConfigured ? s.adminAnalyticsServerHint : s.adminReportsDemo,
                  style: AdminTheme.hint,
                ),
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: [
                  Tab(text: s.adminAnalyticsTabOverview),
                  Tab(text: s.adminAnalyticsTabFunnel),
                  Tab(text: s.adminAnalyticsTabGeo),
                  Tab(text: s.adminAnalyticsTabChat),
                  Tab(text: s.adminAnalyticsTabListings),
                  Tab(text: s.adminAnalyticsTabApp),
                  Tab(text: s.adminAnalyticsTabErrors),
                  Tab(text: s.adminAnalyticsTabExport),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.adminAnalyticsPeriodHint, style: AdminTheme.hint),
              const SizedBox(height: 6),
              OpsPeriodChips(
                value: _densePeriod ? _periodHours : 0,
                onChanged: (v) {
                  if (v == 0) {
                    setState(() => _densePeriod = false);
                  } else {
                    setState(() {
                      _densePeriod = true;
                      _periodHours = v;
                    });
                  }
                  _load();
                },
                labels: {
                  12: s.adminAnalyticsPeriod12h,
                  24: s.adminAnalyticsPeriod24h,
                  0: s.adminAnalyticsPeriodDaily,
                },
              ),
              if (!_densePeriod) ...[
                const SizedBox(height: 8),
                OpsPeriodChips(
                  value: _days,
                  onChanged: (d) {
                    setState(() => _days = d);
                    _load();
                  },
                  labels: {
                    7: s.adminReportDays7,
                    14: s.adminReportDays14,
                    30: s.adminReportDays30,
                  },
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(s),
                    _funnelTab(s),
                    _geoTab(s),
                    _chatTab(s),
                    _listingsTab(s),
                    _appTab(s),
                    _errorsTab(s),
                    _exportTab(s),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _scroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AdminMobileLayout.scrollPadding(context, top: 12, horizontal: 16, fabClearance: 16),
        children: [child],
      ),
    );
  }

  Widget _overviewTab(AppStrings s) {
    if (_densePeriod) return _periodOverviewTab(s);

    final cur = _current;
    final pri = _prior;
    final leads = cur.sum((r) => r.leadsCreated);
    final leadsP = pri.sum((r) => r.leadsCreated);
    final views = cur.sum((r) => r.listingViews);
    final viewsP = pri.sum((r) => r.listingViews);
    final users = cur.sum((r) => r.newUsers);
    final usersP = pri.sum((r) => r.newUsers);
    final gmv = cur.sum((r) => r.gmvClosed.toInt());
    final gmvP = pri.sum((r) => r.gmvClosed.toInt());

    final leadPoints = _platform.reversed
        .map((r) => OpsChartPoint(label: _shortDate(r.statDate), value: r.leadsCreated))
        .toList();
    final viewPoints = _platform.reversed
        .map((r) => OpsChartPoint(label: _shortDate(r.statDate), value: r.listingViews))
        .toList();
    final userPoints = _platform.reversed
        .map((r) => OpsChartPoint(label: _shortDate(r.statDate), value: r.newUsers))
        .toList();

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.adminAnalyticsCompareHint, style: AdminTheme.hint),
          const SizedBox(height: 10),
          OpsSummaryMetrics(
            metrics: [
              OpsSummaryMetric(
                label: s.adminReportTotalLeads,
                value: '$leads',
                subtitle: _delta(leads, leadsP, s),
                icon: Icons.support_agent_outlined,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsTotalViews,
                value: '$views',
                subtitle: _delta(views, viewsP, s),
                icon: Icons.visibility_outlined,
              ),
              OpsSummaryMetric(
                label: s.adminDashUsers,
                value: '$users',
                subtitle: _delta(users, usersP, s),
                icon: Icons.person_add_outlined,
                accent: AppTheme.success,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsGmv,
                value: NumberFormat.compact(locale: s.isEnglish ? 'en' : 'th').format(gmv),
                subtitle: _delta(gmv, gmvP, s),
                icon: Icons.payments_outlined,
                accent: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  OpsMiniBarChart(title: s.adminReportChartLeads, points: leadPoints),
                  const SizedBox(height: 16),
                  OpsMiniBarChart(
                    title: s.adminAnalyticsTotalViews,
                    points: viewPoints,
                    color: AppTheme.accentDeep,
                  ),
                  const SizedBox(height: 16),
                  OpsMiniBarChart(
                    title: s.adminAnalyticsNewUsersChart,
                    points: userPoints,
                    color: AppTheme.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodOverviewTab(AppStrings s) {
    final rows = _periodStats.reversed.toList();
    int sum(int Function(AnalyticsPeriodStats r) pick) =>
        _periodStats.fold(0, (a, r) => a + pick(r));

    final installs = sum((r) => r.appInstalls);
    final opens = sum((r) => r.appOpens);
    final errors = sum((r) => r.clientErrors);
    final leads = sum((r) => r.leadsCreated);

    final installPts = rows
        .map((r) => OpsChartPoint(label: r.bucketLabel, value: r.appInstalls))
        .toList();
    final errorPts = rows
        .map((r) => OpsChartPoint(label: r.bucketLabel, value: r.clientErrors))
        .toList();
    final leadPts = rows
        .map((r) => OpsChartPoint(label: r.bucketLabel, value: r.leadsCreated))
        .toList();

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSummaryMetrics(
            metrics: [
              OpsSummaryMetric(
                label: s.adminAnalyticsAppInstalls,
                value: '$installs',
                icon: Icons.download_outlined,
                accent: AppTheme.success,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsAppOpens,
                value: '$opens',
                icon: Icons.launch_outlined,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsTabErrors,
                value: '$errors',
                icon: Icons.error_outline,
                accent: AppTheme.error,
              ),
              OpsSummaryMetric(
                label: s.adminReportTotalLeads,
                value: '$leads',
                icon: Icons.support_agent_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  OpsMiniBarChart(
                    title: s.adminAnalyticsPeriodInstallChart,
                    points: installPts,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 16),
                  OpsMiniBarChart(
                    title: s.adminAnalyticsPeriodErrorChart,
                    points: errorPts,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  OpsMiniBarChart(title: s.adminAnalyticsPeriodLeadsChart, points: leadPts),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _funnelTab(AppStrings s) {
    final cur = _current;
    final views = cur.sum((r) => r.listingViews);
    final chats = cur.sum((r) => r.chatStarts);
    final leads = cur.sum((r) => r.leadsCreated);
    final accepted = cur.sum((r) => r.leadsAccepted);
    final contracts = cur.sum((r) => r.eContractsSigned);
    final appts = cur.sum((r) => r.appointmentsCreated);
    final confirmed = cur.sum((r) => r.appointmentsConfirmed);
    final closed = cur.sum((r) => r.dealsClosed);

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: OpsFunnelStrip(
                title: s.adminAnalyticsFullFunnel,
                steps: [
                  OpsFunnelStep(label: s.adminAnalyticsFunnelViews, value: views),
                  OpsFunnelStep(
                    label: s.adminAnalyticsFunnelChats,
                    value: chats,
                    rateLabel: views == 0 ? null : _pct(chats / views, s),
                  ),
                  OpsFunnelStep(
                    label: s.adminReportFunnelLeads,
                    value: leads,
                    rateLabel: chats == 0 ? null : _pct(leads / chats, s),
                  ),
                  OpsFunnelStep(
                    label: s.adminReportFunnelAccepted,
                    value: accepted,
                    rateLabel: leads == 0 ? null : _pct(accepted / leads, s),
                  ),
                  OpsFunnelStep(label: s.adminAnalyticsFunnelContract, value: contracts),
                  OpsFunnelStep(label: s.adminReportFunnelAppts, value: appts),
                  OpsFunnelStep(
                    label: s.adminReportFunnelConfirmed,
                    value: confirmed,
                    rateLabel: appts == 0 ? null : _pct(confirmed / appts, s),
                  ),
                  OpsFunnelStep(label: s.adminAnalyticsFunnelClosed, value: closed),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._platform.map((r) {
            final summary = PlatformStatsSummary.fromRows([
              {
                'lead_count': r.leadsCreated,
                'accepted_count': r.leadsAccepted,
                'appointment_count': r.appointmentsCreated,
                'appointment_confirmed_count': r.appointmentsConfirmed,
              }
            ]);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(_shortDate(r.statDate)),
                subtitle: Text(s.adminStatRowSubtitle(
                  r.leadsCreated,
                  r.leadsAccepted,
                  r.appointmentsCreated,
                  r.appointmentsConfirmed,
                )),
                trailing: Text(
                  _pct(summary.leadAcceptRate, s),
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _geoTab(AppStrings s) {
    final maxScore = _districts.isEmpty
        ? 1
        : _districts.map((d) => d.score).reduce((a, b) => a > b ? a : b);

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.adminAnalyticsGeoHint, style: AdminTheme.hint),
          const SizedBox(height: 12),
          if (_districts.isEmpty)
            Text(s.adminNoStats)
          else
            ..._districts.map((d) {
              final ratio = d.score / maxScore;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.district, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        s.adminAnalyticsDistrictLine(d.listingViews, d.leadsCreated, d.appointmentsCreated),
                        style: AdminTheme.hint,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.05, 1.0),
                          minHeight: 8,
                          backgroundColor: AppTheme.border,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _chatTab(AppStrings s) {
    final totalVol = _chat.fold(0, (a, r) => a + r.volume);
    final totalSla = _chat.fold(0, (a, r) => a + r.slaBreaches);

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSummaryMetrics(
            metrics: [
              OpsSummaryMetric(
                label: s.adminAnalyticsChatVolume,
                value: '$totalVol',
                icon: Icons.chat_outlined,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsSlaBreaches,
                value: '$totalSla',
                icon: Icons.timer_off_outlined,
                accent: AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_chat.isEmpty)
            Text(s.adminNoStats)
          else
            ..._chat.map((row) {
              final claimRate = row.volume == 0 ? 0.0 : row.claimed / row.volume;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(s.adminAnalyticsChatCategory(row.category)),
                  subtitle: Text(s.adminAnalyticsChatLine(
                    row.volume,
                    row.claimed,
                    row.resolved,
                    row.slaBreaches,
                    row.avgClaimMinutes?.round(),
                  )),
                  trailing: Text(
                    _pct(claimRate, s),
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _listingsTab(AppStrings s) {
    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.adminAnalyticsTopListingsHint, style: AdminTheme.hint),
          const SizedBox(height: 12),
          if (_listings.isEmpty)
            Text(s.adminNoStats)
          else
            ..._listings.asMap().entries.map((e) {
              final i = e.key;
              final row = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEDE9FE),
                    child: Text('${i + 1}', style: TextStyle(color: LivingBkkBrand.purplePrimary, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(row.listingCode),
                  subtitle: Text(s.adminAnalyticsListingLine(
                    row.views,
                    row.chatStarts,
                    row.leadsCreated,
                  )),
                  trailing: Text(
                    '${row.engagementScore}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _appTab(AppStrings s) {
    final rows = _periodStats;
    final installs = rows.fold(0, (a, r) => a + r.appInstalls);
    final opens = rows.fold(0, (a, r) => a + r.appOpens);
    final uninstalls = rows.fold(0, (a, r) => a + r.appUninstalls);

    final openPts = rows.reversed
        .map((r) => OpsChartPoint(label: r.bucketLabel, value: r.appOpens))
        .toList();

    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.adminAnalyticsAppHint, style: AdminTheme.hint),
          const SizedBox(height: 12),
          OpsSummaryMetrics(
            metrics: [
              OpsSummaryMetric(
                label: s.adminAnalyticsAppInstalls,
                value: '$installs',
                icon: Icons.install_mobile_outlined,
                accent: AppTheme.success,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsAppOpens,
                value: '$opens',
                icon: Icons.smartphone_outlined,
              ),
              OpsSummaryMetric(
                label: s.adminAnalyticsAppUninstalls,
                value: '$uninstalls',
                icon: Icons.mobile_off_outlined,
                accent: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: OpsMiniBarChart(
                title: s.adminAnalyticsAppOpens,
                points: openPts,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorsTab(AppStrings s) {
    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.adminAnalyticsErrorsHint, style: AdminTheme.hint),
          const SizedBox(height: 12),
          if (_errors.isEmpty)
            Text(s.adminNoStats)
          else
            ..._errors.map((row) {
              final entry = ErrorCatalog.resolve(row.errorKey);
              final th = entry;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: Icon(
                    Icons.report_problem_outlined,
                    color: th.severity == ErrorSeverity.high
                        ? AppTheme.error
                        : AppTheme.warning,
                  ),
                  title: Text(th.titleTh, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${row.occurrenceCount} ${s.adminAnalyticsErrorCount} · '
                    '${row.affectedSessions} ${s.adminAnalyticsErrorSessions}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(th.summaryTh, style: AdminTheme.hint),
                          const SizedBox(height: 10),
                          Text(
                            s.adminAnalyticsErrorFixTitle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ...th.fixStepsTh.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(step)),
                                ],
                              ),
                            ),
                          ),
                          if (row.topPlatform != null) ...[
                            const SizedBox(height: 8),
                            Text('แพลตฟอร์ม: ${row.topPlatform}', style: AdminTheme.hint),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _exportTab(AppStrings s) {
    return _scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: Text(s.adminAnalyticsRefreshRollup),
              subtitle: Text(s.adminAnalyticsRefreshRollupHint),
              trailing: FilledButton(
                onPressed: _refreshingRollup ? null : _rollupRefresh,
                child: Text(s.adminRunNow),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.content_copy),
              title: Text(s.adminCopyTsv),
              subtitle: Text(s.adminReportsConfigured),
              onTap: _copyTsv,
            ),
          ),
          const SizedBox(height: 12),
          Text(s.adminMakecomSetup, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.adminMakecomInstructions, style: TextStyle(fontSize: 13, height: 1.45)),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.adminAnalyticsScaleNote, style: AdminTheme.hint),
        ],
      ),
    );
  }

  String _shortDate(String raw) {
    if (raw.length >= 10) {
      final p = raw.substring(0, 10).split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}';
    }
    return raw;
  }
}
