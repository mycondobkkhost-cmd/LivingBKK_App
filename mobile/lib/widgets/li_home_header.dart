import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../state/locale_controller.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'language_switch_button.dart';
import 'living_bkk_logo.dart';
import 'perspective_selector_row.dart';

/// หัวหน้าแรก — LivingBKK branding
class LiHomeHeader extends StatelessWidget {
  const LiHomeHeader({
    super.key,
    required this.localeController,
    required this.roleController,
    this.onOpenProfile,
  });

  final LocaleController localeController;
  final UserRoleController roleController;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
        boxShadow: [AppTheme.cardShadowFor(p)],
      ),
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        10,
        LiLayout.pagePadding,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ListenableBuilder(
                    listenable: localeController,
                    builder: (context, _) => LivingBkkLogo(
                      size: LivingBkkLogoSize.sm,
                      showTagline: false,
                      isEnglish: localeController.isEnglish,
                    ),
                  ),
                ),
              ),
              LanguageSwitchButton(controller: localeController),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.notifications_outlined, size: 21),
                onPressed: () {},
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.person_outline, size: 21),
                onPressed: () {
                  if (onOpenProfile != null) {
                    onOpenProfile!();
                  } else {
                    context.push('/login');
                  }
                },
                tooltip: s.navProfile,
              ),
            ],
          ),
          PerspectiveSelectorRow(
            controller: roleController,
            localeController: localeController,
          ),
        ],
      ),
    );
  }
}

/// แท็บ เช่า | ซื้อ — สีแยก
class LiTransactionTabs extends StatelessWidget {
  const LiTransactionTabs({
    super.key,
    required this.selectedRent,
    required this.onRent,
    required this.onSale,
  });

  final bool selectedRent;
  final VoidCallback onRent;
  final VoidCallback onSale;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LiLayout.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: _tab(
              s.rent,
              selectedRent,
              onRent,
              active: AppTheme.accentDeep,
              activeBg: AppTheme.accentDeepLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tab(
              s.homeSaleIncludesInstallment,
              !selectedRent,
              onSale,
              active: AppTheme.accentMid,
              activeBg: AppTheme.accentMidLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String label,
    bool selected,
    VoidCallback onTap, {
    required Color active,
    required Color activeBg,
  }) {
    return Material(
      color: selected ? activeBg : LiLayout.tabInactiveBg,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          height: LiLayout.txnTabHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? active.withOpacity(0.45) : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: selected ? active : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// แถบผลลัพธ์: จำนวน · แผนที่/รายการ · ตัวกรอง
class LiResultsToolbar extends StatelessWidget {
  const LiResultsToolbar({
    super.key,
    required this.count,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onFilter,
    this.extra,
  });

  final int count;
  final HomeViewModeLi viewMode;
  final ValueChanged<HomeViewModeLi> onViewModeChanged;
  final VoidCallback onFilter;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 10, LiLayout.pagePadding, 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: LiLayout.divider)),
      ),
      child: Row(
        children: [
          Text(
            s.t('พบ $count ประกาศ', '$count listings'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          if (extra != null) ...[const SizedBox(width: 8), extra!],
          const Spacer(),
          _iconToggle(
            context,
            Icons.view_list,
            viewMode == HomeViewModeLi.list,
            () => onViewModeChanged(HomeViewModeLi.list),
          ),
          const SizedBox(width: 4),
          _iconToggle(
            context,
            Icons.map_outlined,
            viewMode == HomeViewModeLi.map,
            () => onViewModeChanged(HomeViewModeLi.map),
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onFilter,
            icon: const Icon(Icons.tune, size: 18),
            label: Text(s.t('ตัวกรอง', 'Filters'), style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconToggle(BuildContext context, IconData icon, bool selected, VoidCallback onTap) {
    final p = context.palette;
    return Material(
      color: selected ? p.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: selected ? p.primary : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

enum HomeViewModeLi { list, map }
