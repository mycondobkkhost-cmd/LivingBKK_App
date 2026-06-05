import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/customer_requirement.dart';
import '../../models/requirement_location_entry.dart';
import '../../services/chat_service.dart';
import '../../services/customer_requirement_repository.dart';
import '../contact/property_chat_page.dart';
import '../../theme/app_theme.dart';
import '../../utils/price_slider_scale.dart';
import '../../widgets/budget_range_slider.dart';
import '../../widgets/property_type_more_sheet.dart';
import '../../widgets/demand/requirement_urgent_rush_toggle.dart';
import '../../widgets/requirement_location_picker.dart';

class CreateRequirementPage extends StatefulWidget {
  const CreateRequirementPage({super.key});

  @override
  State<CreateRequirementPage> createState() => _CreateRequirementPageState();
}

class _CreateRequirementPageState extends State<CreateRequirementPage> {
  final _repo = CustomerRequirementRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _messenger = TextEditingController();
  final _notes = TextEditingController();
  final _minArea = TextEditingController(text: '40');
  final _scroll = ScrollController();

  String _requesterRole = 'direct';
  String _transactionType = 'rent';
  final Set<String> _propertyTypes = {'condo'};
  String _furnishing = 'unfurnished';
  String _decisionTimeframe = 'still_comparing';
  DateTime? _contractStartBy;
  List<RequirementLocationEntry> _locations = [];
  bool _locationTouched = false;

  double _minPricePos = PriceSliderScale.rentBahtToPosition(8000);
  double _maxPricePos = PriceSliderScale.rentBahtToPosition(25000);

  final Set<String> _buyPayments = {};
  final Set<String> _buyPurposes = {};

  bool _urgentRush = false;
  bool _submitting = false;

  static const _decisionKeys = [
    'book_now',
    'still_comparing',
    'within_1_week',
    'within_2_weeks',
    'within_1_month',
    'flexible',
  ];

  static const _mainPropertySlugs = ['condo', 'house', 'townhome'];

  bool get _isSale => _transactionType == 'sale';

  double get _minPriceBaht => _isSale
      ? PriceSliderScale.salePositionToBaht(_minPricePos)
      : PriceSliderScale.rentPositionToBaht(_minPricePos);

  double get _maxPriceBaht => _isSale
      ? PriceSliderScale.salePositionToBaht(_maxPricePos)
      : PriceSliderScale.rentPositionToBaht(_maxPricePos);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _messenger.dispose();
    _notes.dispose();
    _minArea.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _resetBudgetForTransaction() {
    if (_isSale) {
      _minPricePos = PriceSliderScale.saleBahtToPosition(2000000);
      _maxPricePos = PriceSliderScale.saleBahtToPosition(5000000);
    } else {
      _minPricePos = PriceSliderScale.rentBahtToPosition(8000);
      _maxPricePos = PriceSliderScale.rentBahtToPosition(25000);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickContractStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractStartBy ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _contractStartBy = picked);
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _locationTouched = true);

    if (!_formKey.currentState!.validate()) {
      _toast(s.t('กรุณากรอกข้อมูลที่จำเป็น', 'Please fill required fields'));
      return;
    }
    if (_locations.isEmpty) {
      _toast(s.requirementZoneRequired);
      return;
    }
    if (_propertyTypes.isEmpty) {
      _toast(s.requirementPropertyTypeRequired);
      return;
    }

