import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/availability_alert.dart';
import '../../services/availability_alerts_repository.dart';
import '../../services/availability_follow_up_service.dart';
import '../../services/availability_hidden_registry_service.dart';
import '../../services/registry_asset_ops_service.dart';
import 'admin_availability_ops.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';
import 'admin_availability_contact.dart';

enum _AvailabilityFilter { due, month, week, all, snoozed }

/// แจ้งเตือนประกาศกำลังจะว่าง — เบอร์อยู่ในคลังลับ · ตั้งเตือนซ้ำได้
class AdminAvailabilityAlertsTab extends StatefulWidget {
  const AdminAvailabilityAlertsTab({super.key, required this.adminTier});

  final String adminTier;

  @override
  State<AdminAvailabilityAlertsTab> createState() =>
      _AdminAvailabilityAlertsTabState();
}

class _AdminAvailabilityAlertsTabState extends State<AdminAvailabilityAlertsTab> {
  final _repo = AvailabilityAlertsRepository.instance;
  final _followUp = AvailabilityFollowUpService.instance;
  final _hidden = AvailabilityHiddenRegistryService.instance;
  final _ops = RegistryAssetOpsService.instance;
  bool _loading = true;
  List<AvailabilityAlertItem> _items = [];
  _AvailabilityFilter _filter = _AvailabilityFilter.due;

  bool get _confidential =>
      RegistryAssetOpsService.tierCanChatDirect(widget.adminTier);

  @override
  void initState() {
    super.initState();
    Future.wait([
      _followUp.ensureLoaded(),
      _hidden.ensureLoaded(),
    ]).then((_) => _load());
    _followUp.addListener(_onFollowUp);
    _hidden.addListener(_onFollowUp);
    _ops.addListener(_onFollowUp);
  }

  @override
  void dispose() {
    _followUp.removeListener(_onFollowUp);
    _hidden.removeListener(_onFollowUp);
    _ops.removeListener(_onFollowUp);
    super.dispose();
  }

  void _onFollowUp() {
    if (mounted) setState(() {});
  }

  int get _withinDays => switch (_filter) {
        _AvailabilityFilter.week => 7,
        _AvailabilityFilter.due => AvailabilityAlertsRepository.notifyHorizonDays,
        _AvailabilityFilter.month => AvailabilityAlertsRepository.notifyHorizonDays,
        _AvailabilityFilter.all => AvailabilityAlertsRepository.listHorizonDays,
        _AvailabilityFilter.snoozed => AvailabilityAlertsRepository.listHorizonDays,
      };

