import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/participant_profile_data.dart';
import '../../models/profile_tag.dart';
import '../../theme/app_theme.dart';
import '../contact/profile_tag_picker_sheet.dart';

/// เลือกว่าเป็นลูกค้าเอง / โคเอ + เลือกแท็กลูกค้า (CL) และผู้พานัด (PR)
class IntakeWhoSection extends StatelessWidget {
  const IntakeWhoSection({
    super.key,
    required this.profile,
    required this.allowCoAgent,
    required this.onChanged,
    this.clientTag,
    this.presenterTag,
    required this.onClientTagChanged,
    required this.onPresenterTagChanged,
  });

  final ParticipantProfileData profile;
  final bool allowCoAgent;
  final VoidCallback onChanged;
  final ProfileTag? clientTag;
  final ProfileTag? presenterTag;
  final ValueChanged<ProfileTag?> onClientTagChanged;
  final ValueChanged<ProfileTag?> onPresenterTagChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: profile.applicantType,
          decoration: InputDecoration(
            labelText: s.whoAreYouRequired,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'seeker_self', child: Text(s.customerRole)),
            if (allowCoAgent)
              DropdownMenuItem(
                value: 'co_agent_request',
                child: Text(s.coAgentRole),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            profile.applicantType = v;
            if (v != 'co_agent_request') profile.customerPhoneLast4 = '';
            onChanged();
          },
        ),
        if (profile.isCoAgent) ...[
          const SizedBox(height: 12),
          Text(
            s.t('ลูกค้าที่พานัด (เลือกหรือสร้างใหม่)', 'Client to view (pick or create)'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          _TagChip(
            label: clientTag?.displayLabel ??
                s.t('ยังไม่เลือกลูกค้า', 'No client selected'),
            code: clientTag?.code,
            onTap: () async {
              final tag = await showProfileTagPickerSheet(
                context,
                role: ProfileTagRole.clientSubject,
                title: s.profileTagPickerClient,
              );
              if (tag != null) onClientTagChanged(tag);
            },
          ),
          const SizedBox(height: 10),
          Text(
            s.t('ผู้พานัด / โคเอ (ตัวคุณ)', 'Presenter / co-agent (you)'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _TagChip(
            label: presenterTag?.displayLabel ??
                (profile.presenterDisplayName.trim().isNotEmpty
                    ? profile.presenterDisplayName
                    : s.t('เลือกโปรไฟล์ผู้พานัด', 'Pick presenter profile')),
            code: presenterTag?.code,
            onTap: () async {
              final tag = await showProfileTagPickerSheet(
                context,
                role: ProfileTagRole.coAgentPresenter,
                title: s.profileTagPickerPresenter,
              );
              if (tag != null) onPresenterTagChanged(tag);
            },
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.code,
    required this.onTap,
  });

  final String label;
  final String? code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (code != null)
                      Text(
                        code!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
