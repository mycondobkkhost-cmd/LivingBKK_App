import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// ข้อควรทราบ — บริการช่วยหาทรัพย์ฟรี แต่ห้ามใช้เล่นๆ / ให้ข้อมูลเท็จ
class RequirementSeriousUseNotice extends StatelessWidget {
  const RequirementSeriousUseNotice({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight.withOpacity(0.55),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 18 : 22,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.requirementSeriousUseTitle,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  s.requirementSeriousUseBody,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
