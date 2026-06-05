import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// ช่องพิเศษ「หาแบบด่วนที่สุด」ในฟอร์มบอกความต้องการ
class RequirementUrgentRushToggle extends StatelessWidget {
  const RequirementUrgentRushToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _rushOrange = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Material(
      color: value ? _rushOrange.withOpacity(0.1) : AppTheme.backgroundAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? _rushOrange : AppTheme.border,
              width: value ? 2 : 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: _rushOrange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 32,
                color: value ? _rushOrange : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.requirementUrgentRushTitle} 🔥',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: value ? _rushOrange : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.requirementUrgentRushSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeColor: _rushOrange,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
