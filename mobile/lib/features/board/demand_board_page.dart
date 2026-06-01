import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/demand_post.dart';
import '../../services/demand_repository.dart';
import '../../theme/app_theme.dart';

class DemandBoardPage extends StatefulWidget {
  const DemandBoardPage({super.key});

  @override
  State<DemandBoardPage> createState() => _DemandBoardPageState();
}

class _DemandBoardPageState extends State<DemandBoardPage> {
  final _repo = DemandRepository();
  List<DemandPost> _posts = [];
  bool _loading = true;
  bool _openOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await _repo.fetchOpenPosts();
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('บอร์ดประกาศ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('เปิดรับข้อเสนอ')),
                ButtonSegment(value: false, label: Text('ปิดแล้ว')),
              ],
              selected: {_openOnly},
              onSelectionChanged: (v) => setState(() => _openOnly = v.first),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = _posts[i];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/board/${p.id}', extra: p),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.transactionType == 'rent' ? 'เช่า' : 'ซื้อ',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (p.description != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    p.description!,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (p.minAreaSqm != null)
                                      Text('≥ ${p.minAreaSqm!.toInt()} ตร.ม.',
                                          style: const TextStyle(fontSize: 13)),
                                    if (p.maxPriceNet != null)
                                      Text(
                                        '≤ ${currency.format(p.maxPriceNet)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    if (p.maxDistanceBtsKm != null)
                                      Text('BTS ≤ ${p.maxDistanceBtsKm} กม.',
                                          style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'โดย LivingBKK · ไม่แสดงจำนวนผู้เสนอ',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
