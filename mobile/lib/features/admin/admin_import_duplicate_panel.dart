import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_import_meta.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';

/// แผงจัดการรายการซ้ำ — เปิดของเดิม / คลัง / ล้าง / เผยแพร่ต่อ
class AdminImportDuplicatePanel extends StatelessWidget {
  const AdminImportDuplicatePanel({
    super.key,
    required this.duplicateOf,
    required this.onOpenOriginalImport,
    required this.onContinuePublish,
    required this.onDiscard,
    this.busy = false,
  });

  final ImportDuplicateRef duplicateOf;
  final VoidCallback onOpenOriginalImport;
  final VoidCallback onContinuePublish;
  final VoidCallback onDiscard;
  final bool busy;

  Future<void> _openSourceUrl(BuildContext context) async {
    final url = duplicateOf.sourceUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ref = duplicateOf;
    final hasListing = ref.listingId != null && ref.listingId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdminTheme.card(alert: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.adminImportDuplicateTitle,
            style: AdminTheme.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 6),
          AdminHint(s.adminImportDuplicateHint),
          const SizedBox(height: 8),
          if (ref.titlePreview != null && ref.titlePreview!.isNotEmpty)
            Text(ref.titlePreview!, style: AdminTheme.body),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (ref.sourceExternalId != null)
                _Tag(label: 'LI #${ref.sourceExternalId}'),
              if (ref.listingCode != null && ref.listingCode!.isNotEmpty)
                ActionChip(
                  label: Text(ref.listingCode!),
                  onPressed: busy || !hasListing
                      ? null
                      : () => openAdminListing(
                            context,
                            listingId: ref.listingId,
                            listingCode: ref.listingCode,
                          ),
                ),
              _Tag(label: s.adminImportStatus(ref.status)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onContinuePublish,
                icon: const Icon(Icons.publish_outlined, size: 18),
                label: Text(s.adminImportContinuePublish),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onOpenOriginalImport,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(s.adminImportOpenOriginal),
              ),
              if (hasListing)
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => openAdminListing(
                            context,
                            listingId: ref.listingId,
                            listingCode: ref.listingCode,
                          ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(s.adminImportOpenInStock),
                ),
              if (ref.sourceUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _openSourceUrl(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(s.adminImportOpenSourceLink),
                ),
              TextButton.icon(
                onPressed: busy ? null : onDiscard,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(s.adminImportDiscardDuplicate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
