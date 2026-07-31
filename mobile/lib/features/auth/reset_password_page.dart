import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'auth_form_widgets.dart';

/// ตั้งรหัสผ่านใหม่หลังเปิดลิงก์จากอีเมลลืมรหัสผ่าน
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _auth = AuthService.instance;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final password = _password.text;
    if (password.length < 6) {
      _showSnack(s.resetPasswordTooShort);
      return;
    }
    if (password != _confirm.text) {
      _showSnack(s.resetPasswordMismatch);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.updatePassword(password);
      if (!mounted) return;
      _showSnack(s.resetPasswordSuccess);
      context.go('/');
    } catch (e) {
      if (mounted) _showSnack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AuthScreenShell(
      form: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.resetPasswordTitle, style: authTitleTextStyle()),
            const SizedBox(height: 8),
            Text(s.resetPasswordIntro, style: authSubtitleTextStyle()),
            const SizedBox(height: 24),
            AuthFormField(
              controller: _password,
              hint: s.authPassword,
              label: s.authPassword,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AuthFormField(
              controller: _confirm,
              hint: s.resetPasswordConfirmHint,
              label: s.resetPasswordConfirmHint,
              obscure: _obscure,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.resetPasswordSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
