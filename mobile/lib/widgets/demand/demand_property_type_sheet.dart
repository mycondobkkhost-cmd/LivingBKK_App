import 'package:flutter/material.dart';

import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_palette.dart';
import '../../theme/li_layout.dart';

/// เลือกประเภททรัพย์บนบอร์ด — ครบทุกหมวดเหมือนหน้าแรก
abstract final class DemandPropertyTypeSheet {
  static Future<String?> show(
    BuildContext context, {
    String? selectedSlug,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _Sheet(selectedSlug: selectedSlug),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({this.selectedSlug});

  final String? selectedSlug;

  IconData _iconFor(String slug) => switch (slug) {
        'condo' => Icons.apartment_rounded,
        'house' => Icons.home_rounded,
        'townhome' => Icons.other_houses_rounded,
        'apartment' => Icons.domain_rounded,
        'land' => Icons.landscape_rounded,
        'commercial' => Icons.storefront_rounded,
        'office' => Icons.business_rounded,
        'home_office' => Icons.home_work_outlined,
        'warehouse' => Icons.warehouse_outlined,
        'factory' => Icons.factory_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              LiLayout.pagePadding,
              0,
              LiLayout.pagePadding,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            children: [
              Text(
                s.demandFilterPropertyType,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.demandFilterAll),
                trailing: selectedSlug == null
                    ? Icon(Icons.check, color: p.primary)
                    : null,
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(height: 1),
              ...PropertyCatalog.categories.map((cat) {
                final selected = selectedSlug == cat.slug;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  leading: Icon(_iconFor(cat.slug), color: p.primary),
                  title: Text(cat.label(s.isEnglish)),
                  trailing: selected
                      ? Icon(Icons.check, color: p.primary)
                      : null,
                  onTap: () => Navigator.pop(context, cat.slug),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
