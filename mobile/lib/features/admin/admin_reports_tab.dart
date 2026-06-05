import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _admin = AdminRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _platformStats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _admin.platformStatsHistory(days: 14);
    setState(() {
      _platformStats = rows;
      _loading = false;
    });
  }

  Future<void> _copyExport() async {
    final tsv = await _admin.buildPlatformStatsTsv(days: 30);
    await Clipboard.setData(ClipboardData(text: tsv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminTsvCopied)),
    );
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
          Card(
            color: AppTheme.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminReportsTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Env.isConfigured ? s.adminReportsConfigured : s.adminReportsDemo,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _copyExport,
                    icon: const Icon(Icons.content_copy),
                    label: Text(s.adminCopyTsv),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.adminDailyStats,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_platformStats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.adminNoStats),
            )
          else
            ..._platformStats.map(_statRow),
          const SizedBox(height: 16),
          Text(
            s.adminMakecomSetup,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.adminMakecomInstructions,
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(Map<String, dynamic> row) {
    final s = context.s;
    final date = row['stat_date'];
    final locale = s.isEnglish ? 'en' : 'th_TH';
    final label = date is DateTime
        ? DateFormat('d MMM yyyy', locale).format(date)
        : date?.toString() ?? '—';
    final leads = (row['lead_count'] as num?)?.toInt() ?? 0;
    final accepted = (row['accepted_count'] as num?)?.toInt() ?? 0;
    final appts = (row['appointment_count'] as num?)?.toInt() ?? 0;
    final confirmed = (row['appointment_confirmed_count'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        subtitle: Text(s.adminStatRowSubtitle(leads, accepted, appts, confirmed)),
        leading: Icon(Icons.insights, color: AppTheme.primary),
      ),
    );
  }
}
