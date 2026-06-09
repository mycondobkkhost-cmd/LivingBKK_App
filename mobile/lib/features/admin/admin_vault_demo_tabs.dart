import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/admin_demo_data.dart';
import '../../l10n/app_strings.dart';
import '../../services/admin_access_repository.dart';
import '../../theme/admin_theme.dart';
import 'admin_org_comp_cards_tab.dart';

/// คำขอเข้าถึง — โหลดจาก DB · fallback demo ในโหมดทดลอง
class AdminAccessRequestsTab extends StatefulWidget {
  const AdminAccessRequestsTab({super.key});

  @override
  State<AdminAccessRequestsTab> createState() => _AdminAccessRequestsTabState();
}

class _AdminAccessRequestsTabState extends State<AdminAccessRequestsTab> {
  late Future<List<AdminAccessRequest>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = AdminAccessRepository.instance.listPending();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('d MMM HH:mm');

    return FutureBuilder<List<AdminAccessRequest>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data ?? const <AdminAccessRequest>[];
        final isDemo = items.isNotEmpty &&
            items.first.id.startsWith('demo-access');

        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminNote(s.adminAccessRequestsIntro),
              if (isDemo) ...[
                const SizedBox(height: 8),
                AdminNote(s.adminDemoDataNote),
              ],
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      s.adminAccessRequestsEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...items.map((row) {
                  final pending = row.isPending;
                  final entityLabel =
                      row.entityCode ?? row.entityId.substring(0, 8);
                  final requester = row.requesterName ?? row.requestedBy;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        pending
                            ? Icons.hourglass_top
                            : Icons.check_circle_outline,
                        color: pending
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      title: Text('$entityLabel · ${row.entityType}'),
                      subtitle: Text(
                        '$requester\n${row.reason}\n'
                        '${dateFmt.format(row.createdAt.toLocal())}',
                        maxLines: 4,
                      ),
                      isThreeLine: true,
                      trailing: Chip(
                        label: Text(
                          pending
                              ? s.adminAccessRequestPending
                              : s.adminAccessRequestApproved,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

/// องค์กร + คอมพ์การ์ดทีมงาน (โปรไฟล์ย่อย)
class AdminOrgTab extends StatelessWidget {
  const AdminOrgTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: s.adminNavOrg),
              Tab(text: s.adminCompCardTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrgUnitsPanel(),
                const AdminOrgCompCardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgUnitsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final units = AdminDemoData.orgUnits();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminNote(s.adminOrgIntro),
        const SizedBox(height: 12),
        ...units.map((row) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(row['name']?.toString() ?? ''),
              subtitle: Text(
                '${s.adminOrgLead}: ${row['lead']} · ${row['members']} ${s.adminOrgMembers}',
              ),
              trailing: Chip(label: Text(row['tier']?.toString() ?? '')),
            ),
          );
        }),
      ],
    );
  }
}
