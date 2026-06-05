import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// แถบ Lead ล่าสุดบน Admin Console — เห็นคำขอนัดดูแม้แชทยังไม่ sync
class AdminRecentLeadsStrip extends StatefulWidget {
  const AdminRecentLeadsStrip({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<AdminRecentLeadsStrip> createState() => _AdminRecentLeadsStripState();
}

class _AdminRecentLeadsStripState extends State<AdminRecentLeadsStrip> {
  final _admin = AdminRepository();
  Timer? _timer;
  List<Map<String, dynamic>> _leads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _admin.recentLeads();
      if (!mounted) return;
      setState(() {
        _leads = rows.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final auth = AuthService.instance;

    return Material(
      color: AppTheme.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!auth.isRealSupabaseSession)
            Container(
              width: double.infinity,
              color: AppTheme.accentMidLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                s.adminMustLoginReal,
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.adminRecentLeadsTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: s.refresh,
                  onPressed: () async {
                    await _load();
                    widget.onChanged();
                  },
                ),
                TextButton(
                  onPressed: () => context.push('/admin'),
                  child: Text(s.adminViewAllLeads, style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_leads.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                s.adminNoLeads,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                itemCount: _leads.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final l = _leads[i];
                  final qual = l['qualification_json'] as Map<String, dynamic>?;
                  final viewing = qual?['viewing_schedule']?.toString();
                  return ActionChip(
                    avatar: const Icon(Icons.person_search, size: 18),
                    label: Text(
                      '${l['listing_code']} · ${l['seeker_nickname']}',
                      style: TextStyle(fontSize: 11),
                    ),
                    tooltip: viewing ?? l['status']?.toString(),
                    onPressed: () => context.push('/admin/lead/${l['id']}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
