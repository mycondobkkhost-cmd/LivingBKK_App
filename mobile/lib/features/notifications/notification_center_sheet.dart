import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_notification.dart';
import '../../services/notification_center_repository.dart';
import '../../shell/main_shell_scope.dart';
import '../../state/locale_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';

/// ศูนย์แจ้งเตือน — bottom sheet แบบ LINE MAN (pill filter + การ์ด)
class NotificationCenterSheet extends StatefulWidget {
  const NotificationCenterSheet({
    super.key,
    required this.roleController,
    required this.localeController,
    this.initialFilter = AppNotificationFilter.all,
  });

  final UserRoleController roleController;
  final LocaleController localeController;
  final AppNotificationFilter initialFilter;

  static Future<void> show(
    BuildContext context, {
    required UserRoleController roleController,
    required LocaleController localeController,
    AppNotificationFilter initialFilter = AppNotificationFilter.all,
  }) {
    final repo = NotificationCenterRepository.instance;
    final isEn = localeController.isEnglish;
    repo.refresh(role: roleController, isEnglish: isEn);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterSheet(
        roleController: roleController,
        localeController: localeController,
        initialFilter: initialFilter,
      ),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  late AppNotificationFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  void _onTap(AppNotification n) {
    NotificationCenterRepository.instance.markRead(n.id);
    Navigator.of(context).pop();
    final route = n.route;
    if (route == null || route.isEmpty) return;
    if (route == '/contact') {
      MainShellScope.maybeOf(context)?.selectTab(3);
      return;
    }
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      height: maxH,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.notifications,
                    style: LiLayout.homeSectionTitle.copyWith(color: p.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: NotificationCenterRepository.instance.markAllRead,
                  child: Text(
                    s.notifMarkAllRead,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip(s.notifFilterAll, AppNotificationFilter.all, p),
                _chip(s.notifFilterChat, AppNotificationFilter.chat, p),
                _chip(s.notifFilterAppointment, AppNotificationFilter.appointment, p),
                _chip(s.notifFilterListing, AppNotificationFilter.listing, p),
                _chip(s.notifFilterSystem, AppNotificationFilter.system, p),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: NotificationCenterRepository.instance,
              builder: (context, _) {
                final repo = NotificationCenterRepository.instance;
                if (repo.isLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final items = repo.filtered(_filter);
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        s.notifEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textSecondary, fontSize: 14),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _NotificationTile(
                    item: items[i],
                    palette: p,
                    onTap: () => _onTap(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, AppNotificationFilter f, AppPalette p) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? p.primary : p.textSecondary,
        ),
        backgroundColor: p.surface,
        selectedColor: p.primaryLight,
        side: BorderSide(color: selected ? p.primary.withOpacity(0.35) : p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.palette,
    required this.onTap,
  });

  final AppNotification item;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final urgent = item.priority == AppNotificationPriority.urgent;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: item.read
                  ? p.border
                  : p.primary.withOpacity(urgent ? 0.45 : 0.28),
            ),
            boxShadow: item.read ? null : [AppTheme.cardShadowFor(p)],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.type.icon, color: p.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: LiLayout.homeCardTitle,
                        fontWeight: item.read ? FontWeight.w600 : FontWeight.w700,
                        color: p.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: LiLayout.homeCardSubtitle,
                        color: p.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (item.ctaLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.ctaLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
