import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/search_filters.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../theme/li_layout.dart';
import 'design_system/app_button.dart';
import 'perspective_selector_row.dart';
import '../state/locale_controller.dart';
import '../state/user_role_controller.dart';
import 'language_switch_button.dart';

/// Hero search section — Airbnb-style heading + search card
class ExploreHeroSection extends StatelessWidget {
  const ExploreHeroSection({
    super.key,
    required this.localeController,
    required this.roleController,
    required this.filters,
    required this.onSearchTap,
    required this.onFilterTap,
    required this.onMapTap,
    this.onOpenProfile,
  });

  final LocaleController localeController;
  final UserRoleController roleController;
  final SearchFilters filters;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;
  final VoidCallback onMapTap;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 8, LiLayout.pagePadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.exploreHeroTitle,
                  style: AppTypography.heroHeadline(p),
                ),
              ),
              LanguageSwitchButton(controller: localeController),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.person_outline, color: p.textPrimary),
                onPressed: onOpenProfile,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.exploreHeroSubtitle,
            style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          AppCardSearchFields(
            filters: filters,
            onSearchTap: onSearchTap,
            onFilterTap: onFilterTap,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: s.exploreSearchCta,
                  onPressed: onSearchTap,
                  expand: true,
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: p.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: InkWell(
                  onTap: onMapTap,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(Icons.map_outlined, color: p.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PerspectiveSelectorRow(
            controller: roleController,
            localeController: localeController,
          ),
        ],
      ),
    );
  }
}

class AppCardSearchFields extends StatelessWidget {
  const AppCardSearchFields({
    super.key,
    required this.filters,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  final SearchFilters filters;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);

    final area = filters.geoZoneSlugs?.isNotEmpty == true
        ? filters.geoZoneSlugs!.join(', ')
        : s.exploreFieldArea;
    final budget = filters.minPrice != null || filters.maxPrice != null
        ? s.exploreBudgetSummary(filters.minPrice, filters.maxPrice)
        : s.exploreFieldBudget;
    final type = filters.propertyType ?? s.exploreFieldType;

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        onTap: onSearchTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            color: p.surface,
            border: Border.all(color: p.border),
            boxShadow: [AppTheme.cardShadowFor(p)],
          ),
          child: Column(
            children: [
              _row(context, Icons.location_on_outlined, s.exploreFieldAreaLabel, area),
              Divider(height: 1, color: p.divider),
              _row(context, Icons.payments_outlined, s.exploreFieldBudgetLabel, budget),
              Divider(height: 1, color: p.divider),
              _row(context, Icons.apartment_outlined, s.exploreFieldTypeLabel, type),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
