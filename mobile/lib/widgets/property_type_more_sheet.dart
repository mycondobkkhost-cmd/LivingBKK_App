import 'package:flutter/material.dart';

import '../data/property_catalog.dart';
import '../l10n/app_strings.dart';
import '../state/search_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/li_layout.dart';

/// หมวดทรัพย์ทั้งหมด — แสดงเมื่อกด 「อื่นๆ」 บนหน้าแรก
abstract final class PropertyTypeMoreSheet {
  static List<PropertyCategory> get categories => PropertyCatalog.categories;

  static bool isMoreSlug(String? slug) =>
      slug != null &&
      !PropertyCatalog.homePrimarySlugs.contains(slug) &&
      PropertyCatalog.bySlug(slug) != null;

  /// วงกลม + stroke สีเดียวกับชื่อหมวดด้านล่าง (แบบแถวหน้าแรก)
  static const categoryGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    mainAxisSpacing: 6,
    crossAxisSpacing: 4,
    childAspectRatio: 1.12,
  );

  static Widget iconCircle({
    required Color tint,
    required IconData icon,
    required bool selected,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withOpacity(selected ? 0.2 : 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: tint.withOpacity(selected ? 0.75 : 0.45),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Icon(icon, color: tint, size: iconSize),
    );
  }

  static IconData iconFor(String slug) => switch (slug) {
        'condo' => Icons.apartment_rounded,
        'house' => Icons.home_rounded,
        'land' => Icons.landscape_rounded,
        'townhome' => Icons.other_houses_rounded,
        'commercial' => Icons.storefront_rounded,
        'office' => Icons.business_rounded,
        'home_office' => Icons.home_work_outlined,
        'showroom' => Icons.directions_car_filled_outlined,
        'business' => Icons.stars_rounded,
        'factory' => Icons.factory_outlined,
        'warehouse' => Icons.warehouse_outlined,
        'co_working' => Icons.groups_outlined,
        'apartment' => Icons.domain_rounded,
        'pool_villa' => Icons.pool_outlined,
        _ => Icons.category_outlined,
      };

  static Color tintFor(String slug, AppPalette p) => switch (slug) {
        'condo' => p.primary,
        'house' => const Color(0xFF4DA8FF),
        'land' => const Color(0xFF10B981),
        'townhome' => const Color(0xFFF59E0B),
        'commercial' => const Color(0xFF10B981),
        'office' => const Color(0xFF0EA5E9),
        'home_office' => const Color(0xFF8B5CF6),
        'showroom' => const Color(0xFF3B82F6),
        'business' => const Color(0xFFEAB308),
        'factory' => const Color(0xFF64748B),
        'warehouse' => const Color(0xFFF59E0B),
        'co_working' => const Color(0xFF14B8A6),
        'apartment' => const Color(0xFF6366F1),
        'pool_villa' => const Color(0xFF06B6D4),
        _ => p.accent,
      };

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

    return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.36,
          maxChildSize: 0.82,
          builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: LiLayout.pagePadding,
            right: LiLayout.pagePadding,
            top: 6,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: ListView(
            controller: scrollController,
            shrinkWrap: true,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.close, size: 20, color: p.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: PropertyTypeMoreSheet.categoryGridDelegate,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final cat = items[i];
                  final tint = PropertyTypeMoreSheet.tintFor(cat.slug, p);
                  final isSelected = selected == cat.slug;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _select(context, cat.slug),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PropertyTypeMoreSheet.iconCircle(
                          tint: tint,
                          icon: PropertyTypeMoreSheet.iconFor(cat.slug),
                          selected: isSelected,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cat.label(s.isEnglish),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.36,
      maxChildSize: 0.82,
      builder: (context, scrollController) => Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: LiLayout.pagePadding,
        right: LiLayout.pagePadding,
        top: 6,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: ListView(
        controller: scrollController,
        shrinkWrap: true,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onDone(_selected),
                child: Text(s.t('เสร็จ', 'Done')),
              ),
            ],
          ),
          const SizedBox(height: 2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: PropertyTypeMoreSheet.categoryGridDelegate,
            itemCount: items.length,
            itemBuilder: (context, i) {
              final cat = items[i];
              final isSelected = _selected.contains(cat.slug);
              final tint = PropertyTypeMoreSheet.tintFor(cat.slug, p);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _toggle(cat.slug),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PropertyTypeMoreSheet.iconCircle(
                      tint: tint,
                      icon: PropertyTypeMoreSheet.iconFor(cat.slug),
                      selected: isSelected,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cat.label(s.isEnglish),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
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
    ),
    );
  }
}
