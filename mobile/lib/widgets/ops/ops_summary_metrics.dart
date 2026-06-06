import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OpsSummaryMetric {
  const OpsSummaryMetric({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
}

/// แถวการ์ดสรุป KPI แบบกะทัดรัด
class OpsSummaryMetrics extends StatelessWidget {
  const OpsSummaryMetrics({super.key, required this.metrics});

  final List<OpsSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _MetricCard(metric: metrics[i])),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (m) => SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _MetricCard(metric: m),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final OpsSummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final accent = metric.accent ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metric.icon != null)
            Icon(metric.icon, size: 18, color: accent),
          if (metric.icon != null) const SizedBox(height: 6),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.subtitle!,
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withOpacity(0.85)),
            ),
          ],
        ],
      ),
    );
  }
}
