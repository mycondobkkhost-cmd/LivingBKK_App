import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../models/property_care_summary.dart';
import '../services/auth_service.dart';
import '../services/property_care_repository.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';
import '../utils/app_notice.dart';

/// การ์ดบนหน้า「จัดการประกาศ」— แยกจากประกาศที่ลงเอง
class PropertyCareOwnerPrompt extends StatefulWidget {
  const PropertyCareOwnerPrompt({super.key});

  @override
  State<PropertyCareOwnerPrompt> createState() => _PropertyCareOwnerPromptState();
}

class _PropertyCareOwnerPromptState extends State<PropertyCareOwnerPrompt> {
  List<PropertyCareSummary> _pending = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_load);
    PropertyCareRepository.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_load);
    PropertyCareRepository.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isSignedIn) {
      if (mounted) {
        setState(() {
          _pending = [];
          _loaded = true;
        });
      }
      return;
    }
    await PropertyCareRepository.ensureDemoForTrialOwner();
    final all = await PropertyCareRepository.instance.summariesForCurrentUser();
    final need = all.where((s) => s.needsClaim || s.needsOwnerData).toList();
    if (!mounted) return;
    setState(() {
      _pending = need;
      _loaded = true;
    });
  }

  Future<void> _acceptFirst() async {
    final claim = _pending.where((s) => s.needsClaim).toList();
    if (claim.isEmpty) {
      context.push(PostListingMenuConfig.caredPropertiesRoute);
      return;
    }
    try {
      await PropertyCareRepository.instance.acceptClaim(claim.first.right.id);
      if (!mounted) return;
      AppNotice.show(context, context.s.careAcceptDone);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _pending.isEmpty) return const SizedBox.shrink();

    final s = context.s;
    final claim = _pending.where((e) => e.needsClaim).length;
    final data = _pending.where((e) => e.needsOwnerData).length;

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: LivingBkkBrand.peach.withOpacity(0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.home_work_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.careMineTabTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.careMineTabBody(claim, data),
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: claim > 0
                        ? _acceptFirst
                        : () => context.push(PostListingMenuConfig.caredPropertiesRoute),
                    child: Text(
                      claim > 0 ? s.careAcceptButton : s.careMineTabOpenButton,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () =>
                      context.push(PostListingMenuConfig.caredPropertiesRoute),
                  child: Text(s.careMineTabOpenButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
