import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/participant_profile_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/budget_range_slider.dart';
import 'intake_flow_config.dart';

/// ชั้น 1 — ฟิลด์โปรไฟล์มาตรฐาน (ใช้ร่วมทุกงาน)
class ParticipantProfileSection extends StatelessWidget {
  const ParticipantProfileSection({
    super.key,
    required this.profile,
    required this.config,
    required this.onChanged,
    required this.nicknameCtrl,
    required this.phoneCtrl,
    required this.customerLast4Ctrl,
    required this.occupationCtrl,
    required this.workplaceCtrl,
    required this.notesCtrl,
    required this.onPickContractStart,
  });

  final ParticipantProfileData profile;
  final IntakeFlowConfig config;
  final VoidCallback onChanged;
  final TextEditingController nicknameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController customerLast4Ctrl;
  final TextEditingController occupationCtrl;
  final TextEditingController workplaceCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onPickContractStart;

  String _dateLabel(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          profile.isCoAgent
              ? s.t('โปรไฟล์ลูกค้า (แก้ไขได้)', 'Client profile (editable)')
              : s.t('โปรไฟล์ของคุณ (แก้ไขได้)', 'Your profile (editable)'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: nicknameCtrl,
          decoration: InputDecoration(labelText: s.nicknameRequired),
          onChanged: (_) {
            profile.nickname = nicknameCtrl.text;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneCtrl,
          decoration: InputDecoration(labelText: s.phoneRequiredField),
          keyboardType: TextInputType.phone,
          onChanged: (_) {
            profile.phone = phoneCtrl.text;
            onChanged();
          },
        ),
        if (profile.isCoAgent) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customerLast4Ctrl,
            decoration: InputDecoration(
              labelText: s.customerPhoneLast4,
              hintText: s.customerPhoneLast4Hint,
              helperText: s.customerPhoneLast4Helper,
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: (_) {
              profile.customerPhoneLast4 = customerLast4Ctrl.text;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: profile.occupants,
          decoration: InputDecoration(
            labelText: s.occupantsRequired,
            border: const OutlineInputBorder(),
          ),
          items: const ['1', '2', '3', '4', '5+']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            profile.occupants = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: profile.gender,
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
          onChanged: (v) {
            profile.gender = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: occupationCtrl,
          decoration: InputDecoration(
            labelText: s.occupationRequired,
            hintText: s.occupationHint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            profile.occupation = occupationCtrl.text;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: workplaceCtrl,
          decoration: InputDecoration(labelText: s.workplaceLabel),
          onChanged: (_) {
            profile.workplace = workplaceCtrl.text;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: profile.contract,
          decoration: InputDecoration(
            labelText: s.contractDurationRequired,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: '6m', child: Text(s.contract6Months)),
            DropdownMenuItem(value: '12m', child: Text(s.contract1Year)),
            DropdownMenuItem(value: '24m', child: Text(s.contract2Years)),
          ],
          onChanged: (v) {
            profile.contract = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        if (config.intent != IntakeIntent.requirement)
          BudgetRangeSlider(
            minPos: profile.budgetMinPos,
            maxPos: profile.budgetMaxPos,
            onChanged: (v) {
              profile.budgetMinPos = v.start;
              profile.budgetMaxPos = v.end;
              onChanged();
            },
          ),
        if (config.showContractStart) ...[
          const SizedBox(height: 16),
          Text(s.contractStartLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickContractStart,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateLabel(s, profile.contractStartDate)),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: profile.contractNotLaterThan,
            onChanged: profile.contractStartDate == null
                ? null
                : (v) {
                    profile.contractNotLaterThan = v ?? false;
                    onChanged();
                  },
            title: Text(s.contractStartNotLater, style: const TextStyle(fontSize: 13)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
        if (config.showLifestyleFields) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: profile.hasCar,
            decoration: InputDecoration(
              labelText: s.hasCarLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'yes', child: Text(s.hasCarYes)),
              DropdownMenuItem(value: 'no', child: Text(s.hasCarNo)),
            ],
            onChanged: (v) {
              profile.hasCar = v;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: profile.smoking,
            decoration: InputDecoration(
              labelText: s.smokingLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'no', child: Text(s.smokeNo)),
              DropdownMenuItem(value: 'yes', child: Text(s.smokeYes)),
            ],
            onChanged: (v) {
              profile.smoking = v;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: profile.pets,
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
            onChanged: (v) {
              profile.pets = v;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: s.summaryNotes,
            hintText: s.viewingFormNotesHint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            profile.notes = notesCtrl.text;
            onChanged();
          },
        ),
      ],
    );
  }
}

/// ชั้น 2 — วันเวลานัดดู
class ViewingScheduleExtension extends StatelessWidget {
  const ViewingScheduleExtension({
    super.key,
    required this.viewingDate,
    required this.viewingTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime? viewingDate;
  final TimeOfDay? viewingTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  String _dateLabel(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return 'เลือกเวลา';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          s.viewingRequired,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.event_available, size: 18),
          label: Text(s.viewingDateLabel(_dateLabel(s, viewingDate))),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickTime,
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(s.viewingTimeLabel(_timeLabel(viewingTime))),
        ),
      ],
    );
  }
}

/// ชั้น 2 — คำถามสอบถามเจ้าของ
class InquiryQuestionExtension extends StatelessWidget {
  const InquiryQuestionExtension({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          s.ownerInquiryAskSection,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: s.ownerInquiryOpenAskLabel,
            hintText: hint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// helper เลือกเวลานัดดู
Future<TimeOfDay?> pickViewingTimeSheet(BuildContext context) async {
  final s = AppStrings.of(context);
  var selected = const TimeOfDay(hour: 10, minute: 0);
  return showModalBottomSheet<TimeOfDay>(
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
}

String? viewingScheduleSummary(
  AppStrings s,
  DateTime? date,
  TimeOfDay? time,
) {
  if (date == null || time == null) return null;
  final y = date.year + (s.isEnglish ? 0 : 543);
  final dateLine = '${date.day}/${date.month}/$y';
  final timeLine =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  return '$dateLine · $timeLine';
}
