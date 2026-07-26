import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_import_meta.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// ข้อมูลติดต่อจากต้นทาง — เฉพาะแอดมิน (ไม่เผยแพร่)
class AdminImportContactPanel extends StatelessWidget {
  const AdminImportContactPanel({
    super.key,
    required this.contact,
  });

  final ImportContactPrivate contact;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminImportCopied)),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AdminTheme.caption),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
          IconButton(
            tooltip: context.s.adminImportCopy,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copy(context, value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.adminImportContactSection,
            style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(s.adminImportContactHint, style: AdminTheme.caption),
          const SizedBox(height: 8),
          for (final p in contact.phones)
            _row(context, s.adminImportContactPhone, p),
          for (final l in contact.lines)
            _row(context, s.adminImportContactLine, l),
          if (contact.phones.isEmpty && contact.lines.isEmpty)
            Text(s.adminImportContactEmpty, style: AdminTheme.caption),
        ],
      ),
    );
  }
}
