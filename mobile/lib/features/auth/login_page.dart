import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String _role = 'seeker';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await _auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
        );
      } else {
        await _auth.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'โหมด Demo — ยังไม่ตั้งค่า Supabase',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'แก้ไฟล์ mobile/assets/env แล้วรันแอปใหม่\nหรือดู docs/SETUP.md',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('ใช้งาน Demo ต่อ'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'LivingBKK',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'กรุงเทพฯ + ปริมณฑล · เช่า ซื้อ ขาย',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'อีเมล'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
            obscureText: true,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            const Text('บทบาทเริ่มต้น', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'seeker', label: Text('Seeker')),
                ButtonSegment(value: 'owner', label: Text('Owner')),
                ButtonSegment(value: 'agent', label: Text('Agent')),
              ],
              selected: {_role},
              onSelectionChanged: (v) => setState(() => _role = v.first),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isSignUp ? 'สมัคร' : 'เข้าสู่ระบบ'),
          ),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(_isSignUp ? 'มีบัญชีแล้ว? เข้าสู่ระบบ' : 'ยังไม่มีบัญชี? สมัคร'),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('ข้าม (ดู Demo)'),
          ),
        ],
      ),
    );
  }
}
