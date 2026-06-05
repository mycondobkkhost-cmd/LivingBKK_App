import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// ป้าย「ด่วนที่สุด」บนบอร์ด — เห็นก่อนกดเข้าอ่านรายละเอียด
class DemandUrgentRushStrip extends StatelessWidget {
  const DemandUrgentRushStrip({
    super.key,
    required this.isRent,
    this.compact = false,
  });

  final bool isRent;
  final bool compact;

  static const _rushOrange = Color(0xFFEA580C);
  static const _rushBg = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _rushOrange.withOpacity(0.16),
            _rushBg,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: _rushOrange.withOpacity(0.45), width: 1.25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: compact ? 18 : 22,
            color: _rushOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.demandUrgentRushBadge(isRent),
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.demandUrgentRushHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ป้ายเล็กในรายการความต้องการของฉัน
class RequirementUrgentChip extends StatelessWidget {
  const RequirementUrgentChip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 14, color: Color(0xFFEA580C)),
          const SizedBox(width: 4),
          Text(
            s.requirementUrgentRushSummary,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }
}
