import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_audit_entry.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_mobile_layout.dart';

/// แผง audit log — Governance compliance
class AdminAuditLogPanel extends StatefulWidget {
  const AdminAuditLogPanel({super.key});

  @override
  State<AdminAuditLogPanel> createState() => _AdminAuditLogPanelState();
}

class _AdminAuditLogPanelState extends State<AdminAuditLogPanel> {
  final _admin = AdminRepository();
  List<AdminAuditEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _admin.fetchAuditLog();
    if (!mounted) return;
    setState(() {
      _entries = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.adminAuditLogEmpty, style: AdminTheme.hint, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: AdminMobileLayout.scrollPadding(context, top: 12, horizontal: 16, fabClearance: 16),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = _entries[i];
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.action,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        dateFmt.format(e.createdAt),
                        style: AdminTheme.hint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.adminAuditLogEntity(e.entityType, e.entityId ?? '—'),
                    style: AdminTheme.hint,
                  ),
                  if (e.actorName != null && e.actorName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.adminAuditLogActor(e.actorName!),
                      style: AdminTheme.hint,
                    ),
                  ],
                  if (e.payload.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      e.payload.entries.map((kv) => '${kv.key}: ${kv.value}').join(' · '),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
