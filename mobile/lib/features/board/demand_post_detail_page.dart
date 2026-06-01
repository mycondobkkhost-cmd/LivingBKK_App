import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/demand_post.dart';
import '../../theme/app_theme.dart';

class DemandPostDetailPage extends StatelessWidget {
  const DemandPostDetailPage({super.key, required this.post});

  final DemandPost post;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(post.postCode)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('แผนที่โซนความต้องการ')),
          ),
          const SizedBox(height: 16),
          if (post.description != null) Text(post.description!),
          const SizedBox(height: 12),
          if (post.maxPriceNet != null)
            Text('งบไม่เกิน ${currency.format(post.maxPriceNet)}'),
          if (post.minAreaSqm != null) Text('ขนาด ≥ ${post.minAreaSqm!.toInt()} ตร.ม.'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ข้อเสนอของผู้อื่นไม่แสดงต่อสาธารณะ — เฉพาะทีม LivingBKK ตรวจสอบ',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/board/${post.id}/offer', extra: post),
            child: const Text('เสนอทรัพย์'),
          ),
        ],
      ),
    );
  }
}
