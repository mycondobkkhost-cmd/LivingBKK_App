import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_offer_acceptance.dart';
import '../../theme/app_theme.dart';

/// ป้ายบอกว่าประกาศรับข้อเสนอจากใคร
class DemandOfferPolicyChip extends StatelessWidget {
  const DemandOfferPolicyChip({
    super.key,
    required this.policy,
    this.compact = true,
  });

  final DemandOfferAcceptancePolicy policy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ownerOnly = policy == DemandOfferAcceptancePolicy.ownerOnly;
    final fg = ownerOnly ? const Color(0xFF1D4ED8) : const Color(0xFF047857);
    final bg = ownerOnly
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFD1FAE5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ownerOnly ? Icons.home_work_outlined : Icons.handshake_outlined,
            size: compact ? 10 : 12,
            color: fg,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              s.demandOfferPolicyBadge(policy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ป้ายแหล่งลีด (ลูกค้าตรง / นายหน้าหาให้ลูกค้า)
class DemandLeadSourceChip extends StatelessWidget {
  const DemandLeadSourceChip({super.key, required this.source});

  final DemandLeadSource source;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final label = s.demandLeadSourceBadge(source);
    if (label == null) return const SizedBox.shrink();

    final coAgent = source == DemandLeadSource.coAgentSourced;
    final fg = coAgent ? AppTheme.accentDeep : AppTheme.textSecondary;
    final bg = coAgent ? AppTheme.accentRoseLight : AppTheme.backgroundAlt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
