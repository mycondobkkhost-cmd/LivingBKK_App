import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../models/platform_stats_summary.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ops/ops_funnel_strip.dart';
import '../../widgets/ops/ops_mini_bar_chart.dart';
import 'admin_exclusive_settings_card.dart';

/// แท็บแดชบอร์ดรายละเอียด — สรุปทุกระบบ
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key, this.onOpenTab});

  final void Function(int tabIndex)? onOpenTab;

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
    final overview = await _admin.fetchDashboardOverview();
    final stats = await _admin.platformStatsHistory(days: 7);
    if (!mounted) return;
    setState(() {
      _data = overview;
      _platformStats = stats;
      _loading = false;
    });
  }

  String _pct(double rate, AppStrings s) =>
      s.adminReportRatePercent((rate * 100).round());

  void _openAttentionTab() {
    final tab = _data.customerRequirementsPending > 0 &&
            _data.customerRequirementsPending >= _data.chatWaiting
        ? 8
        : 1;
    widget.onOpenTab?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final trendSummary = PlatformStatsSummary.fromRows(_platformStats);
    final leadPoints = OpsMiniBarChart.fromDailyRows(
      _platformStats,
      labelBuilder: (d, en) => OpsMiniBarChart.shortDateLabel(d, en),
      valuePicker: (r) => (r['lead_count'] as num?)?.toInt() ?? 0,
      isEnglish: s.isEnglish,
      maxPoints: 7,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_data.attentionTotal > 0)
            Card(
              color: AppTheme.error.withOpacity(0.08),
              child: ListTile(
                leading: Icon(Icons.priority_high, color: AppTheme.error),
                title: Text(
                  s.adminDashNeedsAction(_data.attentionTotal),
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.error),
                ),
                subtitle: Text(s.adminDashActionHint),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _openAttentionTab(),
                ),
                onTap: _openAttentionTab,
              ),
            ),
          _sectionTitle(s.adminDashSectionOps),
          _row([
            _metricCard(s.adminDashChat, _data.chatWaiting, Icons.chat, 1, s,
                alert: _data.chatWaiting > 0),
            _metricCard(s.adminDashLeads, _data.leadsNew, Icons.support_agent, 3, s,
                foot: s.adminDashLeadsSub(_data.leadsTotal), alert: _data.leadsNew > 0),
          ]),
          _row([
            _metricCard(s.adminDashAppointments, _data.appointmentsPending, Icons.event, 4, s,
                alert: _data.appointmentsPending > 0),
            _metricCard(s.adminDashOffers, _data.offersPending, Icons.local_offer, 2, s,
                alert: _data.offersPending > 0),
          ]),
          const SizedBox(height: 12),
          _sectionTitle(s.adminDashSectionCatalog),
          _row([
            _metricCard(s.adminDashProjects, _data.projects, Icons.apartment, 10, s),
            _metricCard(s.adminDashListings, _data.listingsPublished, Icons.home_work, -1, s,
                foot: s.adminDashListingsSub(_data.listingsTotal)),
          ]),
          _row([
            _metricCard(s.adminDashImports, _data.importsPending, Icons.cloud_download, 9, s,
                alert: _data.importsPending > 0),
            _metricCard(s.adminDashDemandPosts, _data.demandPostsOpen, Icons.campaign, 8, s),
          ]),
          _row([
            _metricCard(
              s.adminDashRequirements,
              _data.customerRequirementsPending,
              Icons.assignment,
              8,
              s,
              alert: _data.customerRequirementsPending > 0,
            ),
          ]),
          const SizedBox(height: 12),
          const AdminExclusiveSettingsCard(),
          _sectionTitle(s.adminDashSectionTrust),
          _row([
            _metricCard(s.adminDashModImages, _data.moderationImages, Icons.image, 6, s,
                alert: _data.moderationImages > 0),
            _metricCard(s.adminDashModFlags, _data.moderationFlags, Icons.flag, 6, s,
                alert: _data.moderationFlags > 0),
          ]),
          _row([
            _metricCard(s.adminDashUsers, _data.usersTotal, Icons.people, -1, s),
          ]),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => widget.onOpenTab?.call(5),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: Text(s.adminOpenReportsCenter),
            ),
          ),
          if (_platformStats.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionTitle(s.adminDashSectionTrend),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpsFunnelStrip(
                      steps: [
                        OpsFunnelStep(
                          label: s.adminReportFunnelLeads,
                          value: trendSummary.totalLeads,
                        ),
                        OpsFunnelStep(
                          label: s.adminReportFunnelAccepted,
                          value: trendSummary.totalAccepted,
                          rateLabel: _pct(trendSummary.leadAcceptRate, s),
                        ),
                        OpsFunnelStep(
                          label: s.adminReportFunnelAppts,
                          value: trendSummary.totalAppointments,
                        ),
                        OpsFunnelStep(
                          label: s.adminReportFunnelConfirmed,
                          value: trendSummary.totalConfirmed,
                          rateLabel: _pct(trendSummary.apptConfirmRate, s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OpsMiniBarChart(
                      title: s.adminReportChartLeads,
                      points: leadPoints,
                      maxBarHeight: 56,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_data.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.adminDashUpdated(DateFormat('HH:mm').format(_data.updatedAt!.toLocal())),
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _metricCard(
    String title,
    int value,
    IconData icon,
    int tabIndex,
    AppStrings s, {
    String? foot,
    bool alert = false,
  }) {
    return Card(
      color: alert ? AppTheme.error.withOpacity(0.05) : null,
      child: InkWell(
        onTap: tabIndex >= 0 ? () => widget.onOpenTab?.call(tabIndex) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: alert ? AppTheme.error : AppTheme.primary, size: 22),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: alert ? AppTheme.error : null,
                ),
              ),
              Text(title, style: AdminTheme.caption),
              if (foot != null) ...[
                const SizedBox(height: 4),
                Text(foot, style: AdminTheme.caption),
              ],
              if (tabIndex >= 0) ...[
                const SizedBox(height: 6),
                Text(s.adminDashOpenTab, style: TextStyle(fontSize: 11, color: AppTheme.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
