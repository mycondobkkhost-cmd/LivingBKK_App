import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/commission_agreement_context.dart';
import '../../models/lead_success_fee.dart';
import '../../theme/app_theme.dart';
import 'commission_agreement_sheet.dart';

enum OwnerViewingResponseMode { confirmRequested, proposeAlternative }

class OwnerViewingResponse {
  const OwnerViewingResponse({
    required this.mode,
    this.requestedSchedule,
    this.proposedDate,
    this.timeStart,
    this.timeEnd,
    this.note,
  });

  final OwnerViewingResponseMode mode;
  final String? requestedSchedule;
  final DateTime? proposedDate;
  final String? timeStart;
  final String? timeEnd;
  final String? note;

  String displaySchedule(AppStrings s) {
    if (mode == OwnerViewingResponseMode.confirmRequested) {
      return requestedSchedule?.trim().isNotEmpty == true
          ? requestedSchedule!.trim()
          : s.ownerViewingAsRequestedFallback;
    }
    final date = proposedDate;
    if (date == null) return '—';
    final y = date.year + (s.isEnglish ? 0 : 543);
    final dateLine = '${date.day}/${date.month}/$y';
    final from = timeStart ?? '—';
    final to = timeEnd ?? '—';
    return '$dateLine · $from – $to';
  }

  Map<String, dynamic> toJson() => {
        'mode': mode == OwnerViewingResponseMode.confirmRequested
            ? 'confirm_requested'
            : 'propose_alternative',
        if (requestedSchedule != null && requestedSchedule!.trim().isNotEmpty)
          'schedule': requestedSchedule!.trim(),
        if (proposedDate != null)
          'proposed_date': proposedDate!.toIso8601String().split('T').first,
        if (timeStart != null) 'time_start': timeStart,
        if (timeEnd != null) 'time_end': timeEnd,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

Future<OwnerViewingResponse?> showOwnerViewingResponseSheet(
  BuildContext context, {
  String? requestedSchedule,
  String? listingCode,
  String? leadId,
  String? listingId,
  LeadSuccessFeeSummary? successFee,
}) {
  return showModalBottomSheet<OwnerViewingResponse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _OwnerViewingResponseBody(
      requestedSchedule: requestedSchedule,
      listingCode: listingCode,
      leadId: leadId,
      listingId: listingId,
      successFee: successFee,
    ),
  );
}

class _OwnerViewingResponseBody extends StatefulWidget {
  const _OwnerViewingResponseBody({
    this.requestedSchedule,
    this.listingCode,
    this.leadId,
    this.listingId,
    this.successFee,
  });

  final String? requestedSchedule;
  final String? listingCode;
  final String? leadId;
  final String? listingId;
  final LeadSuccessFeeSummary? successFee;

  @override
  State<_OwnerViewingResponseBody> createState() =>
      _OwnerViewingResponseBodyState();
}

class _OwnerViewingResponseBodyState extends State<_OwnerViewingResponseBody> {
  OwnerViewingResponseMode _mode = OwnerViewingResponseMode.confirmRequested;
  DateTime? _proposedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _timeStart = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _timeEnd = const TimeOfDay(hour: 12, minute: 0);
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    var selected = initial;
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (ctx) {
        final base = DateTime(2020, 1, 1, selected.hour, selected.minute);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: base,
                  use24hFormat: true,
                  onDateTimeChanged: (dt) {
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: Text(AppStrings.of(context).ok),
              ),
            ],
          ),
        );
      },
    );
  }

  void _appendNote(String snippet) {
    final cur = _noteCtrl.text.trim();
    _noteCtrl.text = cur.isEmpty ? snippet : '$cur\n$snippet';
    _noteCtrl.selection = TextSelection.collapsed(offset: _noteCtrl.text.length);
    setState(() {});
  }

  bool get _canSubmit {
    if (_mode == OwnerViewingResponseMode.confirmRequested) return true;
    return _proposedDate != null &&
        _timeEnd.hour * 60 + _timeEnd.minute >
            _timeStart.hour * 60 + _timeStart.minute;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final s = AppStrings.of(context);
    final agreed = await showCommissionAgreementSheet(
      context,
      agreementContext: CommissionAgreementContext.confirmViewing,
      title: s.t(
        'ข้อตกลงก่อนยืนยันนัดดู',
        'Agreement before confirming viewing',
      ),
      summaryLines: [
        s.t(
          'ยืนยันนัดชมทรัพย์ตามที่ลูกค้าขอ หรือเสนอวัน/เวลาใหม่',
          'Confirm viewing as requested or propose new date/time',
        ),
        if (widget.requestedSchedule?.trim().isNotEmpty == true)
          '${s.t('วันนัดที่ลูกค้าขอ', 'Requested schedule')}: '
              '${widget.requestedSchedule!.trim()}',
      ],
      schemeSnapshot: {
        'mode': _mode.name,
        if (widget.listingCode != null) 'listing_code': widget.listingCode,
      },
      listingId: widget.listingId,
      leadId: widget.leadId,
      successFee: widget.successFee,
      listingCode: widget.listingCode,
    );
    if (!agreed || !mounted) return;

    Navigator.pop(
      context,
      OwnerViewingResponse(
        mode: _mode,
        requestedSchedule: widget.requestedSchedule,
        proposedDate: _mode == OwnerViewingResponseMode.proposeAlternative
            ? _proposedDate
            : null,
        timeStart: _mode == OwnerViewingResponseMode.proposeAlternative
            ? _formatTime(_timeStart)
            : null,
        timeEnd: _mode == OwnerViewingResponseMode.proposeAlternative
            ? _formatTime(_timeEnd)
            : null,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final schedule = widget.requestedSchedule?.trim();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.ownerViewingResponseTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              s.ownerViewingResponseSubtitle,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
            if (schedule != null && schedule.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.ownerViewingCustomerRequestLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(schedule, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<OwnerViewingResponseMode>(
              segments: [
                ButtonSegment(
                  value: OwnerViewingResponseMode.confirmRequested,
                  label: Text(s.ownerViewingModeConfirm),
                  icon: const Icon(Icons.check, size: 18),
                ),
                ButtonSegment(
                  value: OwnerViewingResponseMode.proposeAlternative,
                  label: Text(s.ownerViewingModeAlternative),
                  icon: const Icon(Icons.schedule, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            if (_mode == OwnerViewingResponseMode.proposeAlternative) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _proposedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _proposedDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _proposedDate == null
                      ? s.selectDate
                      : s.viewingDateLabel(
                          '${_proposedDate!.day}/${_proposedDate!.month}/${_proposedDate!.year + (s.isEnglish ? 0 : 543)}',
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickTime(_timeStart);
                        if (picked != null) setState(() => _timeStart = picked);
                      },
                      child: Text(s.ownerViewingTimeFrom(_formatTime(_timeStart))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickTime(_timeEnd);
                        if (picked != null) setState(() => _timeEnd = picked);
                      },
                      child: Text(s.ownerViewingTimeTo(_formatTime(_timeEnd))),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: s.ownerViewingNoteLabel,
                hintText: s.ownerViewingNoteHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text(s.ownerViewingNoteJuristicKey),
                  onPressed: () => _appendNote(s.ownerViewingNoteJuristicKeyBody),
                ),
                ActionChip(
                  label: Text(s.ownerViewingNoteSelfView),
                  onPressed: () => _appendNote(s.ownerViewingNoteSelfViewBody),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(s.ownerViewingSubmitConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
