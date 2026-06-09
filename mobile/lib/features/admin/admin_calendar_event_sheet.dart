import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/calendar_event.dart';
import '../../services/auth_service.dart';
import '../../services/calendar_event_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

Future<void> showAdminCalendarEventSheet(
  BuildContext context, {
  required CalendarEvent initial,
  required Future<void> Function() onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _AdminCalendarEventSheet(
      initial: initial,
      onSaved: onSaved,
    ),
  );
}

class _AdminCalendarEventSheet extends StatefulWidget {
  const _AdminCalendarEventSheet({
    required this.initial,
    required this.onSaved,
  });

  final CalendarEvent initial;
  final Future<void> Function() onSaved;

  @override
  State<_AdminCalendarEventSheet> createState() =>
      _AdminCalendarEventSheetState();
}

class _AdminCalendarEventSheetState extends State<_AdminCalendarEventSheet> {
  final _repo = CalendarEventRepository();
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _location;
  late CalendarEvent _event;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _event = widget.initial;
    _title = TextEditingController(text: _event.title);
    _description = TextEditingController(text: _event.description ?? '');
    _location = TextEditingController(text: _event.locationLabel ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save({bool confirm = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actor = AuthService.instance.effectiveUserId;
      var next = await _repo.updateHuman(
        current: _event,
        title: _title.text.trim(),
        description: _description.text.trim(),
        locationLabel: _location.text.trim(),
        actorUserId: actor,
      );
      if (confirm && next.isAiDraft) {
        next = await _repo.confirmDraft(next);
      }
      if (!mounted) return;
      setState(() => _event = next);
      await widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirm
                ? context.s.adminCalendarConfirmAiDraftDone
                : context.s.adminCalendarEventSaved,
          ),
        ),
      );
    } on CalendarVersionConflictException {
      if (!mounted) return;
      setState(() => _error = context.s.adminCalendarVersionConflict);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAi() async {
    setState(() => _busy = true);
    try {
      final refreshed = await _repo.runAiDraft(
        threadId: _event.threadId,
        leadId: _event.leadId,
        appointmentId: _event.appointmentId,
      );
      if (!mounted) return;
      if (refreshed != null) {
        setState(() {
          _event = refreshed;
          if (!_event.isHumanLockedTitle) _title.text = _event.title;
          if (!_event.isHumanLockedDescription) {
            _description.text = _event.description ?? '';
          }
          if (_event.locationLabel != null && _event.fieldLocks['location_label'] != 'human') {
            _location.text = _event.locationLabel!;
          }
        });
        await widget.onSaved();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.adminCalendarEventEditTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (_event.isAiDraft) ...[
              const SizedBox(height: 6),
              Text(s.adminCalendarAiDraftHint, style: AdminTheme.caption),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: s.adminCalendarEventTitleLabel,
                border: const OutlineInputBorder(),
                suffixIcon: _event.isHumanLockedTitle
                    ? Icon(Icons.lock_outline, size: 18, color: Colors.orange.shade800)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: s.adminCalendarEventLocationLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: s.adminCalendarEventDescriptionLabel,
                border: const OutlineInputBorder(),
                suffixIcon: _event.isHumanLockedDescription
                    ? Icon(Icons.lock_outline, size: 18, color: Colors.orange.shade800)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.adminCalendarEventTimeLabel}: ${_event.timeSlotLabel}',
              style: AdminTheme.caption,
            ),
            if (_event.fieldLocks.isNotEmpty)
              Text(
                s.adminCalendarHumanLockedCount(_event.fieldLocks.length),
                style: AdminTheme.caption.copyWith(color: Colors.orange.shade800),
              ),
            const SizedBox(height: 14),
            if (_busy) const LinearProgressIndicator(),
            Row(
              children: [
                if (_event.isAiDraft)
                  TextButton.icon(
                    onPressed: _busy ? null : _refreshAi,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(s.adminCalendarRefreshAi),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _save(confirm: false),
                  child: Text(s.save),
                ),
                if (_event.isAiDraft) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : () => _save(confirm: true),
                    child: Text(s.adminCalendarConfirmAiDraft),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
