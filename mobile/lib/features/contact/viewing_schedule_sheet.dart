import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class ViewingScheduleResult {
  const ViewingScheduleResult({required this.scheduledAt});

  final DateTime scheduledAt;
}

Future<ViewingScheduleResult?> showViewingScheduleSheet(BuildContext context) {
  return showModalBottomSheet<ViewingScheduleResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _ScheduleBody(),
  );
}

class _ScheduleBody extends StatefulWidget {
  const _ScheduleBody();

  @override
  State<_ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<_ScheduleBody> {
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;

  String _dateLabel(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return 'เลือกเวลา';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} น.';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final s = AppStrings.of(context);
    var selected = _time ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                Expanded(
                  child: Text(s.selectViewingTime, textAlign: TextAlign.center),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(s.ok),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2024, 1, 1, selected.hour, selected.minute),
                onDateTimeChanged: (dt) {
                  selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final s = context.s;
    if (_date == null || _time == null) {
      setState(() => _error = s.errRequiredFields);
      return;
    }
    final at = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    Navigator.pop(context, ViewingScheduleResult(scheduledAt: at));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.viewingScheduleTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(s.viewingScheduleHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
            ),
            title: Text(s.selectDate),
            trailing: Text(_dateLabel(s, _date)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
            ),
            title: Text(s.selectViewingTime),
            trailing: Text(_timeLabel(_time)),
            onTap: _pickTime,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppTheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: Text(s.viewingScheduleSubmit)),
        ],
      ),
    );
  }
}
