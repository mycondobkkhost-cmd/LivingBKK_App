import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/commission_tier.dart';
import '../../services/commission_repository.dart';
import '../../services/lead_inbox_repository.dart';
import '../../theme/app_theme.dart';
import 'e_contract_sheet.dart';
import 'lead_unavailable_sheet.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class LeadInboxDetailPage extends StatefulWidget {
  const LeadInboxDetailPage({super.key, required this.leadId});

  final String leadId;

  @override
  State<LeadInboxDetailPage> createState() => _LeadInboxDetailPageState();
}

class _LeadInboxDetailPageState extends State<LeadInboxDetailPage> {
  final _inbox = LeadInboxRepository();
  final _commission = CommissionRepository();
  bool _loading = true;
  Map<String, dynamic>? _lead;
  CommissionTier? _tier;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _inbox.claimIfNeeded(widget.leadId);
      final lead = await _inbox.fetchLead(widget.leadId);
      final tiers = await _commission.fetchActiveTiers();
      final tier = _commission.tierForContract(
        tiers,
        lead?['contract_duration'] as String?,
      );
      setState(() {
        _lead = lead;
        _tier = tier;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _contractLabel(AppStrings s, String? code) {
    switch (code) {
      case '6m':
        return s.contract6Months;
      case '12m':
        return s.contract1Year;
      case '24m':
        return s.contract2Years;
      default:
        return code ?? '—';
    }
  }

  Map<String, String> _qualLabels(AppStrings s, Map<String, dynamic>? q) {
    if (q == null) return {};
    final out = <String, String>{};
    if (q['applicant_type'] == 'seeker_self') {
      out[s.typeFieldLabel] = s.typeSeeker;
    } else if (q['applicant_type'] == 'co_agent_request') {
      out[s.typeFieldLabel] = s.typeCoAgentRequest;
    }
    if (q['budget_min'] != null || q['budget_max'] != null) {
      out[s.budgetLabel] = '${q['budget_min'] ?? '—'} – ${q['budget_max'] ?? '—'}';
    }
    if (q['viewing_schedule'] != null) {
      out[s.viewingFieldLabel] = q['viewing_schedule'].toString();
    }
    return out;
  }

  Future<void> _accept() async {
    if (_tier == null || _lead == null) return;
    final s = AppStrings.of(context);
    final code = _lead!['listing_code']?.toString() ?? '';
    final agreed = await showEContractSheet(
      context,
      tier: _tier!,
      listingCode: code,
    );
    if (agreed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await _inbox.acceptLead(
        leadId: widget.leadId,
        commissionTierId: _tier!.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.caseAccepted)),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _unavailable() async {
    final s = AppStrings.of(context);
    final result = await showLeadUnavailableSheet(context);
    if (result == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await _inbox.markUnavailable(
        leadId: widget.leadId,
        unavailableUntil: result.unavailableUntil,
        availableAgain: result.availableAgain,
        listingId: _lead?['listing_id'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.unavailableSaved)),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (_loading) {
      return ConsumerPageShell(
        title: 'Lead',
        onBack: () => context.pop(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lead = _lead;
    if (lead == null) {
      return ConsumerPageShell(
        title: 'Lead',
        onBack: () => context.pop(),
        body: Center(child: Text(s.notFoundLead)),
      );
    }

    final status = lead['status']?.toString() ?? 'new';
    final canAct = status == 'new' || status == 'routed';
    final qual = _qualLabels(s, lead['qualification_json'] as Map<String, dynamic>?);

    return ConsumerPageShell(
      title: lead['listing_code']?.toString() ?? 'Lead',
      onBack: () => context.pop(),
      body: ListView(
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: LiLayout.pagePadding,
          right: LiLayout.pagePadding,
          bottom: 20,
          addHomeIndicator: false,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead['seeker_nickname']?.toString() ?? s.leadDefaultName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lead['seeker_phone_censored']?.toString() ?? s.phoneHidden,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _row(s.statusLabel, status),
                  _row(
                    s.occupantsLabel,
                    lead['occupants_count'] != null
                        ? s.occupantsCount(lead['occupants_count'] as int)
                        : null,
                  ),
                  _row(s.occupationLabel, lead['occupation']?.toString()),
                  _row(s.workplaceField, lead['workplace']?.toString()),
                  _row(s.movePlanLabel, lead['move_plan']?.toString()),
                  _row(s.contractFieldLabel, _contractLabel(s, lead['contract_duration'] as String?)),
                  _row(s.budgetLabel, lead['budget']?.toString()),
                  _row(s.carLabel, lead['has_car'] == true ? s.hasCarYes : s.hasCarNo),
                  _row(s.smokingField, lead['smoking']?.toString()),
                  _row(s.petsField, lead['pets']?.toString()),
                  ...qual.entries.map((e) => _row(e.key, e.value)),
                ],
              ),
            ),
          ),
          if (_tier != null) ...[
            const SizedBox(height: 12),
            Card(
              color: AppTheme.primaryLight,
              child: ListTile(
                title: Text(_tier!.name, style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_tier!.splitSummary),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (canAct) ...[
            FilledButton.icon(
              onPressed: _acting ? null : _accept,
              icon: _acting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(s.acceptCase),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _acting ? null : _unavailable,
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(s.propertyUnavailable),
            ),
          ] else
            Text(
              s.caseProcessed,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty || value == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
