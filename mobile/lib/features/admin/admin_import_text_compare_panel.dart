import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// Before (ต้นทาง) → After (ร่าง RealXtate)
class AdminImportTextComparePanel extends StatelessWidget {
  const AdminImportTextComparePanel({
    super.key,
    required this.beforeController,
    required this.afterController,
    required this.onRegenerateAi,
    this.busy = false,
    this.aiSource,
  });

  final TextEditingController beforeController;
  final TextEditingController afterController;
  final VoidCallback onRegenerateAi;
  final bool busy;
  final String? aiSource;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdminTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.adminImportBeforeAfterTitle,
                  style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (aiSource != null)
                Chip(
                  label: Text(
                    aiSource == 'openai' ? 'AI' : s.adminImportAiRules,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.adminImportBeforeLabel, style: AdminTheme.caption),
          const SizedBox(height: 4),
          TextField(
            controller: beforeController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: s.adminImportBeforeHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(s.adminImportAfterLabel, style: AdminTheme.caption),
          const SizedBox(height: 4),
          TextField(
            controller: afterController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: s.adminImportAfterHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onRegenerateAi,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary),
              label: Text(s.adminImportRegenerateAi),
            ),
          ),
        ],
      ),
    );
  }
}
