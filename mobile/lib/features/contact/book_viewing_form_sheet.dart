import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../services/lead_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/price_slider_scale.dart';
import '../../widgets/budget_range_slider.dart';

class ViewingSubmitResult {
  const ViewingSubmitResult({
    required this.summary,
    required this.savedToDatabase,
    this.duplicatePhoneSuffix = false,
    this.leadTransactionRef,
  });

  final Map<String, String> summary;
  final bool savedToDatabase;
  final bool duplicatePhoneSuffix;
  final String? leadTransactionRef;
}

Future<ViewingSubmitResult?> showBookViewingFormSheet(
  BuildContext context, {
  required ChatRoom room,
}) {
  return showModalBottomSheet<ViewingSubmitResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _BookViewingForm(room: room),
  );
}

class _BookViewingForm extends StatefulWidget {
  const _BookViewingForm({required this.room});

  final ChatRoom room;

  @override
  State<_BookViewingForm> createState() => _BookViewingFormState();
}

class _BookViewingFormState extends State<_BookViewingForm> {
  final _repo = LeadRepository();
  bool _submitting = false;

  String? _applicantType;
  String? _occupants;
  String? _hasCar;
  String? _smoking;
  String? _pets;
  String? _contract;
  String? _gender;
  double _budgetMinPos = 0;
  double _budgetMaxPos = PriceSliderScale.rentBahtToPosition(30000);
  DateTime? _contractStartDate;
  bool _contractNotLaterThan = false;
  DateTime? _viewingDate;
  TimeOfDay? _viewingTime;

  final _nickname = TextEditingController();
  final _phone = TextEditingController();
  final _customerPhoneLast4 = TextEditingController();
  final _occupation = TextEditingController();
  final _workplace = TextEditingController();
  String? _formError;

  double get _budgetMin => PriceSliderScale.rentPositionToBaht(_budgetMinPos);
  double get _budgetMax => PriceSliderScale.rentPositionToBaht(_budgetMaxPos);

  @override
  void dispose() {
    _nickname.dispose();
    _phone.dispose();
    _customerPhoneLast4.dispose();
    _occupation.dispose();
    _workplace.dispose();
    super.dispose();
  }

  String _applicantLabel(AppStrings s) {
    switch (_applicantType) {
      case 'seeker_self':
        return s.customerRole;
      case 'co_agent_request':
        return s.coAgentRole;
      default:
        return '-';
    }
  }

