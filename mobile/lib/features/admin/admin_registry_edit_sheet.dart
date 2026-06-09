import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/vault_asset.dart';
import '../../services/auth_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../theme/admin_theme.dart';
import 'admin_listing_public_preview_sheet.dart';

/// แก้ไขข้อมูลสาธารณะในคลัง — ไม่ต้องกลับไปแท็บนำเข้า
Future<bool?> showRegistryEditSheet({
  required BuildContext context,
  required VaultAssetSummary summary,
  String? initialTitle,
  String? initialDescription,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _RegistryEditBody(
        summary: summary,
        initialTitle: initialTitle ?? summary.titlePreview ?? '',
        initialDescription: initialDescription ?? '',
      ),
    ),
  );
}

class _RegistryEditBody extends StatefulWidget {
  const _RegistryEditBody({
    required this.summary,
    required this.initialTitle,
    required this.initialDescription,
  });

  final VaultAssetSummary summary;
  final String initialTitle;
  final String initialDescription;

  @override
  State<_RegistryEditBody> createState() => _RegistryEditBodyState();
}

class _RegistryEditBodyState extends State<_RegistryEditBody> {
  final _ops = RegistryAssetOpsService.instance;
  late final TextEditingController _title;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _desc = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  String? get _listingId =>
      widget.summary.listingId ??
      (widget.summary.entityType == 'listing' ? widget.summary.entityId : null);

  Future<void> _preview() async {
    final listingId = _listingId;
    if (listingId == null) return;
    await showAdminListingPublicPreview(
      context: context,
      listingId: listingId,
      titleOverride: _title.text.trim(),
      descriptionOverride: _desc.text.trim(),
    );
  }

  void _save() {
    final s = context.s;
    final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
    _ops.saveEdits(
      entityType: widget.summary.entityType,
      entityId: widget.summary.entityId,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      actor: actor,
      previousTitle: widget.initialTitle,
      previousDescription: widget.initialDescription,
    );
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRegistryEditSaved)),
    );
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
          Text(s.adminRegistryEditTitle, style: AdminTheme.title.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            widget.summary.displayCode,
            style: AdminTheme.caption.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: s.adminRegistryColTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: s.adminRegistryEditDescription,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _listingId == null ? null : _preview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(s.adminListingPreview),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(s.adminRegistrySave)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        ],
      ),
    );
  }
}
