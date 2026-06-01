import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'lead_bot_sheet.dart';

class ContactTabPage extends StatelessWidget {
  const ContactTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ติดต่อ LivingBKK')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent, size: 72, color: AppTheme.primary.withValues(alpha: 0.8)),
              const SizedBox(height: 24),
              const Text(
                'สอบถามหรือนัดเข้าชมทรัพย์',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'บอทจะเก็บข้อมูลคัดกรองก่อนส่งให้ทีมประสานงาน',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => showLeadBotSheet(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('เริ่มสนทนา'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
