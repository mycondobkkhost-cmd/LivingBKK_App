import 'package:flutter/material.dart';

import '../data/property_catalog.dart';
import '../l10n/app_strings.dart';
import '../state/search_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/li_layout.dart';

/// หมวดทรัพย์เพิ่มเติม — แสดงเมื่อกด 「อื่นๆ」 บนหน้าแรก
abstract final class PropertyTypeMoreSheet {
  static const moreSlugs = [
    'apartment',
    'commercial',
    'office',
    'home_office',
    'warehouse',
  ];

  static List<PropertyCategory> get categories => [
        for (final slug in moreSlugs)
          if (PropertyCatalog.bySlug(slug) != null) PropertyCatalog.bySlug(slug)!,
      ];

  static bool isMoreSlug(String? slug) =>
      slug != null && moreSlugs.contains(slug);

  static Future<void> show(
    BuildContext context, {
    required SearchSessionController searchSession,
    void Function(String slug)? onCategoryPicked,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyTypeMoreSheetBody(
        searchSession: searchSession,
        selectedSlug: searchSession.categorySlug,
        onSelect: (slug) {
          if (onCategoryPicked != null) {
            onCategoryPicked(slug);
            return;
          }
          final current = searchSession.categorySlug;
          searchSession.setCategorySlug(current == slug ? null : slug);
        },
      ),
    );
  }

  /// เลือกประเภททรัพย์ (ฟอร์มความต้องการ ฯลฯ)
  static Future<void> showPicker(
    BuildContext context, {
    required String? selectedSlug,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyTypeMoreSheetBody(
        selectedSlug: selectedSlug,
        onSelect: (slug) {
          onSelect(slug);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  /// เลือกประเภททรัพย์เพิ่มเติมได้หลายรายการ
  static Future<void> showMultiPicker(
    BuildContext context, {
    required Set<String> selectedSlugs,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyTypeMultiPickerSheet(
        initial: Set<String>.from(selectedSlugs),
        onDone: (slugs) {
          onChanged(slugs);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _PropertyTypeMoreSheetBody extends StatelessWidget {
  const _PropertyTypeMoreSheetBody({
    this.searchSession,
    this.selectedSlug,
    required this.onSelect,
  });

  final SearchSessionController? searchSession;
  final String? selectedSlug;
  final ValueChanged<String> onSelect;

  IconData _iconFor(String slug) => switch (slug) {
        'apartment' => Icons.domain_rounded,
        'commercial' => Icons.storefront_rounded,
        'office' => Icons.business_rounded,
        'home_office' => Icons.home_work_outlined,
        'warehouse' => Icons.warehouse_outlined,
        _ => Icons.category_outlined,
      };

  Color _tintFor(String slug, AppPalette p) => switch (slug) {
        'apartment' => const Color(0xFF6366F1),
        'commercial' => const Color(0xFF10B981),
        'office' => const Color(0xFF0EA5E9),
        'home_office' => const Color(0xFF8B5CF6),
        'warehouse' => const Color(0xFFF59E0B),
        _ => p.accent,
      };

  void _select(BuildContext context, String slug) {
    onSelect(slug);
    if (searchSession != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listenable = searchSession;
    if (listenable != null) {
      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => _body(context, listenable.categorySlug),
      );
    }
    return _body(context, selectedSlug);
  }

  Widget _body(BuildContext context, String? selected) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final items = PropertyTypeMoreSheet.categories;

    return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: LiLayout.pagePadding,
            right: LiLayout.pagePadding,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.propertyTypeSheetTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, color: p.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final cat = items[i];
                  final tint = _tintFor(cat.slug, p);
                  final isSelected = selected == cat.slug;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _select(context, cat.slug),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: tint.withOpacity(isSelected ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: tint, width: 2)
                                : null,
                          ),
                          child: Icon(_iconFor(cat.slug), color: tint, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.label(s.isEnglish),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            color: isSelected ? tint : p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }
}

class _PropertyTypeMultiPickerSheet extends StatefulWidget {
  const _PropertyTypeMultiPickerSheet({
    required this.initial,
    required this.onDone,
  });

  final Set<String> initial;
  final ValueChanged<Set<String>> onDone;

  @override
  State<_PropertyTypeMultiPickerSheet> createState() =>
      _PropertyTypeMultiPickerSheetState();
}

class _PropertyTypeMultiPickerSheetState extends State<_PropertyTypeMultiPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initial);
  }

  void _toggle(String slug) {
    setState(() {
      if (_selected.contains(slug)) {
        if (_selected.length > 1) _selected.remove(slug);
      } else {
        _selected.add(slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final items = PropertyTypeMoreSheet.categories;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: LiLayout.pagePadding,
        right: LiLayout.pagePadding,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.propertyTypeSheetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onDone(_selected),
                child: Text(s.t('เสร็จ', 'Done')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final cat = items[i];
              final isSelected = _selected.contains(cat.slug);
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggle(cat.slug),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: p.primary.withOpacity(isSelected ? 0.22 : 0.1),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: p.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.category_outlined,
                        color: p.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label(s.isEnglish),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: isSelected ? p.primary : p.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
