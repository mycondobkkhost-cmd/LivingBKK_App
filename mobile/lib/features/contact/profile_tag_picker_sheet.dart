import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/profile_tag.dart';
import '../../services/profile_tag_service.dart';
import '../../theme/app_theme.dart';
import 'profile_tag_form_sheet.dart';

/// เลือกแท็กเดิม · แก้ไข (สร้างแท็กใหม่) · สร้างใหม่
Future<ProfileTag?> showProfileTagPickerSheet(
  BuildContext context, {
  required ProfileTagRole role,
  required String title,
}) async {
  final tags = ProfileTagService.instance.tagsForUser(role: role);
  if (tags.isEmpty) {
    return showProfileTagFormSheet(context, role: role);
  }

  return showModalBottomSheet<ProfileTag>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _PickerBody(role: role, title: title, tags: tags),
  );
}

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.role,
    required this.title,
    required this.tags,
  });

  final ProfileTagRole role;
  final String title;
  final List<ProfileTag> tags;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(s.profileTagPickerHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ...tags.take(6).map(
            (t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(t.displayLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  t.snapshot['nickname'] ?? t.snapshot['displayName'] ?? t.code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                trailing: FilledButton(
                  onPressed: () => Navigator.pop(context, t),
                  child: Text(s.profileTagUse),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final latest = tags.first;
              final edited = await showProfileTagFormSheet(
                context,
                role: role,
                basedOn: latest,
              );
              if (context.mounted && edited != null) {
                Navigator.pop(context, edited);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(s.profileTagEditNewVersion),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final created = await showProfileTagFormSheet(context, role: role);
              if (context.mounted && created != null) {
                Navigator.pop(context, created);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(s.profileTagCreateNew),
          ),
        ],
      ),
    );
  }
}
