import 'package:flutter/material.dart';

import '../../config/env.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryLight,
            child: Icon(Icons.person, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('ผู้ใช้ทดสอบ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(
            Env.isConfigured ? 'เชื่อม Supabase แล้ว' : 'โหมด Demo (แก้ค่าใน assets/env)',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          const Text('บทบาท (ทดสอบ UI)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: roleController,
            builder: (context, _) {
              return SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'seeker', label: Text('Seeker')),
                  ButtonSegment(value: 'owner', label: Text('Owner')),
                  ButtonSegment(value: 'agent', label: Text('Agent')),
                ],
                selected: {roleController.role},
                onSelectionChanged: (v) => roleController.setRole(v.first),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'เลือก Agent แล้วกลับแท็บ「ค้นหา」เพื่อเห็นโหมดขอโคเอเจ้นท์ได้',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
