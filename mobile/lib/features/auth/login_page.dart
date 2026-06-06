import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_perspective.dart';
import '../../services/auth_service.dart';
import '../../state/locale_controller.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_routing.dart';
import '../../widgets/language_switch_button.dart';
import 'auth_form_widgets.dart';

/// หน้าเข้าสู่ระบบ — ธีมเดียวกับ header หน้าแรก
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.roleController,
    required this.localeController,
  });

  final UserRoleController roleController;
  final LocaleController localeController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _afterAuth() async {
    final role = await _auth.fetchProfileRole();
    if (role == 'admin') {
      widget.roleController.setPlatformAdmin(true);
    } else {
      widget.roleController.setPlatformAdmin(false);
    }
    if (_auth.isTrialSignedIn) {
      widget.roleController.setRole(_auth.trialRole ?? 'seeker');
    } else {
      widget.roleController.setPerspective(AppPerspective.customer);
    }
    await SessionGate.instance?.markAuthenticated();
    if (!mounted) return;
    if (role == 'admin') {
      context.go(adminHomePath());
      return;
    }
    context.go('/');
  }

  Future<void> _enterTrial() async {
    final s = AppStrings.of(context);
    setState(() => _loading = true);
    try {
      await _auth.signInAsTrial();
      await _afterAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.trialEntered), duration: const Duration(seconds: 3)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty && Env.allowPasswordlessLogin) {
      await _enterTrial();
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      await _afterAuth();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyMessage(e)),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth(Future<void> Function() action) async {
    if (!Env.isConfigured) {
      _showSnack(AppStrings.of(context).oauthNotConfigured);
      return;
    }
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _showSnack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final s = AppStrings.of(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      _showSnack(s.resetPasswordNeedEmail);
      return;
    }
    if (!Env.isConfigured) {
      _showSnack(s.configureSupabaseFirst);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.resetPassword(email);
      if (mounted) _showSnack(s.resetPasswordSent);
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
    return ListenableBuilder(
      listenable: widget.localeController,
      builder: (context, _) {
        final s = AppStrings.of(context);

        return AuthScreenShell(
          trailing: Padding(
            padding: const EdgeInsets.only(right: 18),
            child: LanguageSwitchButton(
              controller: widget.localeController,
              light: true,
              hero: true,
            ),
          ),
          form: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.authWelcome,
                  textAlign: TextAlign.center,
                  style: authTitleTextStyle(),
                ),
            const SizedBox(height: 20),
            if (!Env.isConfigured && !Env.allowPasswordlessLogin)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  s.configureSupabaseFirst,
                  textAlign: TextAlign.center,
                  style: authBodyTextStyle(),
                ),
              )
            else ...[
              AuthFormField(
                controller: _email,
                label: s.authEmailOrUsername,
                hint: s.authEmailOrUsername,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AuthFormField(
                controller: _password,
                label: s.authPassword,
                hint: s.authPassword,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  child: Text(
                    s.forgotPassword,
                    style: authBodyTextStyle(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: authPrimaryButtonStyle(),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.signInTitle),
                ),
              ),
              if (Env.allowPasswordlessLogin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _enterTrial,
                    style: AppTheme.pillOutlined.copyWith(
                      side: MaterialStateProperty.all(
                        BorderSide(color: LivingBkkBrand.homeHeaderBlockColor.withOpacity(0.45)),
                      ),
                    ),
                    child: Text(
                      s.authQuickEntry,
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LivingBkkBrand.homeHeaderBlockColor,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                s.authOrLoginWith,
                textAlign: TextAlign.center,
                style: authBodyTextStyle(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthSocialButton(
                    color: const Color(0xFF1877F2),
                    icon: Icons.facebook,
                    iconColor: Colors.white,
                    onTap: _loading ? null : () => _oauth(_auth.signInWithFacebook),
                  ),
                  const SizedBox(width: 16),
                  AuthSocialButton(
                    color: Colors.white,
                    border: AppTheme.border,
                    child: const GoogleLogoIcon(size: 24),
                    onTap: _loading ? null : () => _oauth(_auth.signInWithGoogle),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  s.authNoAccountYet,
                  style: authBodyTextStyle(),
                ),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: Text(
                    s.authSignUpFree,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: LivingBkkBrand.homeHeaderBlockColor,
                      decoration: TextDecoration.underline,
                      decorationColor: LivingBkkBrand.homeHeaderBlockColor,
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}