    final draft = _buildDraft();
    final confirmed = await _showConfirmDialog(draft);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      final outcome = await _repo.submit(draft);
      if (!mounted) return;
      final room = await ChatService.instance.recordRequirement(outcome.requirement);
      if (!mounted) return;

      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PropertyChatPage(room: room),
        ),
      );
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('CreateRequirementPage._submit: $e\n$st');
      if (mounted) _toast(s.requirementSubmitFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  CustomerRequirement _buildDraft() {
    final labels = _locations.map((e) => e.label).toList();
    RequirementLocationEntry? firstProject;
    for (final e in _locations) {
      if (e.projectSlug != null) {
        firstProject = e;
        break;
      }
    }

    final typeSlugs = _propertyTypes.toList()..sort();
    final primarySlug = typeSlugs.first;
    final messenger = _messenger.text.trim();

    return CustomerRequirement(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      transactionType: _transactionType,
      propertyType: PropertyCatalog.dbValueForSlug(primarySlug) ?? primarySlug,
      propertyTypes: typeSlugs,
      zone: labels.join(', '),
      requesterRole: _requesterRole,
      locationLabels: labels,
      contactName: _name.text.trim(),
      contactPhone: _phone.text.trim(),
      messengerId: messenger.isEmpty ? null : messenger,
      minPriceNet: _minPriceBaht,
      maxPriceNet: _maxPriceBaht,
      minAreaSqm: double.tryParse(_minArea.text.trim()),
      furnishing: _isSale ? 'any' : _furnishing,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      contractStartBy: _isSale ? null : _contractStartBy,
      decisionTimeframe: _decisionTimeframe,
      preferredProjectName: firstProject?.label,
      preferredProjectSlug: firstProject?.projectSlug,
      buyPaymentTypes: _isSale ? _buyPayments.toList() : const [],
      buyPurposes: _isSale ? _buyPurposes.toList() : const [],
      createdAt: DateTime.now(),
      urgentRush: _urgentRush,
    );
  }

  Future<bool> _showConfirmDialog(CustomerRequirement draft) async {
    final s = AppStrings.of(context);
    final summary = draft.toChatSummary(s.isEnglish);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(s.requirementConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.requirementConfirmIntro,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  for (final e in summary.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 108,
                            child: Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.requirementConfirmEdit),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.requirementConfirmSubmit),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final dateFmt = DateFormat.yMMMd(s.isEnglish ? 'en' : 'th');

    return Scaffold(
      appBar: AppBar(title: Text(s.requirementCreateTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              s.requirementCreateIntro,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 14),
            RequirementUrgentRushToggle(
              value: _urgentRush,
              onChanged: (v) => setState(() => _urgentRush = v),
            ),
            const SizedBox(height: 18),
            _sectionTitle(s.requirementFieldRequesterRole),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _roleCard(
                    'direct',
                    s.requirementRoleDirect,
                    s.requirementRoleDirectHint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _roleCard(
                    'agent',
                    s.requirementRoleAgent,
                    s.requirementRoleAgentHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle(s.requirementSectionContact),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: _fieldDeco(
                label: s.requirementFieldContactName,
                hint: s.requirementFieldContactNameHint,
                icon: Icons.person_outline,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requirementContactNameRequired : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: _fieldDeco(
                label: s.requirementFieldContactPhone,
                hint: s.requirementFieldContactPhoneHint,
                icon: Icons.phone_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requirementContactPhoneRequired : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _messenger,
              textInputAction: TextInputAction.next,
              decoration: _fieldDeco(
                label: s.isEnglish ? s.requirementFieldWhatsApp : s.requirementFieldLineId,
                hint: s.isEnglish ? '@username' : 'Line ID',
                icon: s.isEnglish ? Icons.chat_outlined : Icons.chat_bubble_outline,
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(s.requirementFieldTransaction),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              segments: [
                ButtonSegment(value: 'rent', label: Text(s.rent)),
                ButtonSegment(value: 'sale', label: Text(s.sale)),
              ],
              selected: {_transactionType},
              onSelectionChanged: (v) {
                setState(() {
                  _transactionType = v.first;
                  _resetBudgetForTransaction();
                });
              },
            ),
            const SizedBox(height: 18),
            _sectionTitle(s.requirementFieldProperty),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slug in _mainPropertySlugs) _propertyChip(slug),
                _propertyOthersChip(),
              ],
            ),
            const SizedBox(height: 18),
            RequirementLocationPicker(
              entries: _locations,
              onChanged: (v) => setState(() {
                _locations = v;
                _locationTouched = true;
              }),
            ),
            if (_locationTouched && _locations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  s.requirementZoneRequired,
                  style: TextStyle(fontSize: 12, color: AppTheme.error),
                ),
              ),
            const SizedBox(height: 18),
            BudgetRangeSlider(
              minPos: _minPricePos,
              maxPos: _maxPricePos,
              isSale: _isSale,
              onChanged: (v) => setState(() {
                _minPricePos = v.start;
                _maxPricePos = v.end;
              }),
            ),
            if (!_isSale) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickContractStart,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _fieldDeco(
                    label: s.requirementFieldContractStart,
                    icon: Icons.calendar_today_outlined,
                  ),
                  child: Text(
                    _contractStartBy != null
                        ? dateFmt.format(_contractStartBy!)
                        : s.requirementFieldContractStartHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: _contractStartBy != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(s.requirementFieldFurnishing, style: _labelStyle),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _furnChip('unfurnished', s.requirementFurnishingEmpty),
                  _furnChip('furnished', s.requirementFurnishingFull),
                  _furnChip('any', s.requirementFurnishingAny),
                ],
              ),
            ],
            if (_isSale) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _multiChip('cash', s.requirementBuyPaymentCash, _buyPayments),
                  _multiChip('loan', s.requirementBuyPaymentLoan, _buyPayments),
                  _multiChip('with_tenant', s.requirementBuyWithTenant, _buyPurposes),
                  _multiChip('vacant', s.requirementBuyVacant, _buyPurposes),
                  _multiChip('investment_yield', s.requirementBuyInvestment, _buyPurposes),
                  _multiChip('own_stay', s.requirementBuyOwnStay, _buyPurposes),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _sectionTitle(s.requirementSectionDetails),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _decisionTimeframe,
              decoration: _fieldDeco(
                label: s.requirementFieldDecisionShort,
                icon: Icons.schedule_outlined,
              ),
              items: [
                for (final key in _decisionKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(
                      s.requirementDecisionLabel(key),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _decisionTimeframe = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minArea,
              keyboardType: TextInputType.number,
              decoration: _fieldDeco(
                label: s.requirementFieldMinAreaShort,
                hint: s.requirementFieldMinAreaHint,
                icon: Icons.square_foot_outlined,
                suffix: s.t('ตร.ม.', 'sqm'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: _fieldDeco(
                label: s.requirementFieldNotes,
                hint: s.requirementFieldNotesHint,
                icon: Icons.notes_outlined,
                alignLabel: true,
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: AppTheme.pillFilled,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(s.requirementSubmitCta, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDeco({
    required String label,
    String? hint,
    IconData? icon,
    String? suffix,
    bool alignLabel = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabel,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      suffixText: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );

  TextStyle get _labelStyle =>
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 13);

  Widget _roleCard(String role, String title, String hint) {
    final selected = _requesterRole == role;
    return Material(
      color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.backgroundAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _requesterRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _propertyChip(String slug) {
    final cat = PropertyCatalog.bySlug(slug)!;
    final s = AppStrings.of(context);
    final selected = _propertyTypes.contains(slug);
    return FilterChip(
      label: Text(cat.label(s.isEnglish)),
      selected: selected,
      showCheckmark: true,
      onSelected: (on) {
        setState(() {
          if (on) {
            _propertyTypes.add(slug);
          } else if (_propertyTypes.length > 1) {
            _propertyTypes.remove(slug);
          }
        });
      },
    );
  }

  Widget _propertyOthersChip() {
    final s = AppStrings.of(context);
    final moreCount = _propertyTypes.where(PropertyTypeMoreSheet.isMoreSlug).length;
    final selected = moreCount > 0;
    final label = selected
        ? '${s.requirementPropertyOthers} ($moreCount)'
        : s.requirementPropertyOthers;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: (_) => PropertyTypeMoreSheet.showMultiPicker(
        context,
        selectedSlugs: _propertyTypes,
        onChanged: (slugs) => setState(() {
          _propertyTypes
            ..clear()
            ..addAll(slugs);
        }),
      ),
    );
  }

  Widget _furnChip(String value, String label) {
    final selected = _furnishing == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _furnishing = value),
    );
  }

  Widget _multiChip(String value, String label, Set<String> target) {
    final selected = target.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (on) {
        setState(() {
          if (on) {
            target.add(value);
          } else {
            target.remove(value);
          }
        });
      },
    );
  }
}
