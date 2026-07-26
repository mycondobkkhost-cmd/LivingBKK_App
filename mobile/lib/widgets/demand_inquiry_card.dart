import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/demand_post.dart';
import '../theme/app_theme.dart';
import '../theme/fb_feed_chrome.dart';
import '../theme/living_bkk_brand.dart';
import 'demand/demand_post_favorite_button.dart';
import 'demand/demand_urgent_rush_strip.dart';

/// การ์ดฟีดประกาศหาทรัพย์ — โมดูลฟีดแบบ Facebook มือถือ
class DemandInquiryCard extends StatelessWidget {
  const DemandInquiryCard({
    super.key,
    required this.post,
    required this.timeLabel,
    required this.onTap,
    required this.onOffer,
    this.myStockMatchScore,
    this.selectionMode = false,
  });

  final DemandPost post;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onOffer;
  final bool selectionMode;
  final int? myStockMatchScore;

  String _budgetPlain(AppStrings s, NumberFormat currency) {
    final min = post.minPriceNet;
    final max = post.maxPriceNet;
    if (min != null && max != null && (max - min).abs() > 1) {
      return '${currency.format(min)} - ${currency.format(max)}';
    }
    if (max != null) return currency.format(max);
    if (min != null) return s.demandBudgetFrom(currency.format(min));
    return s.t('ตามตกลง', 'Negotiable');
  }

  String _lookingSummary(AppStrings s) {
    final tx = post.transactionType == 'rent'
        ? s.demandLookingRent
        : s.demandLookingSale;
    final type = post.propertyLabel(s.isEnglish);
    final zones = post.zones.isNotEmpty
        ? post.zones.take(4).join(', ')
        : (post.zoneLabel(s.isEnglish) ?? '');
    final project = post.projectLine(s.isEnglish);
    final parts = <String>[
      tx,
      type,
      if (project != null && project.isNotEmpty) project,
      if (zones.isNotEmpty) zones,
    ];
    return parts.join(' ');
  }

  String _posterName(AppStrings s) {
    final note = s.demandLeadSourceFootnote(post.leadSource).trim();
    if (note.isNotEmpty) return note;
    return LivingBkkBrand.name;
  }

  String _avatarLetter(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'R';
    return t.substring(0, 1).toUpperCase();
  }

  String? _bodyText(AppStrings s) {
    final desc = s.isEnglish
        ? (post.descriptionEn?.trim().isNotEmpty == true
            ? post.descriptionEn
            : post.description)
        : post.description;
    if (desc != null && desc.trim().isNotEmpty) return desc.trim();
    final title = s.isEnglish
        ? (post.titleEn?.trim().isNotEmpty == true ? post.titleEn! : post.title)
        : post.title;
    final t = title.trim();
    if (t.isEmpty || t == post.projectLine(s.isEnglish)) return null;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currency =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final isUrgent = post.isUrgentRush;
    final poster = _posterName(s);
    final body = _bodyText(s);
    final accent = LivingBkkBrand.brandRed;
    final summaryBg = LivingBkkBrand.brandRedTint;

    return FbFeedCard(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUrgent) ...[
                  DemandUrgentRushStrip(
                    isRent: post.transactionType == 'rent',
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: summaryBg,
                      child: Text(
                        _avatarLetter(poster),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  poster,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: LivingBkkBrand.serviceGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!selectionMode) ...[
                      DemandPostFavoriteButton(post: post, iconSize: 20),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        onSelected: (v) {
                          if (v == 'detail') onTap();
                          if (v == 'offer') onOffer();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'detail',
                            child: Text(s.t('ดูรายละเอียด', 'View details')),
                          ),
                          PopupMenuItem(
                            value: 'offer',
                            child: Text(s.demandSubmitOffer),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: summaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: s.t('กำลังมองหา : ', 'Looking for: '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: accent.withOpacity(0.9),
                                      ),
                                    ),
                                    TextSpan(
                                      text: _lookingSummary(s),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: LivingBkkBrand.brandRedDark,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: s.t('ช่วงราคา : ', 'Budget: '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: accent.withOpacity(0.9),
                                      ),
                                    ),
                                    TextSpan(
                                      text: _budgetPlain(s, currency),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: LivingBkkBrand.brandRedDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (myStockMatchScore != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 16,
                                color: LivingBkkBrand.accentOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.demandMyStockMatchBadge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LivingBkkBrand.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppTheme.textPrimary.withOpacity(0.92),
                    ),
                  ),
                  if (body.length > 90)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        s.t('อ่านเพิ่มเติม', 'Read more'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LivingBkkBrand.brandRed,
                        ),
                      ),
                    ),
                ],
                if (!selectionMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: FilledButton(
                            onPressed: onOffer,
                            style: FilledButton.styleFrom(
                              backgroundColor: LivingBkkBrand.brandRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(s.demandSubmitOffer),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onTap,
                        tooltip: s.t('รายละเอียด', 'Details'),
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: onTap,
                        tooltip: s.t('แชร์', 'Share'),
                        icon: Icon(
                          Icons.ios_share_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
