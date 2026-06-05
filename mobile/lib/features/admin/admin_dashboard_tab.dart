import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(s.adminDashSectionOps),
          _row([
            _metricCard(s.adminDashChat, _data.chatWaiting, Icons.chat, 1, s),
            _metricCard(s.adminDashLeads, _data.leadsNew, Icons.support_agent, 3, s,
                foot: s.adminDashLeadsSub(_data.leadsTotal)),
          ]),
          _row([
            _metricCard(s.adminDashAppointments, _data.appointmentsPending, Icons.event, 4, s),
            _metricCard(s.adminDashOffers, _data.offersPending, Icons.local_offer, 2, s),
          ]),
          const SizedBox(height: 12),
          _sectionTitle(s.adminDashSectionCatalog),
          _row([
            _metricCard(s.adminDashProjects, _data.projects, Icons.apartment, 9, s),
            _metricCard(s.adminDashListings, _data.listingsPublished, Icons.home_work, -1, s,
                foot: s.adminDashListingsSub(_data.listingsTotal)),
          ]),
          _row([
            _metricCard(s.adminDashImports, _data.importsPending, Icons.cloud_download, 8, s),
            _metricCard(s.adminDashDemandPosts, _data.demandPostsOpen, Icons.campaign, 7, s),
          ]),
          const SizedBox(height: 12),
          const AdminExclusiveSettingsCard(),
          _sectionTitle(s.adminDashSectionTrust),
          _row([
            _metricCard(s.adminDashModImages, _data.moderationImages, Icons.image, 6, s),
            _metricCard(s.adminDashModFlags, _data.moderationFlags, Icons.flag, 6, s),
          ]),
          _row([
            _metricCard(s.adminDashUsers, _data.usersTotal, Icons.people, -1, s),
          ]),
          if (_platformStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(s.adminDashSectionTrend),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in _platformStats.take(7))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          s.adminDashTrendLine(
                            row['stat_date']?.toString() ?? '—',
                            (row['lead_count'] as num?)?.toInt() ?? 0,
                            (row['appointment_count'] as num?)?.toInt() ?? 0,
                          ),
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
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
  }) {
    return Card(
      child: InkWell(
        onTap: tabIndex >= 0 ? () => widget.onOpenTab?.call(tabIndex) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(height: 8),
              Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              Text(title, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              if (foot != null) ...[
                const SizedBox(height: 4),
                Text(foot, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
