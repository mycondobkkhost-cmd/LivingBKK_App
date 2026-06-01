import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WorkPage extends StatelessWidget {
  const WorkPage({super.key, this.isAgent = false});

  final bool isAgent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('งานของฉัน')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('คำขอที่ส่ง'),
          _placeholderCard(
            'Lead ที่ส่ง',
            'รอเชื่อม Supabase leads ตาม role',
            Icons.mail_outline,
          ),
          if (isAgent) ...[
            const SizedBox(height: 16),
            _sectionTitle('โคเอเจ้นท์'),
            _placeholderCard(
              'คำขอ Co-Agent',
              'สถานะ pending / approved',
              Icons.handshake_outlined,
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('ข้อเสนอบอร์ด'),
          _placeholderCard(
            'DM-2026-000001',
            'โคเอเจ้นท์ 50/50 · รอตรวจ',
            Icons.description_outlined,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _placeholderCard(String title, String subtitle, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
