import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/customer_requirement.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import 'admin_nav_model.dart';

/// ความต้องการลูกค้า — รายการรอทีมเผยแพร่บนบอร์ด
class AdminRequirementsTab extends StatefulWidget {
  const AdminRequirementsTab({
    super.key,
    required this.onOpenNav,
    this.onChanged,
  });

  final void Function(AdminNavId id) onOpenNav;
  final VoidCallback? onChanged;

  @override
  State<AdminRequirementsTab> createState() => _AdminRequirementsTabState();
}

class _AdminRequirementsTabState extends State<AdminRequirementsTab> {
  final _admin = AdminRepository();
  List<CustomerRequirement> _items = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _admin.listPendingCustomerRequirements();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _close(CustomerRequirement lead) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminBoardCloseLead),
        content: Text(s.adminBoardCloseLeadConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.ownerExclusiveTermsConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _admin.closeCustomerRequirement(lead.id);
      await _load();
      widget.onChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminBoardLeadClosed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('d MMM HH:mm');

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminNote(s.adminRequirementsIntro),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(s.adminNavRequirements, style: AdminTheme.section),
              ),
              Text('${_items.length}', style: AdminTheme.status),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : () => widget.onOpenNav(AdminNavId.boardCreate),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(s.adminBoardManualCreate),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AdminHint(s.adminBoardLeadsHint),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AdminTheme.card(),
              child: Text(s.adminBoardLeadsEmpty, style: AdminTheme.hint, textAlign: TextAlign.center),
            )
          else
            ..._items.map((lead) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: AdminTheme.card(alert: lead.urgentRush),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lead.titleTh(),
                              style: AdminTheme.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (lead.urgentRush)
                            Icon(Icons.bolt, size: 20, color: Colors.amber.shade700),
                        ],
                      ),
                      if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(lead.notes!, style: AdminTheme.caption),
                      ],
                      if (lead.contactName.isNotEmpty || lead.contactPhone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [lead.contactName, lead.contactPhone].where((e) => e.isNotEmpty).join(' · '),
                          style: AdminTheme.caption,
                        ),
                      ],
                      if (lead.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(dateFmt.format(lead.createdAt!.toLocal()), style: AdminTheme.caption),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => widget.onOpenNav(AdminNavId.boardCreate),
                            icon: const Icon(Icons.campaign_outlined, size: 16),
                            label: Text(s.adminBoardFromLead),
                          ),
                          if (lead.threadId != null && lead.threadId!.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => context.push('/admin/console?room=${lead.threadId}'),
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: Text(s.adminBoardOpenChat),
                            ),
                          TextButton(
                            onPressed: _busy ? null : () => _close(lead),
                            child: Text(s.adminBoardCloseLead),
                          ),
                        ],
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
}
