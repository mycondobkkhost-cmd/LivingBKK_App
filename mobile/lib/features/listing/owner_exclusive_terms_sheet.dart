import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_exclusive_options.dart';
import '../../services/platform_settings_service.dart';
import '../../theme/app_theme.dart';

/// เงื่อนไขเบื้องต้น — ฝากทรัพย์ Exclusive กับ RealXtate (เจ้าของ)
Future<bool?> showOwnerExclusiveTermsSheet(
  BuildContext context, {
  required String listingType,
  required int contractDays,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _OwnerExclusiveTermsSheet(
      listingType: listingType,
      contractDays: contractDays,
    ),
  );
}

class _OwnerExclusiveTermsSheet extends StatelessWidget {
  const _OwnerExclusiveTermsSheet({
    required this.listingType,
    required this.contractDays,
  });

  final String listingType;
  final int contractDays;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cfg = PlatformSettingsService.instance.exclusive;
    final isSale = ListingExclusiveOptions.isSaleType(listingType);
    final bumpH = isSale ? cfg.saleBumpHours : cfg.rentBumpHours;
    final bumpLabel = isSale
        ? s.ownerExclusiveBumpEveryDays(bumpH ~/ 24 == 0 ? 1 : bumpH ~/ 24)
        : s.ownerExclusiveBumpEveryHours(bumpH);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.ownerExclusiveTermsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.ownerExclusiveTermsIntro, style: _body),
                    const SizedBox(height: 12),
                    _bullet(s.ownerExclusiveTermsExclusiveOnly),
                    _bullet(s.ownerExclusiveTermsContract(
                      ListingExclusiveOptions.contractLabel(
                        contractDays,
                        s.isEnglish,
                        isSale: isSale,
                      ),
                      isSale,
                    )),
                    _bullet(s.ownerExclusiveTermsMarketing),
                    _bullet(s.ownerExclusiveTermsAutoBump(bumpLabel)),
                    const SizedBox(height: 8),
                    Text(s.ownerExclusiveTermsFollowUp, style: _body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: AppTheme.pillFilled,
              child: Text(s.ownerExclusiveTermsConfirm),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }

  static final _body = TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textSecondary);

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, height: 1.5)),
          Expanded(child: Text(text, style: _body)),
        ],
      ),
    );
  }
}
