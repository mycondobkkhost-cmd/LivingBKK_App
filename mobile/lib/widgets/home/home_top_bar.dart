import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/search_filters.dart';
import '../../shell/main_shell_scope.dart';
import '../../state/locale_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../notification_bell_button.dart';
import '../perspective_dropdown_chip.dart';
import '../smart_search_bar.dart';

/// หัวหน้าแรก — gradient PROP Navy → PITER Pink → fade ขาว
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.roleController,
    required this.localeController,
    required this.onOpenSearch,
    required this.onOpenNotifications,
    required this.filters,
    this.onFiltersChanged,
    this.onMapSearch,
    this.onOpenProject,
    this.onOpenFilters,
  });

  final UserRoleController roleController;
  final LocaleController localeController;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;
  final SearchFilters filters;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback? onMapSearch;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hasActive = filters.hasActiveFilters;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LivingBkkBrand.homeHeaderGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PerspectiveDropdownChip(
                    controller: roleController,
                    localeController: localeController,
                    onPurpleHeader: true,
                    compact: true,
                    mini: true,
                  ),
                  const Spacer(),
                  _headerIcon(
                    icon: Icons.favorite_border_rounded,
                    onTap: () => MainShellScope.maybeOf(context)?.selectTab(1),
                  ),
                  const SizedBox(width: 6),
                  NotificationBellButton(
                    compact: true,
                    onPressed: onOpenNotifications,
                    onPurple: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.white,
                elevation: 0,
                shadowColor: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: onOpenSearch,
                  borderRadius: BorderRadius.circular(28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IgnorePointer(
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: SmartSearchBar(
                            filters: filters,
                            onFiltersChanged: onFiltersChanged ?? (_) {},
                            style: SearchBarStyle.airbnb,
                            dense: true,
                            onMapSearch: onMapSearch,
                            onOpenProject: onOpenProject,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onOpenFilters != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.white.withOpacity(0.92),
                    ),
                    onPressed: onOpenFilters,
                    icon: Icon(
                      Icons.tune,
                      size: 16,
                      color: hasActive ? Colors.white : Colors.white70,
                    ),
                    label: Text(
                      hasActive ? s.filtersActive : s.advancedFilters,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
