import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../services/auth_service.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

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
          Text(
            auth.currentUser?.email ?? 'ผู้ใช้ทดสอบ (Demo)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            Env.isConfigured
                ? (auth.isSignedIn ? 'เชื่อม Supabase + ล็อกอินแล้ว' : 'ตั้งค่าแล้ว — ยังไม่ล็อกอิน')
                : 'โหมด Demo — แก้ mobile/assets/env',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (Env.isConfigured) ...[
            if (!auth.isSignedIn)
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('เข้าสู่ระบบ / สมัคร'),
              )
            else
              OutlinedButton(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ออกจากระบบแล้ว')),
                    );
                  }
                },
                child: const Text('ออกจากระบบ'),
              ),
            const SizedBox(height: 24),
          ],
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
                  ButtonSegment(value: 'admin', label: Text('Admin')),
                ],
                selected: {roleController.role},
                onSelectionChanged: (v) async {
                  roleController.setRole(v.first);
                  if (auth.isSignedIn) {
                    await auth.updateProfileRole(v.first);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Agent → แท็บค้นหามี「ขอโคเอเจ้นท์ได้」',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          if (roleController.role == 'owner' || roleController.role == 'agent') ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: auth.isSignedIn
                  ? () => context.push('/listing/create')
                  : () => context.push('/login'),
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('ลงประกาศทรัพย์'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: auth.isSignedIn
                  ? () => context.push('/listings/mine')
                  : () => context.push('/login'),
              icon: const Icon(Icons.list_alt),
              label: const Text('ประกาศของฉัน · ยืนยันว่าง'),
            ),
          ],
          if (roleController.role == 'admin') ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: auth.isSignedIn
                  ? () => context.push('/admin')
                  : () => context.push('/login'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('ศูนย์ Admin'),
            ),
          ],
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('คู่มือตั้งค่า'),
            subtitle: const Text('docs/SETUP.md + mobile/docs/MAPS_SETUP.md'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
