import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/demand_post.dart';
import '../theme/app_theme.dart';
import 'demand/demand_offer_policy_chip.dart';
import 'demand/demand_post_favorite_button.dart';
import 'demand/demand_urgent_rush_strip.dart';

/// การ์ดประกาศหาทรัพย์แบบกะทัดรัด — ~4 รายการต่อหน้าจอมือถือ
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
  /// คะแนนจับคู่ MyStock (≥ 42) — แสดงป้ายเมื่อมีค่า
  final int? myStockMatchScore;

  String _budgetLabel(AppStrings s, NumberFormat currency) {
    final min = post.minPriceNet;
    final max = post.maxPriceNet;
    if (min != null && max != null && (max - min).abs() > 1) {
      return s.demandBudgetRange(currency.format(min), currency.format(max));
    }
    if (max != null) {
      return s.demandBudgetUpTo(currency.format(max));
    }
    if (min != null) {
      return s.demandBudgetFrom(currency.format(min));
    }
    return s.t('ติดต่อสอบถาม', 'Contact for budget');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final isRent = post.transactionType == 'rent';
    final isCash = post.isCashCase;
    final isUrgent = post.isUrgentRush;
    final project = post.projectLine(s.isEnglish);
    final zone = post.zoneLabel(s.isEnglish);

    final txColor = isRent ? AppTheme.primary : AppTheme.cta;
    final txBg = isRent ? AppTheme.primaryLight : AppTheme.accentRoseLight;

    return Material(
      color: AppTheme.cardTint,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: isUrgent
              ? const Color(0xFFEA580C)
              : (isCash ? AppTheme.warning : AppTheme.border),
          width: isUrgent || isCash ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUrgent) ...[
                DemandUrgentRushStrip(isRent: isRent, compact: true),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  _Tag(
                    label: isRent ? s.demandLookingRent : s.demandLookingSale,
                    fg: txColor,
                    bg: txBg,
                  ),
                  const SizedBox(width: 4),
                  _Tag(
                    label: post.propertyLabel(s.isEnglish),
                    fg: AppTheme.textSecondary,
                    bg: AppTheme.backgroundAlt,
                  ),
                  if (isCash) ...[
                    const SizedBox(width: 4),
                    _Tag(
                      label: s.demandCashBadge,
                      fg: AppTheme.warning,
                      bg: AppTheme.warningLight,
                      icon: Icons.payments_outlined,
                    ),
                  ],
                  const Spacer(),
                  if (!selectionMode) ...[
                    DemandPostFavoriteButton(post: post, iconSize: 18),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    timeLabel,
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  DemandOfferPolicyChip(policy: post.offerAcceptancePolicy),
                  if (post.leadSource != null)
                    DemandLeadSourceChip(source: post.leadSource!),
                  if (myStockMatchScore != null) ...[
                    _Tag(
                      label: s.demandMyStockMatchBadge,
                      fg: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                      icon: Icons.home_work_outlined,
                    ),
                  ],
                ],
              ),
              if (project != null && project.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
              if (zone != null && zone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: AppTheme.primary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        zone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 2),
              Text(
                _budgetLabel(s, currency),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!selectionMode) ...[
                const SizedBox(height: 6),
                Divider(height: 1, color: AppTheme.divider),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        'LB',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.demandLeadSourceFootnote(post.leadSource),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                    FilledButton(
                      onPressed: onOffer,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      child: Text(s.demandSubmitOffer),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.fg,
    required this.bg,
    this.icon,
  });

  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
