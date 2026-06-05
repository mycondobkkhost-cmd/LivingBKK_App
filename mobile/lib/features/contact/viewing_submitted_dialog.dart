import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reference_code_chip.dart';

Future<void> showViewingSubmittedDialog(
  BuildContext context, {
  required Map<String, String> profileSummary,
  bool savedToDatabase = true,
  bool duplicatePhoneSuffix = false,
  String? chatRef,
  String? leadRef,
}) {
  final s = AppStrings.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.check_circle, color: AppTheme.primary, size: 56),
      title: Text(
        s.viewingRequestReceived,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.viewingFollowUpNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            if (chatRef != null && chatRef.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReferenceCodeChip(
                code: chatRef,
                label: s.transactionRefLabel,
              ),
              if (leadRef != null && leadRef.isNotEmpty) ...[
                const SizedBox(height: 6),
                ReferenceCodeChip(
                  code: leadRef,
                  label: 'Lead',
                ),
              ],
              const SizedBox(height: 4),
              Text(
                s.viewingRefHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
            if (!savedToDatabase) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentMidLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  s.viewingSavedChatOnly,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
            if (duplicatePhoneSuffix) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmberLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentMid.withOpacity(0.4)),
                ),
                child: Text(
                  s.viewingDuplicatePhone,
                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              s.viewingSummaryTitle,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...profileSummary.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppTheme.textPrimary, height: 1.35),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: e.value),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.ok),
        ),
      ],
    ),
  );
}
