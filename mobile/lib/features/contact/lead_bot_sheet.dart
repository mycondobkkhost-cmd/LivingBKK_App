import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

void showLeadBotSheet(BuildContext context, {String? listingCode}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => LeadBotSheet(listingCode: listingCode ?? 'LB-AUTO'),
  );
}

class LeadBotSheet extends StatelessWidget {
  const LeadBotSheet({super.key, required this.listingCode});

  final String listingCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ติดต่อ / นัดชม',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'รหัสประกาศ: $listingCode',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'ชื่อเล่น *')),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(labelText: 'เบอร์โทร *'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ส่งคำขอแล้ว — เชื่อม Supabase leads ใน Phase 4.2'),
                ),
              );
            },
            child: const Text('ส่งคำขอ'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
