import 'package:flutter/material.dart';

import '../features/listing/property_care_complete_sheet.dart';
import '../l10n/app_strings.dart';
import '../models/property_care_summary.dart';
import '../services/auth_service.dart';
import '../services/property_care_repository.dart';
import '../theme/app_theme.dart';
import '../utils/app_notice.dart';
import 'property_care_summary_card.dart';

/// รายการทรัพย์ที่มอบให้ดูแล — แสดงบนหน้าของฉัน
class PropertyCareMineSection extends StatefulWidget {
  const PropertyCareMineSection({super.key});

  @override
  State<PropertyCareMineSection> createState() => _PropertyCareMineSectionState();
}

class _PropertyCareMineSectionState extends State<PropertyCareMineSection> {
  final _repo = PropertyCareRepository.instance;
  List<PropertyCareSummary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_load);
    _repo.addListener(_load);
    PropertyCareRepository.ensureDemoForTrialOwner();
    _load();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_load);
    _repo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isSignedIn) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
      return;
    }
    await PropertyCareRepository.ensureDemoForTrialOwner();
    final rows = await _repo.summariesForCurrentUser();
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _accept(PropertyCareSummary item) async {
    try {
      await _repo.acceptClaim(item.right.id);
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.careMineSectionTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          s.careMineTabBody(
            _items.where((e) => e.needsClaim).length,
            _items.where((e) => e.needsOwnerData).length,
          ),
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _items.length; i++) ...[
          PropertyCareSummaryCard(
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
          if (i < _items.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
