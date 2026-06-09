import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/viewing_report.dart';
import '../../theme/app_theme.dart';

Future<ViewingReportSheetResult?> showAdminViewingFollowUpSheet(
  BuildContext context, {
  String? listingCode,
  String? timeSlot,
  String? viewedDateLabel,
}) {
  return showModalBottomSheet<ViewingReportSheetResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _ViewingReportSheet(
      listingCode: listingCode,
      timeSlot: timeSlot,
      viewedDateLabel: viewedDateLabel,
    ),
  );
}

class _ViewingReportSheet extends StatefulWidget {
  const _ViewingReportSheet({
    this.listingCode,
    this.timeSlot,
    this.viewedDateLabel,
  });

  final String? listingCode;
  final String? timeSlot;
  final String? viewedDateLabel;

  @override
  State<_ViewingReportSheet> createState() => _ViewingReportSheetState();
}

class _ViewingReportSheetState extends State<_ViewingReportSheet> {
  ViewingFollowUpDecision _decision = ViewingFollowUpDecision.continueFollow;
  ViewingFollowUpIntent _intent = ViewingFollowUpIntent.consider;
  final _outcomeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  final _wantsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _outcomePreset;
  bool _saving = false;

  @override
  void dispose() {
    _outcomeCtrl.dispose();
    _feedbackCtrl.dispose();
    _wantsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isNoShow(AppStrings s) =>
      _outcomePreset == s.viewingReportNoShowPreset(s.isEnglish);

  void _submit() {
    if (_saving) return;
    final s = context.s;
    final noShow = _isNoShow(s);
    final outcome = [
      if (_outcomePreset != null && _outcomePreset!.isNotEmpty) _outcomePreset,
      if (_outcomeCtrl.text.trim().isNotEmpty) _outcomeCtrl.text.trim(),
    ].join(' — ');
    final notes = _notesCtrl.text.trim();
    final feedback = _feedbackCtrl.text.trim();
    final wants = _wantsCtrl.text.trim();

    if (outcome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminViewingReportNeedOutcome)),
      );
      return;
    }
    if (noShow && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminViewingReportNeedNoShowNote)),
      );
      return;
    }
    if (!noShow && feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminViewingReportNeedFeedback)),
      );
      return;
    }
    if (!noShow && wants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminViewingReportNeedWants)),
      );
      return;
    }

    setState(() => _saving = true);
    Navigator.pop(
      context,
      ViewingReportSheetResult(
        decision: noShow ? ViewingFollowUpDecision.closeCase : _decision,
        intent: !noShow && _decision == ViewingFollowUpDecision.continueFollow
            ? _intent
            : null,
        outcome: outcome,
        customerFeedback: noShow
            ? (feedback.isEmpty ? s.adminCalendarNoShowBadge : feedback)
            : feedback,
        customerWants: noShow
            ? (wants.isEmpty ? '—' : wants)
            : wants,
        teamNotes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.adminViewingReportTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            if (widget.listingCode != null && widget.listingCode!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.listingCode}'
                '${widget.viewedDateLabel != null ? ' · ${widget.viewedDateLabel}' : ''}'
                '${widget.timeSlot != null ? ' · ${widget.timeSlot}' : ''}',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              s.adminViewingReportIntro,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            _fieldLabel(s.adminViewingReportOutcomeLabel, required: true),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: s.adminViewingReportOutcomePresets.map((p) {
                final noShow = p == s.viewingReportNoShowPreset(s.isEnglish);
                return ChoiceChip(
                  label: Text(p, style: const TextStyle(fontSize: 11)),
                  selected: _outcomePreset == p,
                  onSelected: (_) => setState(() {
                    _outcomePreset = p;
                    if (noShow) _decision = ViewingFollowUpDecision.closeCase;
                  }),
                  selectedColor: noShow ? Colors.red.shade100 : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _outcomeCtrl,
              decoration: InputDecoration(
                hintText: s.adminViewingReportOutcomeHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _fieldLabel(s.adminViewingReportFeedbackLabel, required: true),
            TextField(
              controller: _feedbackCtrl,
              decoration: InputDecoration(
                hintText: s.adminViewingReportFeedbackHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _fieldLabel(s.adminViewingReportWantsLabel, required: true),
            TextField(
              controller: _wantsCtrl,
              decoration: InputDecoration(
                hintText: s.adminViewingReportWantsHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _fieldLabel(
              s.adminViewingReportNotesLabel,
              required: _isNoShow(s),
            ),
            if (_isNoShow(s))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  s.adminViewingReportNeedNoShowNote,
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                ),
              ),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: _isNoShow(s)
                    ? s.adminViewingReportNoShowNotesHint
                    : s.adminViewingReportNotesHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            if (!_isNoShow(s)) ...[
            _fieldLabel(s.adminViewingReportNextStepLabel),
            SegmentedButton<ViewingFollowUpDecision>(
              segments: [
                ButtonSegment(
                  value: ViewingFollowUpDecision.continueFollow,
                  label: Text(s.adminViewingFollowUpContinue),
                  icon: const Icon(Icons.loop_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ViewingFollowUpDecision.closeCase,
                  label: Text(s.adminViewingFollowUpClose),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                ),
              ],
              selected: {_decision},
              onSelectionChanged: (v) => setState(() => _decision = v.first),
            ),
            if (_decision == ViewingFollowUpDecision.continueFollow) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(s.adminViewingFollowUpIntentConsider),
                    selected: _intent == ViewingFollowUpIntent.consider,
                    onSelected: (_) =>
                        setState(() => _intent = ViewingFollowUpIntent.consider),
                  ),
                  ChoiceChip(
                    label: Text(s.adminViewingFollowUpIntentFindMore),
                    selected: _intent == ViewingFollowUpIntent.findMore,
                    onSelected: (_) =>
                        setState(() => _intent = ViewingFollowUpIntent.findMore),
                  ),
                  ChoiceChip(
                    label: Text(s.adminViewingFollowUpIntentBoth),
                    selected: _intent == ViewingFollowUpIntent.both,
                    onSelected: (_) =>
                        setState(() => _intent = ViewingFollowUpIntent.both),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.adminViewingReportChatHintContinue,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                s.adminViewingReportAdminOnlyHint,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
            ] else ...[
              const SizedBox(height: 8),
              Text(
                s.adminCalendarNoShowBadge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: Icon(
                _isNoShow(s) || _decision == ViewingFollowUpDecision.closeCase
                    ? Icons.save_outlined
                    : Icons.send_outlined,
              ),
              label: Text(
                _isNoShow(s) || _decision == ViewingFollowUpDecision.closeCase
                    ? s.adminViewingReportSubmitClose
                    : s.adminViewingReportSubmitContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        required ? '$text *' : text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
