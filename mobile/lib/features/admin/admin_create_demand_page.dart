import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/customer_requirement.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/demand/requirement_urgent_rush_toggle.dart';

class AdminCreateDemandPage extends StatefulWidget {
  const AdminCreateDemandPage({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<AdminCreateDemandPage> createState() => _AdminCreateDemandPageState();
}

class _AdminCreateDemandPageState extends State<AdminCreateDemandPage> {
  final _admin = AdminRepository();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _maxPrice = TextEditingController();
  final _minArea = TextEditingController();
  final _btsKm = TextEditingController(text: '1.5');

  String _type = 'rent';
  bool _urgentRush = false;
  bool _busy = false;
  bool _loadingLeads = true;
  List<CustomerRequirement> _leads = [];
  CustomerRequirement? _selectedLead;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _maxPrice.dispose();
    _minArea.dispose();
    _btsKm.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    setState(() => _loadingLeads = true);
    try {
      final items = await _admin.listPendingCustomerRequirements();
      if (!mounted) return;
      setState(() {
        _leads = items;
        if (_selectedLead != null &&
            !items.any((e) => e.id == _selectedLead!.id)) {
          _selectedLead = null;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingLeads = false);
    }
  }

  void _selectLead(CustomerRequirement lead) {
    setState(() {
      _selectedLead = lead;
      _type = lead.transactionType;
      _urgentRush = lead.urgentRush;
      _title.text = lead.titleTh();
      _desc.text = lead.suggestedBoardDescription();
      _maxPrice.text = lead.maxPriceNet?.toStringAsFixed(0) ?? '';
      _minArea.text = lead.minAreaSqm?.toStringAsFixed(0) ?? '';
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedLead = null;
      _title.clear();
      _desc.clear();
      _maxPrice.clear();
      _minArea.clear();
      _btsKm.text = '1.5';
      _type = 'rent';
      _urgentRush = false;
    });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final s = context.s;
    try {
      final zones = _selectedLead?.locationLabels.isNotEmpty == true
          ? _selectedLead!.locationLabels
          : (_selectedLead?.zone.isNotEmpty == true
              ? [_selectedLead!.zone]
              : <String>[]);

      if (_selectedLead != null) {
        await _admin.publishCustomerRequirementAsBoard(
          requirementId: _selectedLead!.id,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          transactionType: _type,
          propertyType: _selectedLead!.propertyType,
          zones: zones,
          maxPriceNet: double.tryParse(_maxPrice.text),
          minAreaSqm: double.tryParse(_minArea.text),
          maxDistanceBtsKm: double.tryParse(_btsKm.text),
          urgentRush: _urgentRush,
          requesterRole: _selectedLead!.requesterRole,
          contactPhone: _selectedLead!.contactPhone,
        );
      } else {
        await _admin.createDemandPost(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          transactionType: _type,
          zones: zones,
          maxPriceNet: double.tryParse(_maxPrice.text),
          minAreaSqm: double.tryParse(_minArea.text),
          maxDistanceBtsKm: double.tryParse(_btsKm.text),
          urgentRush: _urgentRush,
        );
      }

      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedLead != null ? s.adminBoardLeadPublished : s.adminBoardCreated,
          ),
        ),
      );
      _clearSelection();
      await _loadLeads();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeLead(CustomerRequirement lead) async {
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
      if (_selectedLead?.id == lead.id) _clearSelection();
      await _loadLeads();
      widget.onCreated();
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

    return RefreshIndicator(
      onRefresh: _loadLeads,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AdminNote(s.adminCreateBoardIntro),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(s.adminBoardLeadsTitle, style: AdminTheme.section),
              ),
              if (_loadingLeads)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text('${_leads.length}', style: AdminTheme.status),
            ],
          ),
          const SizedBox(height: 6),
          AdminHint(s.adminBoardLeadsHint),
          const SizedBox(height: 12),
          if (!_loadingLeads && _leads.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AdminTheme.card(),
              child: Text(s.adminBoardLeadsEmpty, style: AdminTheme.hint),
            )
          else
            ..._leads.map((lead) {
              final selected = _selectedLead?.id == lead.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _busy ? null : () => _selectLead(lead),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: AdminTheme.card(
                        color: selected
                            ? LivingBkkBrand.purplePrimary.withOpacity(0.06)
                            : null,
                        alert: lead.urgentRush,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  lead.titleTh(),
                                  style: AdminTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (lead.urgentRush)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.bolt,
                                    size: 18,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                            ],
                          ),
                          if (lead.contactName.isNotEmpty ||
                              lead.contactPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (lead.contactName.isNotEmpty) lead.contactName,
                                if (lead.contactPhone.isNotEmpty) lead.contactPhone,
                              ].join(' · '),
                              style: AdminTheme.caption,
                            ),
                          ],
                          if (lead.demandPostCode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              s.requirementBoardCodeLabel(lead.demandPostCode!),
                              style: AdminTheme.caption.copyWith(
                                color: LivingBkkBrand.purplePrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (lead.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              dateFmt.format(lead.createdAt!.toLocal()),
                              style: AdminTheme.caption,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (lead.threadId != null &&
                                  lead.threadId!.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => context.push(
                                            '/admin/chat/${lead.threadId}',
                                          ),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                  label: Text(s.adminBoardOpenChat),
                                ),
                              if (selected)
                                TextButton(
                                  onPressed: _busy ? null : () => _closeLead(lead),
                                  child: Text(s.adminBoardCloseLead),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          Divider(color: AdminTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedLead != null
                      ? s.adminBoardEditAndPublish
                      : s.adminBoardManualCreate,
                  style: AdminTheme.section,
                ),
              ),
              if (_selectedLead != null)
                TextButton(
                  onPressed: _busy ? null : _clearSelection,
                  child: Text(s.cancel),
                ),
            ],
          ),
          if (_selectedLead != null) ...[
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.inbox, size: 16),
              label: Text(s.adminBoardFromLead),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: '${s.offerTitleField} *'),
          ),
          TextField(
            controller: _desc,
            decoration: InputDecoration(
              labelText: s.offerDetailsField,
              hintText: s.adminCreateBoardHint,
            ),
            maxLines: 6,
          ),
          TextField(
            controller: _maxPrice,
            decoration: InputDecoration(labelText: s.adminMaxPriceLabel),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _minArea,
            decoration: InputDecoration(labelText: s.adminMinAreaLabel),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _btsKm,
            decoration: InputDecoration(labelText: s.adminBtsDistanceLabel),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            value: _type,
            items: [
              DropdownMenuItem(value: 'rent', child: Text(s.rent)),
              DropdownMenuItem(value: 'sale', child: Text(s.sale)),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          RequirementUrgentRushToggle(
            value: _urgentRush,
            onChanged: (v) => setState(() => _urgentRush = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(s.adminPublishBoard),
          ),
        ],
      ),
    );
  }
}
