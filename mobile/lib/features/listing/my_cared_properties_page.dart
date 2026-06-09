import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/property_care_summary.dart';
import '../../services/auth_service.dart';
import '../../services/property_care_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../utils/app_notice.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../widgets/property_care_summary_card.dart';
import 'property_care_complete_sheet.dart';

/// ทรัพย์ที่ฉันดูแล — หลังแอดมินมอบสิทธิ์
class MyCaredPropertiesPage extends StatefulWidget {
  const MyCaredPropertiesPage({super.key});

  @override
  State<MyCaredPropertiesPage> createState() => _MyCaredPropertiesPageState();
}

class _MyCaredPropertiesPageState extends State<MyCaredPropertiesPage> {
  final _repo = PropertyCareRepository.instance;
  List<PropertyCareSummary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_load);
    PropertyCareRepository.ensureDemoForTrialOwner();
    _load();
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _repo.summariesForCurrentUser();
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _accept(PropertyCareSummary item) async {
    final s = context.s;
    setState(() => _loading = true);
    try {
      await _repo.acceptClaim(item.right.id);
      if (!mounted) return;
      AppNotice.show(context, s.careAcceptDone);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotice.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottomPad = PageSafeInsets.bottom(context);

    return ConsumerPageShell(
      title: s.myCaredPropertiesTitle,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      safeBottomBody: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _empty(s, bottomPad)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      LiLayout.pagePadding,
                      12,
                      LiLayout.pagePadding,
                      bottomPad + 24,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => PropertyCareSummaryCard(
                      item: _items[i],
                      onAccept: () => _accept(_items[i]),
                      onRefresh: _load,
                      onComplete: () async {
                        await showPropertyCareCompleteSheet(
                          context,
                          summary: _items[i],
                          onDone: _load,
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _empty(AppStrings s, double bottomPad) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        48,
        LiLayout.pagePadding,
        bottomPad + 24,
      ),
      children: [
        Icon(Icons.home_work_outlined, size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(
          s.myCaredPropertiesEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        if (!AuthService.instance.isSignedIn) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push('/login'),
            child: Text(s.signInTitle),
          ),
        ],
      ],
    );
  }
}