  List<AvailabilityAlertItem> _applyFilter(List<AvailabilityAlertItem> raw) {
    return raw.where((item) {
      final st = _followUp.stateFor(item.listingId);
      switch (_filter) {
        case _AvailabilityFilter.due:
          return st.isDueToday;
        case _AvailabilityFilter.snoozed:
          return st.isSnoozed;
        case _AvailabilityFilter.week:
        case _AvailabilityFilter.month:
        case _AvailabilityFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([
      _followUp.ensureLoaded(),
      _hidden.ensureLoaded(),
    ]);
    final list = await _repo.fetchUpcoming(withinDays: _withinDays);
    final active = list.where((item) {
      if (_hidden.isHidden(item.listingId)) return false;
      if (_followUp.stateFor(item.listingId).stoppedFollowUp) return false;
      return true;
    }).toList();
    if (!mounted) return;
    setState(() {
      _items = _applyFilter(active);
      _loading = false;
    });
  }

  Future<void> _snooze(AvailabilityAlertItem item) async {
    final s = context.s;
    final noteCtrl = TextEditingController();
    int days = 7;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(s.adminAvailabilitySnoozeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.adminAvailabilitySnoozeHint, style: AdminTheme.caption),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [1, 3, 7, 14, 30].map((d) {
                  return ChoiceChip(
                    label: Text(s.adminAvailabilitySnoozeDays(d)),
                    selected: days == d,
                    onSelected: (_) => setLocal(() => days = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.adminAvailabilitySnoozeNote,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.adminAvailabilitySnoozeConfirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) {
      noteCtrl.dispose();
      return;
    }
    await _followUp.snooze(
      listingId: item.listingId,
      days: days,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    noteCtrl.dispose();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminAvailabilitySnoozeSaved(days))),
    );
  }

  Future<void> _markContacted(AvailabilityAlertItem item) async {
    await _followUp.markContacted(item.listingId);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminAvailabilityMarkContacted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(s.adminAvailabilityAlertsIntro, style: AdminTheme.hint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text(s.adminAvailabilityFilterDue),
                selected: _filter == _AvailabilityFilter.due,
                onSelected: (_) {
                  setState(() => _filter = _AvailabilityFilter.due);
                  _load();
                },
              ),
              ChoiceChip(
                label: Text(s.adminAvailabilityFilterSnoozed),
                selected: _filter == _AvailabilityFilter.snoozed,
                onSelected: (_) {
                  setState(() => _filter = _AvailabilityFilter.snoozed);
                  _load();
                },
              ),
              ChoiceChip(
                label: Text(s.adminAvailabilityFilterMonth),
                selected: _filter == _AvailabilityFilter.month,
                onSelected: (_) {
                  setState(() => _filter = _AvailabilityFilter.month);
                  _load();
                },
              ),
              ChoiceChip(
                label: Text(s.adminAvailabilityFilterAll),
                selected: _filter == _AvailabilityFilter.all,
                onSelected: (_) {
                  setState(() => _filter = _AvailabilityFilter.all);
                  _load();
                },
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: s.refresh,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          s.adminAvailabilityAlertsEmpty,
                          textAlign: TextAlign.center,
                          style: AdminTheme.hint,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AlertCard(
                        item: _items[i],
                        adminTier: widget.adminTier,
                        confidential: _confidential,
                        dateFmt: dateFmt,
                        followUp: _followUp.stateFor(_items[i].listingId),
                        onSnooze: () => _snooze(_items[i]),
                        onContacted: () => _markContacted(_items[i]),
                        onReload: _load,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.item,
    required this.adminTier,
    required this.confidential,
    required this.dateFmt,
    required this.followUp,
    required this.onSnooze,
    required this.onContacted,
    required this.onReload,
  });

  final AvailabilityAlertItem item;
  final String adminTier;
  final bool confidential;
  final DateFormat dateFmt;
  final AvailabilityFollowUpState followUp;
  final VoidCallback onSnooze;
  final VoidCallback onContacted;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final days = item.daysLeft;
    final urgent = item.urgent && followUp.isDueToday;
    final accent = urgent
        ? AppTheme.error
        : (item.withinOneMonth ? AppTheme.accentMid : AppTheme.primary);
    final hasAccess = AdminAvailabilityContactActions.hasAccess(
      listingId: item.listingId,
      adminTier: adminTier,
    );
    final pending = AdminAvailabilityContactActions.hasPendingRequest(
      item.listingId,
    );

    return Material(
      color: AdminTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openAdminListing(
          context,
          listingId: item.listingId,
          listingCode: item.listingCode,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: followUp.isDueToday && urgent
                  ? AppTheme.error.withOpacity(0.35)
                  : AdminTheme.border,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.adminAvailabilityDaysLeft(days),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.listingCode,
                          style: AdminTheme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTheme.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (followUp.isDueToday && !followUp.isSnoozed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 16, color: AppTheme.accentMid),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.adminAvailabilityDueNow,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (followUp.isSnoozed && followUp.remindAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    s.adminAvailabilityRemindOn(
                      dateFmt.format(followUp.remindAt!),
                    ),
                    style: AdminTheme.caption.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (followUp.contactCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => showAvailabilityContactHistory(
                      context: context,
                      item: item,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          s.adminAvailabilityContactCount(followUp.contactCount),
                          style: AdminTheme.caption.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        if (followUp.lastContact != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateFmt.format(followUp.lastContact!.at.toLocal()),
                              style: AdminTheme.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Text(item.locationLine(s.isEnglish), style: AdminTheme.caption),
              const SizedBox(height: 4),
              Text(
                s.adminAvailabilityOnDate(dateFmt.format(item.availableAgain)),
                style: AdminTheme.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.ownerName != null && item.ownerName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  s.adminAvailabilityOwner(item.ownerName!),
                  style: AdminTheme.body.copyWith(fontSize: 13),
                ),
              ],
              const SizedBox(height: 6),
              Text(s.adminAvailabilityVaultPhoneHint, style: AdminTheme.caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilledButton.icon(
                    onPressed: pending
                        ? null
                        : () => AdminAvailabilityContactActions.openOwnerChat(
                              context,
                              item: item,
                              adminTier: adminTier,
                            ),
                    icon: Icon(
                      hasAccess ? Icons.chat_outlined : Icons.lock_outline,
                      size: 18,
                    ),
                    label: Text(
                      hasAccess
                          ? s.adminRegistryChatOwner
                          : (pending
                              ? s.adminRegistryChatRequestPending
                              : s.adminAvailabilityRequestContact),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => AdminAvailabilityContactActions
                        .openVaultListing(
                      context,
                      item: item,
                      adminTier: adminTier,
                      confidential: confidential,
                    ),
                    icon: Icon(
                      confidential
                          ? Icons.lock_open_outlined
                          : Icons.table_rows_outlined,
                      size: 18,
                    ),
                    label: Text(
                      confidential
                          ? s.adminNavVault
                          : s.adminNavAssetRegistry,
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showRecordExternalCallDialog(
                        context: context,
                        item: item,
                      );
                      if (ok) onReload();
                    },
                    icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                    label: Text(s.adminAvailabilityRecordCallTitle),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.snooze, size: 18),
                    label: Text(s.adminAvailabilitySnoozeBtn),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await openAvailabilityListingEdit(
                        context: context,
                        item: item,
                      );
                      onReload();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(s.adminAvailabilityEditListing),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton(
                    onPressed: onContacted,
                    child: Text(s.adminAvailabilityMarkContacted),
                  ),
                  TextButton(
                    onPressed: () async {
                      final ok = await showStopFollowUpDialog(
                        context: context,
                        item: item,
                      );
                      if (ok) {
                        onReload();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.adminAvailabilityStopFollowUpTitle),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                    child: Text(s.adminAvailabilityStopFollowUpBtn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
