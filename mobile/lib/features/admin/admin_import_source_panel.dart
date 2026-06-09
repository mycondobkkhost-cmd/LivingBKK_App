import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_import_meta.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// แสดงข้อมูลต้นทางจาก Facebook / OG ที่เก็บไว้ตอนดึง
class AdminImportSourcePanel extends StatelessWidget {
  const AdminImportSourcePanel({
    super.key,
    required this.platform,
    required this.sourceMeta,
    this.imageCount = 0,
  });

  final String platform;
  final ImportSourceMeta sourceMeta;
  final int imageCount;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final meta = sourceMeta;
    final isFacebook = platform == 'facebook';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdminTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isFacebook ? s.adminImportFacebookSection : s.adminImportSourceMetaSection,
            style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (meta.posterName != null || meta.posterUrl != null) ...[
            Text(s.adminImportFacebookPoster, style: AdminTheme.caption),
            const SizedBox(height: 4),
            InkWell(
              onTap: meta.posterUrl != null
                  ? () => _openUrl(context, meta.posterUrl!)
                  : null,
              child: Text(
                meta.posterName ?? meta.posterUrl!,
                style: TextStyle(
                  color: meta.posterUrl != null ? AppTheme.primary : null,
                  decoration: meta.posterUrl != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (meta.postUrl != null && meta.postUrl!.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => _openUrl(context, meta.postUrl!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.adminImportOpenPostLink),
            ),
            const SizedBox(height: 8),
          ],
          if (meta.postText != null && meta.postText!.isNotEmpty) ...[
            Text(s.adminImportFacebookPost, style: AdminTheme.caption),
            const SizedBox(height: 4),
            SelectableText(
              meta.postText!,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 8),
          ],
          if (meta.postLinks.isNotEmpty) ...[
            Text(s.adminImportFacebookLinks, style: AdminTheme.caption),
            const SizedBox(height: 4),
            ...meta.postLinks.take(8).map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => _openUrl(context, link),
                      child: Text(
                        link,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
          ],
          if (imageCount > 0) ...[
            const SizedBox(height: 6),
            Text(s.adminImportImages(imageCount), style: AdminTheme.caption),
          ],
        ],
      ),
    );
  }
}
