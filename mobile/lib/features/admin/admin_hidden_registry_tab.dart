import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/vault_asset.dart';
import '../../services/availability_follow_up_service.dart';
import '../../services/availability_hidden_registry_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import 'admin_asset_registry_widgets.dart';

/// คลังซ่อน — ทรัพย์ที่ติดต่อเจ้าของไม่ได้ (ไม่อยู่ในคลังหลัก)
class AdminHiddenRegistryTab extends StatefulWidget {
  const AdminHiddenRegistryTab({super.key});

  @override
  State<AdminHiddenRegistryTab> createState() => _AdminHiddenRegistryTabState();
}

class _AdminHiddenRegistryTabState extends State<AdminHiddenRegistryTab> {
  final _hidden = AvailabilityHiddenRegistryService.instance;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _hidden.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    _hidden.addListener(_onHidden);
  }

  @override
  void dispose() {
    _hidden.removeListener(_onHidden);
    _search.dispose();
    super.dispose();
  }

  void _onHidden() {
    if (mounted) setState(() {});
  }

  List<VaultAssetSummary> get _filtered {
    final items = _hidden.hiddenSummaries();
    if (_query.trim().isEmpty) return items;
    return filterAssetRegistry(items, _query);
  }

  Future<void> _restore(String listingId) async {
    final s = context.s;
    await _hidden.restore(listingId);
    await AvailabilityFollowUpService.instance.resetFollowUp(listingId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminHiddenRegistryRestored)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = DateFormat('d MMM yyyy HH:mm');
    final entries = _hidden.allEntries();
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(s.adminHiddenRegistryIntro, style: AdminTheme.hint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: s.adminRegistrySearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(s.adminHiddenRegistryEmpty, style: AdminTheme.hint),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final sum = filtered[i];
                    final entry = entries.firstWhere(
                      (e) => e.listingId == sum.listingId,
                    );
                    return Material(
                      color: AdminTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility_off_outlined,
                                    size: 18, color: AppTheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sum.listingCode ?? sum.displayCode,
                                    style: AdminTheme.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(sum.titlePreview ?? '—', style: AdminTheme.body),
                            const SizedBox(height: 6),
                            Text(
                              s.adminHiddenRegistryReason(entry.reason),
                              style: AdminTheme.caption,
                            ),
                            Text(
                              s.adminHiddenRegistryArchivedOn(
                                fmt.format(entry.archivedAt.toLocal()),
                              ),
                              style: AdminTheme.caption,
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => _restore(entry.listingId),
                              icon: const Icon(Icons.undo, size: 18),
                              label: Text(s.adminHiddenRegistryRestore),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
