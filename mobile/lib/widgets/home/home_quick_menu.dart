import 'package:flutter/material.dart';

import '../../config/demand_board_menu_config.dart';
import '../../config/post_listing_menu_config.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/listing_navigation.dart';
import '../property_type_more_sheet.dart';

/// เมนูด่วน — ลงประกาศฟรี + 3 บริการ pill + ประเภททรัพย์
class HomeQuickMenu extends StatelessWidget {
  const HomeQuickMenu({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.isAgent,
    this.onMapSearch,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final bool isAgent;
  final VoidCallback? onMapSearch;

  static const _propertyIconSize = 44.0;
  static const _propertySlugs = ['condo', 'house', 'townhome', 'home_office'];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final showPost = PostListingMenuConfig.showHomeQuickPost(roleController);
    final services = _buildServiceItems(context, s, p);
    final properties = _buildPropertyItems(context, s, p);

    if (!showPost && services.isEmpty && properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPost) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PostListingCta(
                title: s.homeQuickOwnerTitle,
                subtitle: s.homeQuickOwnerBody,
                onTap: () => PostListingNavigation.openCreateWithAuthGate(context),
              ),
            ),
            if (services.isNotEmpty) const SizedBox(height: 6),
          ],
          if (services.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < services.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _ServicePillCta(data: services[i])),
                  ],
                ],
              ),
            ),
          if (properties.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 68,
                child: Row(
                  children: [
                    for (final item in properties)
                      Expanded(
                        child: _QuickIcon(
                          data: item,
                          iconSize: _propertyIconSize,
                          palette: p,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_ServicePillData> _buildServiceItems(
    BuildContext context,
    AppStrings s,
    AppPalette p,
  ) {
    final out = <_ServicePillData>[
      _ServicePillData(
        line1: s.homeQuickServiceMapLine1,
        line2: s.homeQuickServiceMapLine2,
        imageAsset: 'assets/home_services/home_service_map.png',
        accentColor: LivingBkkBrand.purpleMid,
        gradientColors: const [Color(0xFF6B4EAA), Color(0xFF8B6FD4)],
        onTap: onMapSearch,
      ),
    ];

    if (DemandBoardMenuConfig.showHomeQuickRequirement(roleController)) {
      out.add(_ServicePillData(
        line1: s.homeQuickServiceMatchLine1,
        line2: s.homeQuickServiceMatchLine2,
        imageAsset: 'assets/home_services/home_service_match.png',
        accentColor: const Color(0xFF0D9488),
        gradientColors: const [Color(0xFF0F9B8E), Color(0xFF2DD4BF)],
        onTap: () => DemandBoardNavigation.openCreateRequirement(context),
      ));
    }

    if (DemandBoardMenuConfig.showHomeQuickBoard(roleController)) {
      out.add(_ServicePillData(
        line1: s.homeQuickServiceBoardLine1,
        line2: s.homeQuickServiceBoardLine2,
        imageAsset: 'assets/home_services/home_service_board.png',
        accentColor: LivingBkkBrand.piterOrange,
        gradientColors: const [Color(0xFFE85A00), Color(0xFFFF9A4D)],
        onTap: () => DemandBoardNavigation.openBoardTab(context),
      ));
    }

    return out;
  }

  List<_QuickItem> _buildPropertyItems(
    BuildContext context,
    AppStrings s,
    AppPalette p,
  ) {
    final out = <_QuickItem>[];

    for (final slug in _propertySlugs) {
      final cat = PropertyCatalog.bySlug(slug);
      if (cat == null) continue;
      out.add(_QuickItem(
        label: cat.label(s.isEnglish),
        icon: _propertyIcon(slug),
        tint: _propertyTint(slug, p),
        onTap: () => ListingNavigation.openCategory(context, slug: slug, isAgent: isAgent),
      ));
    }

    out.add(_QuickItem(
      label: s.homePropertyOthers,
      icon: Icons.grid_view_rounded,
      tint: p.textSecondary,
      onTap: () {
        PropertyTypeMoreSheet.show(
          context,
          searchSession: searchSession,
          onCategoryPicked: (picked) {
            Navigator.of(context).pop();
            ListingNavigation.openCategory(context, slug: picked, isAgent: isAgent);
          },
        );
      },
    ));

    return out;
  }

  static IconData _propertyIcon(String slug) => switch (slug) {
        'condo' => Icons.apartment_rounded,
        'house' => Icons.home_rounded,
        'townhome' => Icons.other_houses_rounded,
        'home_office' => Icons.home_work_rounded,
        _ => Icons.category_rounded,
      };

  static Color _propertyTint(String slug, AppPalette p) => switch (slug) {
        'condo' => p.primary,
        'house' => const Color(0xFF4DA8FF),
        'townhome' => const Color(0xFFF59E0B),
        'home_office' => const Color(0xFF6366F1),
        _ => p.textSecondary,
      };
}

class _ServicePillData {
  const _ServicePillData({
    required this.line1,
    required this.line2,
    required this.imageAsset,
    required this.accentColor,
    required this.gradientColors,
    this.onTap,
  });

  final String line1;
  final String line2;
  final String imageAsset;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  String get semanticsLabel => '$line1 $line2';
}

class _QuickItem {
  const _QuickItem({
    required this.label,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
}

/// ปุ่มลงประกาศ — แยกจากแถวบริการด้านล่าง
class _PostListingCta extends StatelessWidget {
  const _PostListingCta({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const double _height = 52;
  static const double _iconSize = 34;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_height / 2),
        child: Ink(
          height: _height,
          decoration: BoxDecoration(
            gradient: LivingBkkBrand.ctaGradient,
            borderRadius: BorderRadius.circular(_height / 2),
            boxShadow: [
              BoxShadow(
                color: LivingBkkBrand.piterOrange.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_home_work_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.05,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มบริการ 3 อัน — รูปเต็มการ์ด + ข้อความขาวทับพื้นที่ว่างซ้าย (ไม่ทาสีทับรูป)
class _ServicePillCta extends StatelessWidget {
  const _ServicePillCta({required this.data});

  final _ServicePillData data;

  static const double _height = 60;
  static const double _radius = 14;

  /// พื้นที่ว่างซ้ายของรูปสำหรับวางข้อความ (สัดส่วนตรงกับ asset)
  static const double _textAreaWidthFraction = 0.58;

  /// ขนาดตัวหนังสือเท่ากันทุกการ์ด — 2 บรรทัด อ่านง่าย
  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.28,
    letterSpacing: -0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Semantics(
          button: true,
          label: data.semanticsLabel,
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                BoxShadow(
                  color: data.accentColor.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textWidth =
                      constraints.maxWidth * _textAreaWidthFraction;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        data.imageAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: _height,
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: data.gradientColors,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              data.semanticsLabel,
                              textAlign: TextAlign.center,
                              style: _labelStyle,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 9,
                        top: 5,
                        bottom: 5,
                        width: textWidth - 9,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.line1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _labelStyle,
                              ),
                              Text(
                                data.line2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _labelStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickIcon extends StatelessWidget {
  const _QuickIcon({
    required this.data,
    required this.iconSize,
    required this.palette,
  });

  final _QuickItem data;
  final double iconSize;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: data.tint.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.tint.withOpacity(0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: data.tint.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 23, color: data.tint),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.12,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
