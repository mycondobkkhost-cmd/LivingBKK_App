import 'package:flutter/material.dart';
import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../navigation/post_listing_navigation.dart';
import '../services/listing_owner_repository.dart';
import '../state/user_role_controller.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// แจ้งเตือนบนหน้าแรกเมื่อมีประกาศที่ควรกด「ยืนยันว่าง」(ครบ 7 วัน)
class ListingBumpReminderBanner extends StatefulWidget {
  const ListingBumpReminderBanner({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  State<ListingBumpReminderBanner> createState() => _ListingBumpReminderBannerState();
}

class _ListingBumpReminderBannerState extends State<ListingBumpReminderBanner> {
  final _repo = ListingOwnerRepository();
  int _dueCount = 0;
  int _minDaysLeft = 30;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.roleController.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.roleController.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.roleController.isOwner && !widget.roleController.isAgent) {
      if (mounted) setState(() => _dueCount = 0);
      return;
    }

    final rows = await _repo.myListings(includeArchived: false);
    var due = 0;
    var minLeft = 30;
    for (final row in rows) {
      if (!ListingOwnerRepository.needsBumpReminder(row)) continue;
      due++;
      final left = ListingOwnerRepository.daysUntilAutoArchive(row);
      if (left < minLeft) minLeft = left;
    }

    if (!mounted) return;
    setState(() {
      _dueCount = due;
      _minDaysLeft = minLeft;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dueCount == 0) return const SizedBox.shrink();
    if (!widget.roleController.isOwner && !widget.roleController.isAgent) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        0,
        LiLayout.pagePadding,
        8,
      ),
      child: Material(
        color: AppTheme.accentAmberLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => PostListingNavigation.openMyListings(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentMid.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: AppTheme.accentMid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.listingBumpBannerTitle(_dueCount),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.listingBumpReminder(_minDaysLeft),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => PostListingNavigation.openMyListings(context),
                  child: Text(s.confirmAvailable, style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
