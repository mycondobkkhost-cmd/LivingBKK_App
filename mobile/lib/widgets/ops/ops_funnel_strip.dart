import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OpsFunnelStep {
  const OpsFunnelStep({
    required this.label,
    required this.value,
    this.rateLabel,
  });

  final String label;
  final int value;
  final String? rateLabel;
}

/// แถบ funnel แนวนอน — Lead → รับ → นัด → ยืนยัน
class OpsFunnelStrip extends StatelessWidget {
  const OpsFunnelStrip({
    super.key,
    required this.steps,
    this.title,
  });

  final String? title;
  final List<OpsFunnelStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final peak = steps.fold<int>(0, (m, s) => s.value > m ? s.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
                ),
              Expanded(child: _Step(step: steps[i], peak: peak)),
            ],
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.peak});

  final OpsFunnelStep step;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final ratio = peak == 0 ? 0.0 : step.value / peak;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.35 + ratio * 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            '${step.value}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.2),
          ),
          if (step.rateLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              step.rateLabel!,
              style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
