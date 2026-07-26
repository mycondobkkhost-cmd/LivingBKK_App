import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_import_meta.dart';
import '../../theme/admin_theme.dart';

/// รูปหลักฐานแคปจาก FB (ไม่ใช่รูปประกาศ)
class AdminImportEvidenceGallery extends StatelessWidget {
  const AdminImportEvidenceGallery({
    super.key,
    required this.images,
  });

  final List<ImportEvidenceImage> images;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdminTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.adminImportEvidenceSection(images.length),
            style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(s.adminImportEvidenceHint, style: AdminTheme.caption),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final img = images[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      img.publicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: AdminTheme.border.withOpacity(0.3),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
