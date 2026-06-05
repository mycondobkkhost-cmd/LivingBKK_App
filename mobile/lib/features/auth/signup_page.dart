import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_perspective.dart';
import '../../services/auth_service.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/legal_policy_rich_text.dart';
import '../../theme/living_bkk_brand.dart';
import '../../theme/li_layout.dart';
import '../../utils/admin_routing.dart';
import 'auth_form_widgets.dart';

/// สมัครสมาชิก — โครงคล้ายแอปทั่วไป แต่ใช้ธีม LivingBKK (ม่วงพาสเทล / layout ต่างจาก login)
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = AuthService.instance;
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  Uint8List? _avatarBytes;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _afterAuth() async {
    final role = await _auth.fetchProfileRole();
    if (role == 'admin') {
      widget.roleController.setPlatformAdmin(true);
    } else {
      widget.roleController.setPlatformAdmin(false);
    }
    widget.roleController.setPerspective(AppPerspective.customer);
    await SessionGate.instance?.markAuthenticated();
    if (!mounted) return;
    if (role == 'admin') {
      context.go(adminHomePath());
      return;
    }
    context.go('/');
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (!_acceptedTerms) {
      _snack(s.signUpAcceptTermsRequired);
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _snack(s.signUpFieldsRequired);
      return;
    }
    if (!Env.isConfigured) {
      _snack(s.configureSupabaseFirst);
      return;
    }

    setState(() => _loading = true);
    try {
      final phone = _normalizedPhone();
      await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        phone: phone,
        displayName: _displayName.text.trim().isEmpty ? null : _displayName.text.trim(),
      );
      await _afterAuth();
      if (!mounted) return;
      if (_avatarBytes != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.signUpAvatarLaterHint)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _normalizedPhone() {
    final raw = _phone.text.trim().replaceAll(RegExp(r'\s|-'), '');
    if (raw.isEmpty) return null;
    if (raw.startsWith('+')) return raw;
    if (raw.startsWith('0')) return '+66${raw.substring(1)}';
    return '+66$raw';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.headerTint,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: Text(
          s.signUpPageTitle,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 20, LiLayout.pagePadding, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.signUpPageIntro,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Center(child: _AvatarPicker(bytes: _avatarBytes, onTap: _pickAvatar)),
            const SizedBox(height: 28),
            AuthFormField(
              controller: _email,
              hint: s.emailLabel,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.signUpCountryCode,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AuthFormField(
                    controller: _phone,
                    hint: s.signUpPhoneHint,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AuthFormField(
              controller: _displayName,
              hint: s.signUpDisplayNameHint,
            ),
            const SizedBox(height: 14),
            AuthFormField(
              controller: _password,
              hint: s.authPassword,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.primary,
              title: LegalPolicyRichText(
                s: s,
                prefix: s.signUpTermsPrefix,
                suffix: '',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: AppTheme.pillFilled,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        s.signUpTitle,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.authHaveAccount, style: TextStyle(color: AppTheme.textSecondary)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    s.authSignInLink,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.bytes, required this.onTap});

  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.inputFill],
              ),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35), width: 2),
              image: bytes != null
                  ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
                  : null,
            ),
            child: bytes == null
                ? Icon(Icons.person_outline, size: 44, color: AppTheme.primary.withOpacity(0.45))
                : null,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
