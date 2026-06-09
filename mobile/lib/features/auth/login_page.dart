import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/env.dart';
import '../../config/demand_board_menu_config.dart';
import '../../config/post_listing_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_perspective.dart';
import '../../services/auth_service.dart';
import '../../services/demo_cast_session.dart';
import '../../services/property_care_notification_service.dart';
import '../../services/property_care_repository.dart';
import '../../state/locale_controller.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
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

  /// ปลายทางหลังล็อกอิน — รวม `nav` ที่หลุดจาก redirect เมื่อ URL ไม่ encode `?`
  String? get _redirectTarget {
    final uri = GoRouterState.of(context).uri;
    final redirect = uri.queryParameters['redirect'];
    if (redirect == null || redirect.isEmpty) return null;
    if (redirect.contains('?')) return redirect;
    final nav = uri.queryParameters['nav'];
    if (nav != null && nav.isNotEmpty && isAdminRoute(redirect)) {
      return '$redirect?nav=$nav';
    }
    return redirect;
  }

  bool get _requiresRealAccount {
    final target = _redirectTarget;
    return target == PostListingMenuConfig.createRoute ||
        target == DemandBoardMenuConfig.createRequirementRoute;
  }

  /// มาจากลิงก์หลังบ้าน — ทดลองต้องเข้าเป็นผู้ดูแลระบบ ไม่ใช่คนหาบ้าน
  bool get _redirectIsAdmin {
    final target = _redirectTarget;
    if (target == null || target.isEmpty) return false;
    final path = Uri.tryParse(target)?.path ?? target.split('?').first;
    return isAdminRoute(path);
  }

  String _trialRoleForRedirect() => _redirectIsAdmin ? 'admin' : 'seeker';

  String? _adminRedirectAfterAuth() {
    final target = _redirectTarget;
    if (target == null || target.isEmpty) return null;
    final path = Uri.tryParse(target)?.path ?? target.split('?').first;
    if (!isAdminRoute(path)) return null;
    return target;
  }

  Future<void> _goAfterAuth() async {
    final redirect = _redirectTarget;
    if (redirect != null &&
        redirect.isNotEmpty &&
        _auth.canCreateListing) {
      context.go(redirect);
      return;
    }
    context.go('/');
  }

  Future<void> _afterAuth() async {
    final access = await _auth.fetchProfileAccess();
    final role = access.role;
    widget.roleController.setPlatformAdmin(role == 'admin');
    widget.roleController.setViewingStaff(
      value: role == 'viewing_staff',
      slug: access.staffSlug,
      userId: _auth.effectiveUserId,
    );
    if (_auth.isTrialSignedIn) {
      widget.roleController.setRole(_auth.trialRole ?? 'seeker');
      PropertyCareRepository.ensureDemoForTrialOwner();
      PropertyCareNotificationService.instance.init();
    } else {
      widget.roleController.setPerspective(AppPerspective.customer);
    }
    await SessionGate.instance?.markAuthenticated();
    if (!mounted) return;
    if (role == 'admin') {
      if (Env.trialMode && DemoCastSession.hubEnabled) {
        DemoCastSession.instance.activateDefaultCeo(widget.roleController);
      }
      context.go(_adminRedirectAfterAuth() ?? adminHomePath());
      return;
    }
    if (role == 'viewing_staff') {
      context.go(viewingStaffHomePath());
      return;
    }
    await _goAfterAuth();
  }

  Future<void> _enterTrialAs(String role) async {
    final s = AppStrings.of(context);
    if (_requiresRealAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.createListingLoginRequired)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signInAsTrial(role: role);
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

  Future<void> _enterTrial() => _enterTrialAs(_trialRoleForRedirect());

  Future<void> _enterAdminTrial() => _enterTrialAs('admin');

  Future<void> _enterOwnerTrial() => _enterTrialAs('owner');

  Future<void> _submit() async {
    if (_password.text.isEmpty && Env.allowPasswordlessLogin) {
      if (_requiresRealAccount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).createListingLoginRequired)),
        );
        return;
      }
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
    await _oauthMaybeComplete(() async {
      await action();
      return false;
    });
  }

  Future<void> _oauthMaybeComplete(Future<bool> Function() action) async {
    if (!Env.isConfigured) {
      _showSnack(AppStrings.of(context).oauthNotConfigured);
      return;
    }
    setState(() => _loading = true);
    try {
      final completed = await action();
      if (completed && mounted) await _afterAuth();
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
              if (_redirectIsAdmin && Env.allowPasswordlessLogin) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.palette.primary.withOpacity(0.25)),
                  ),
                  child: Text(
                    s.adminHintTrial,
                    textAlign: TextAlign.center,
                    style: authBodyTextStyle(),
                  ),
                ),
              ],
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
                  style: authPrimaryButtonStyle(context),
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
                if (!_redirectIsAdmin) ...[
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _enterTrial,
                      style: AppTheme.pillOutlined.copyWith(
                        side: MaterialStateProperty.all(
                          BorderSide(
                            color: context.palette.primary.withOpacity(0.45),
                          ),
                        ),
                      ),
                      child: Text(
                        s.authQuickEntryFront,
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.palette.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: _loading ? null : _enterAdminTrial,
                    style: authPrimaryButtonStyle(context),
                    child: Text(
                      s.authQuickEntryAdmin,
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _enterOwnerTrial,
                    style: AppTheme.pillOutlined.copyWith(
                      side: MaterialStateProperty.all(
                        BorderSide(
                          color: LivingBkkBrand.peach.withOpacity(0.85),
                        ),
                      ),
                    ),
                    child: Text(
                      s.authQuickEntryOwner,
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LivingBkkBrand.peach,
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
                    color: Colors.black,
                    child: const AppleLogoIcon(size: 22),
                    onTap: _loading
                        ? null
                        : () => _oauthMaybeComplete(_auth.signInWithApple),
                  ),
                  const SizedBox(width: 16),
                  AuthSocialButton(
                    color: const Color(0xFF1877F2),
                    icon: Icons.facebook,
                    iconColor: Colors.white,
                    onTap: _loading
                        ? null
                        : () => _oauth(_auth.signInWithFacebook),
                  ),
                  const SizedBox(width: 16),
                  AuthSocialButton(
                    color: context.palette.surface,
                    border: context.palette.border,
                    child: const GoogleLogoIcon(size: 24),
                    onTap: _loading
                        ? null
                        : () => _oauth(_auth.signInWithGoogle),
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
                  onPressed: () {
                    final redirect = _redirectTarget;
                    if (redirect != null && redirect.isNotEmpty) {
                      context.push(
                        '/signup?redirect=${Uri.encodeComponent(redirect)}',
                      );
                    } else {
                      context.push('/signup');
                    }
                  },
                  child: Text(
                    s.authSignUpFree,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.palette.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: context.palette.primary,
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
