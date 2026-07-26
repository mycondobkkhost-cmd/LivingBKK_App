import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_import_meta.dart';
import '../../theme/admin_theme.dart';

/// รูปทรัพย์ใน draft — อัปโหลด/ลบได้
class AdminImportListingPhotosPanel extends StatelessWidget {
  const AdminImportListingPhotosPanel({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onDelete,
    this.busy = false,
  });

  final List<ImportListingImage> images;
  final VoidCallback onAdd;
  final void Function(String imageId) onDelete;
  final bool busy;

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
                  s.adminImportImagesSection(images.length),
                  style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : onAdd,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(s.adminImportAddListingPhotos),
              ),
            ],
          ),
          if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(s.adminImportListingPhotosEmpty, style: AdminTheme.caption),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final img = images[i];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            img.publicUrl,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: AdminTheme.border.withOpacity(0.3),
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: busy ? null : () => onDelete(img.id),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
