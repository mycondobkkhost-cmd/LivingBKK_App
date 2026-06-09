import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../models/property_care_summary.dart';
import '../services/auth_service.dart';
import '../services/property_care_repository.dart';
import '../theme/app_theme.dart';

/// แบนเนอร์บนหน้าแรก — รอรับสิทธิ์ / รอเติมข้อมูลทรัพย์
class PropertyCareBanner extends StatefulWidget {
  const PropertyCareBanner({super.key});

  @override
  State<PropertyCareBanner> createState() => _PropertyCareBannerState();
}

class _PropertyCareBannerState extends State<PropertyCareBanner> {
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
      if (mounted) setState(() {
        _pending = [];
        _loaded = true;
      });
      return;
    }
    await PropertyCareRepository.ensureDemoForTrialOwner();
    final repo = PropertyCareRepository.instance;
    final all = await repo.summariesForCurrentUser();
    final need = all
        .where((s) => s.needsClaim || s.needsOwnerData)
        .toList();
    if (!mounted) return;
    setState(() {
      _pending = need;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _pending.isEmpty) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final claim = _pending.where((e) => e.needsClaim).length;
    final data = _pending.where((e) => e.needsOwnerData).length;
    final msg = claim > 0
        ? s.careBannerClaim(claim)
        : s.careBannerData(data);

    return Material(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Icon(Icons.home_work_outlined, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push(PostListingMenuConfig.caredPropertiesRoute),
              child: Text(
                claim > 0 ? s.careAcceptButton : s.careMineTabOpenButton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