  String _dateLabel(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return 'เลือกเวลา';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} น.';
  }

  Future<void> _pickContractStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractStartDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _contractStartDate = picked);
  }

  Future<void> _pickViewingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewingDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() => _viewingDate = picked);
  }

  Future<void> _pickViewingTime() async {
    final s = AppStrings.of(context);
    var selected = _viewingTime ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s.cancel),
                        ),
                        Expanded(
                          child: Text(
                            s.selectViewingTime,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, selected),
                          child: Text(s.ok),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime:
                          DateTime(2024, 1, 1, selected.hour, selected.minute),
                      onDateTimeChanged: (dt) {
                        setModalState(() {
                          selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _viewingTime = picked);
  }

  String? _contractStartSummary(AppStrings s) {
    if (_contractStartDate == null) return null;
    if (_contractNotLaterThan) {
      return s.contractStartNotLaterThan(_dateLabel(s, _contractStartDate));
    }
    return s.contractStartOn(_dateLabel(s, _contractStartDate));
  }

  String? _viewingSummary(AppStrings s) {
    if (_viewingDate == null || _viewingTime == null) return null;
    return '${_dateLabel(s, _viewingDate)} · ${_timeLabel(_viewingTime)}';
  }

  Map<String, String> _buildSummary(AppStrings s) {
    final budgetRange =
        '${PriceSliderScale.formatBaht(_budgetMin, isSale: false)} – ${PriceSliderScale.formatBaht(_budgetMax, isSale: false)}';

    return {
      s.summaryWhoAreYou: _applicantLabel(s),
      s.summaryNickname: _nickname.text.trim(),
      s.summaryPhone: _phone.text.trim(),
      if (_applicantType == 'co_agent_request' &&
          _customerPhoneLast4.text.trim().isNotEmpty)
        s.summaryCustomerLast4: _customerPhoneLast4.text.trim(),
      s.summaryOccupants: _occupants ?? '-',
      if (_gender != null) s.summaryGender: leadGenderLabel(_gender),
      s.summaryOccupation: _occupation.text.trim(),
      if (_workplace.text.trim().isNotEmpty) s.summaryWorkplace: _workplace.text.trim(),
      s.summaryContract: _contractLabel(s),
      s.summaryBudget: budgetRange,
      if (_contractStartSummary(s) != null)
        s.summaryContractStart: _contractStartSummary(s)!,
      if (_hasCar != null) s.summaryHasCar: _hasCar == 'yes' ? s.hasCarYes : s.hasCarNo,
      if (_smoking != null) s.summarySmoking: _smoking == 'yes' ? s.smokeYes : s.smokeNo,
      if (_pets != null) s.summaryPets: _petsLabel(s),
      if (_viewingSummary(s) != null) s.summaryViewing: _viewingSummary(s)!,
    };
  }

  String _contractLabel(AppStrings s) {
    switch (_contract) {
      case '6m':
        return s.contract6Months;
      case '12m':
        return s.contract1Year;
      case '24m':
        return s.contract2Years;
      default:
        return '-';
    }
  }

  String _petsLabel(AppStrings s) {
    switch (_pets) {
      case 'none':
        return s.petNone;
      case 'cat':
        return s.petCat;
      case 'dog':
        return s.petDog;
      case 'other':
        return s.petOther;
      default:
        return '-';
    }
  }

  int? _parseOccupants(String? raw) {
    if (raw == null) return null;
    if (raw.contains('+')) return int.tryParse(raw.replaceAll('+', ''));
    return int.tryParse(raw);
  }

  void _setFormError(String message) => setState(() => _formError = message);

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    setState(() => _formError = null);

    if (_applicantType == null) {
      _setFormError(s.errSelectApplicantType);
      return;
    }
    if (_nickname.text.trim().isEmpty || _phone.text.trim().length < 9) {
      _setFormError(s.errNicknamePhone);
      return;
    }
    if (_occupants == null ||
        _occupation.text.trim().isEmpty ||
        _contract == null ||
        _viewingDate == null ||
        _viewingTime == null) {
      _setFormError(s.errRequiredFields);
      return;
    }

    String? customerLast4;
    var duplicateSuffix = false;
    if (_applicantType == 'co_agent_request') {
      customerLast4 = LeadRepository.normalizePhoneSuffix(_customerPhoneLast4.text);
      if (customerLast4.length != 4) {
        _setFormError(s.errCoAgentLast4);
        return;
      }
      duplicateSuffix = await _repo.isDuplicateCustomerPhoneSuffix(customerLast4);
    }

    setState(() => _submitting = true);
    final summary = _buildSummary(s);
    final movePlan = summary[s.summaryContractStart];
    final viewingSchedule = summary[s.summaryViewing];

    try {
      final outcome = await _repo.submit(
        LeadSubmission(
          listingCode: widget.room.listingCode,
          listingId: widget.room.listingId,
          seekerNickname: _nickname.text.trim(),
          seekerPhone: _phone.text.trim(),
          applicantType: _applicantType,
          occupantsCount: _parseOccupants(_occupants),
          gender: _gender,
          occupation: _occupation.text.trim(),
          workplace: _workplace.text.trim().isEmpty ? null : _workplace.text.trim(),
          movePlan: movePlan,
          contractDuration: _contract!,
          budget: _budgetMax,
          budgetMin: _budgetMin,
          budgetMax: _budgetMax,
          viewingSchedule: viewingSchedule,
          hasCar: _hasCar == 'yes',
          pets: _pets,
          smoking: _smoking == 'yes' ? 'yes' : (_smoking == 'no' ? 'no' : null),
          customerPhoneLast4: customerLast4,
          duplicatePhoneSuffix: duplicateSuffix,
        ),
      );

      await ChatService.instance.appendViewingSummary(
        widget.room,
        summary,
        duplicatePhoneSuffix: duplicateSuffix,
      );

      if (!mounted) return;
      Navigator.pop(
        context,
        ViewingSubmitResult(
          summary: summary,
          savedToDatabase: outcome.savedToDatabase,
          duplicatePhoneSuffix: duplicateSuffix,
          leadTransactionRef: outcome.transactionRef,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _setFormError(s.submitFailedWith('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.requestViewingTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              widget.room.displayTitle,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _applicantType,
              decoration: InputDecoration(
                labelText: s.whoAreYouRequired,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'seeker_self',
                  child: Text(s.customerRole),
                ),
                DropdownMenuItem(
                  value: 'co_agent_request',
                  child: Text(s.coAgentRole),
                ),
              ],
              onChanged: (v) => setState(() {
                _applicantType = v;
                if (v != 'co_agent_request') _customerPhoneLast4.clear();
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nickname,
              decoration: InputDecoration(labelText: s.nicknameRequired),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: InputDecoration(labelText: s.phoneRequiredField),
              keyboardType: TextInputType.phone,
            ),
            if (_applicantType == 'co_agent_request') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customerPhoneLast4,
                decoration: InputDecoration(
                  labelText: s.customerPhoneLast4,
                  hintText: s.customerPhoneLast4Hint,
                  helperText: s.customerPhoneLast4Helper,
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _occupants,
              decoration: InputDecoration(
                labelText: s.occupantsRequired,
                border: const OutlineInputBorder(),
              ),
              items: const ['1', '2', '3', '4', '5+']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _occupants = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: s.genderLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'male', child: Text(s.genderMale)),
                DropdownMenuItem(value: 'female', child: Text(s.genderFemale)),
                DropdownMenuItem(value: 'lgbtq_plus', child: Text(s.genderLgbtq)),
                DropdownMenuItem(value: 'prefer_not_say', child: Text(s.genderPreferNot)),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _occupation,
              decoration: InputDecoration(
                labelText: s.occupationRequired,
                hintText: s.occupationHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _workplace,
              decoration: InputDecoration(labelText: s.workplaceLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _contract,
              decoration: InputDecoration(
                labelText: s.contractDurationRequired,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '6m', child: Text(s.contract6Months)),
                DropdownMenuItem(value: '12m', child: Text(s.contract1Year)),
                DropdownMenuItem(value: '24m', child: Text(s.contract2Years)),
              ],
              onChanged: (v) => setState(() => _contract = v),
            ),
            const SizedBox(height: 16),
            BudgetRangeSlider(
              minPos: _budgetMinPos,
              maxPos: _budgetMaxPos,
              onChanged: (v) => setState(() {
                _budgetMinPos = v.start;
                _budgetMaxPos = v.end;
              }),
            ),
            const SizedBox(height: 16),
            Text(
              s.contractStartLabel,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickContractStartDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dateLabel(s, _contractStartDate)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _contractNotLaterThan,
              onChanged: _contractStartDate == null
                  ? null
                  : (v) => setState(() => _contractNotLaterThan = v ?? false),
              title: Text(
                s.contractStartNotLater,
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            Text(
              s.viewingRequired,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickViewingDate,
              icon: const Icon(Icons.event_available, size: 18),
              label: Text(s.viewingDateLabel(_dateLabel(s, _viewingDate))),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickViewingTime,
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(s.viewingTimeLabel(_timeLabel(_viewingTime))),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _hasCar,
              decoration: InputDecoration(
                labelText: s.hasCarLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'yes', child: Text(s.hasCarYes)),
                DropdownMenuItem(value: 'no', child: Text(s.hasCarNo)),
              ],
              onChanged: (v) => setState(() => _hasCar = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _smoking,
              decoration: InputDecoration(
                labelText: s.smokingLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'no', child: Text(s.smokeNo)),
                DropdownMenuItem(value: 'yes', child: Text(s.smokeYes)),
              ],
              onChanged: (v) => setState(() => _smoking = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _pets,
              decoration: InputDecoration(
                labelText: s.petsLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'none', child: Text(s.petNone)),
                DropdownMenuItem(value: 'cat', child: Text(s.petCat)),
                DropdownMenuItem(value: 'dog', child: Text(s.petDog)),
                DropdownMenuItem(value: 'other', child: Text(s.petOther)),
              ],
              onChanged: (v) => setState(() => _pets = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.submitViewingRequest),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
