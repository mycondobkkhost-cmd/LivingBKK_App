import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class OwnerViewingDeclineResult {
  const OwnerViewingDeclineResult({this.note});

  final String? note;
}

Future<OwnerViewingDeclineResult?> showOwnerViewingDeclineSheet(
  BuildContext context, {
  required String viewingCode,
}) {
  return showModalBottomSheet<OwnerViewingDeclineResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _OwnerViewingDeclineBody(viewingCode: viewingCode),
  );
}

class _OwnerViewingDeclineBody extends StatefulWidget {
  const _OwnerViewingDeclineBody({required this.viewingCode});

  final String viewingCode;

  @override
  State<_OwnerViewingDeclineBody> createState() => _OwnerViewingDeclineBodyState();
}

class _OwnerViewingDeclineBodyState extends State<_OwnerViewingDeclineBody> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.ownerHubDeclineTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.ownerHubDeclineSubtitle(widget.viewingCode),
            style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: s.ownerViewingNoteLabel,
              hintText: s.ownerHubDeclineNoteHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final note = _noteCtrl.text.trim();
              Navigator.pop(
                context,
                OwnerViewingDeclineResult(
                  note: note.isEmpty ? null : note,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(s.ownerHubDeclineSubmit),
          ),
        ],
      ),
    );
  }
}
