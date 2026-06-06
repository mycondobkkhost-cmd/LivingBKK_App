import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class OpsChartPoint {
  const OpsChartPoint({required this.label, required this.value});

  final String label;
  final int value;
}

/// กราฟแท่งแนวตั้งแบบเบา — ไม่ต้องพึ่ง package ภายนอก
class OpsMiniBarChart extends StatelessWidget {
  const OpsMiniBarChart({
    super.key,
    required this.title,
    required this.points,
    this.color,
    this.maxBarHeight = 72,
    this.emptyHint,
  });

  final String title;
  final List<OpsChartPoint> points;
  final Color? color;
  final double maxBarHeight;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppTheme.primary;
    final maxVal = points.fold<int>(0, (m, p) => p.value > m ? p.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        if (points.isEmpty)
          Text(
            emptyHint ?? '—',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          )
        else
          SizedBox(
            height: maxBarHeight + 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < points.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _Bar(
                      label: points[i].label,
                      value: points[i].value,
                      maxValue: maxVal,
                      color: barColor,
                      maxHeight: maxBarHeight,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// แปลงแถวสถิติรายวัน → จุดกราฟ (เรียงเก่า→ใหม่)
  static List<OpsChartPoint> fromDailyRows(
    List<Map<String, dynamic>> rows, {
    required String Function(dynamic date, bool isEnglish) labelBuilder,
    required int Function(Map<String, dynamic> row) valuePicker,
    bool isEnglish = false,
    int maxPoints = 14,
  }) {
    final slice = rows.take(maxPoints).toList().reversed.toList();
    return slice
        .map(
          (r) => OpsChartPoint(
            label: labelBuilder(r['stat_date'], isEnglish),
            value: valuePicker(r),
          ),
        )
        .toList();
  }

  static String shortDateLabel(dynamic date, bool isEnglish) {
    if (date is DateTime) {
      return DateFormat(isEnglish ? 'd/M' : 'd/M', isEnglish ? 'en' : 'th').format(date);
    }
    final raw = date?.toString() ?? '';
    if (raw.length >= 10) {
      final parts = raw.substring(0, 10).split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}';
    }
    return raw.isEmpty ? '—' : raw;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.maxHeight,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final h = ratio <= 0 ? 4.0 : (ratio * maxHeight).clamp(4.0, maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value > 0 ? '$value' : '',
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary, height: 1),
        ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: AppTheme.animNormal,
          height: h,
          decoration: BoxDecoration(
            color: value > 0 ? color : AppTheme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
