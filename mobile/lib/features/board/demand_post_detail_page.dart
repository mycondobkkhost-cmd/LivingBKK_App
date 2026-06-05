import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../navigation/demand_board_navigation.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/demand/demand_offer_policy_chip.dart';
import '../../widgets/demand/demand_post_favorite_button.dart';
import '../../widgets/demand/demand_urgent_rush_strip.dart';
import '../../utils/localized_content.dart';
import '../../models/demand_post.dart';
import '../../theme/app_theme.dart';

class DemandPostDetailPage extends StatelessWidget {
  const DemandPostDetailPage({super.key, required this.post});

  final DemandPost post;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(post.postCode),
        actions: [
          DemandPostFavoriteButton(post: post, showSnackBar: true),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (post.isUrgentRush) ...[
            DemandUrgentRushStrip(isRent: post.transactionType == 'rent'),
            const SizedBox(height: 14),
          ],
          Text(
            post.localizedTitle(s.isEnglish),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(s.demandZoneMap)),
          ),
          const SizedBox(height: 16),
          if (post.localizedDescription(s.isEnglish) != null)
            Text(post.localizedDescription(s.isEnglish)!),
          const SizedBox(height: 12),
          if (post.maxPriceNet != null)
            Text(s.budgetMax(currency.format(post.maxPriceNet))),
          if (post.minAreaSqm != null) Text(s.areaMin(post.minAreaSqm!.toInt())),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    DemandOfferPolicyChip(
                      policy: post.offerAcceptancePolicy,
                      compact: false,
                    ),
                    if (post.leadSource != null)
                      DemandLeadSourceChip(source: post.leadSource!),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.demandOfferPolicyDetail(post.offerAcceptancePolicy),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              s.offersPrivateAdmin,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                DemandBoardNavigation.openSubmitOffer(context, post: post),
            child: Text(s.submitOfferTitle),
          ),
        ],
      ),
    );
  }
}
