import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/profile_tag.dart';
import '../../services/profile_tag_repository.dart';
import '../../theme/app_theme.dart';

/// เลือกแท็กเพื่อแทรก @mention ในแชทแอดมิน
Future<String?> showTagMentionPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _TagMentionPickerSheet(),
  );
}

class _TagMentionPickerSheet extends StatefulWidget {
  const _TagMentionPickerSheet();

  @override
  State<_TagMentionPickerSheet> createState() => _TagMentionPickerSheetState();
}

class _TagMentionPickerSheetState extends State<_TagMentionPickerSheet> {
  final _query = TextEditingController();
  List<ProfileTag> _tags = [];

  @override
  void initState() {
    super.initState();
    ProfileTagRepository.instance.ensureLoaded().then((_) => _search(''));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      _tags = ProfileTagRepository.instance.searchGlobal(q).take(30).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.adminTagMentionPickerTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            decoration: InputDecoration(
              hintText: s.adminTagMentionPickerHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tags.length,
              itemBuilder: (context, i) {
                final tag = _tags[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    tag.code,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(tag.subjectDisplayName ?? tag.role.name),
                  onTap: () => Navigator.pop(context, '@${tag.code}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
