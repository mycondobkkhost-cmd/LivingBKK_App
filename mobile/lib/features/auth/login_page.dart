import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../theme/brand_assets.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_routing.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../widgets/language_switch_button.dart';
import '../../widgets/legal_policy_rich_text.dart';
import 'auth_form_widgets.dart';
import 'phone_login_sheet.dart';

/// หน้าเข้าสู่ระบบ — โครงตาม mock (โทร / Google / Apple / LINE) · ธีม RealXtate
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
  bool _showEmailForm = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

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
    if (redirect != null && redirect.isNotEmpty && _auth.canCreateListing) {
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

  Future<void> _submitEmail() async {
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

  Future<void> _continueWithLine() async {
    if (!Env.isConfigured) {
      _showSnack(AppStrings.of(context).oauthNotConfigured);
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = await _auth.lineOAuthUri();
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack(AppStrings.of(context).oauthNotConfigured);
      }
    } catch (e) {
      if (mounted) _showSnack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPhoneLogin() async {
    if (!Env.isConfigured && !Env.allowPasswordlessLogin) {
      _showSnack(AppStrings.of(context).configureSupabaseFirst);
      return;
    }
    if (!Env.isConfigured) {
      _showSnack(AppStrings.of(context).oauthNotConfigured);
      return;
    }
    await PhoneLoginSheet.show(context, onVerified: _afterAuth);
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
        final p = context.palette;
        final mq = MediaQuery.of(context);
        final topInset = mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;

        return AppMobileScaffold(
          backgroundColor: p.surface,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // โซนแดงด้านบน
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: mq.size.height * 0.34,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            right: -30,
                            child: _orb(160, 0.14),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -40,
                            child: _orb(120, 0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, topInset > 0 ? 0 : 4, 12, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                            const Spacer(),
                            LanguageSwitchButton(
                              controller: widget.localeController,
                              light: true,
                              hero: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              AuthCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Center(child: _BrandMark()),
                                    const SizedBox(height: 14),
                                    Text(
                                      s.authCreateOrSignIn,
                                      textAlign: TextAlign.center,
                                      style: authTitleTextStyle(),
                                    ),
                                    if (_redirectIsAdmin && Env.allowPasswordlessLogin) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: p.primaryLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          s.adminHintTrial,
                                          textAlign: TextAlign.center,
                                          style: authBodyTextStyle(),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 22),
                                    AuthContinueButton(
                                      filled: true,
                                      enabled: !_loading,
                                      label: s.authContinueWithPhone,
                                      leading: const PhoneLogoIcon(size: 22, color: Colors.white),
                                      onTap: _openPhoneLogin,
                                    ),
                                    const SizedBox(height: 18),
                                    _OrDivider(label: s.authOrDivider),
                                    const SizedBox(height: 18),
                                    AuthContinueButton(
                                      enabled: !_loading,
                                      label: s.authContinueWithGoogle,
                                      leading: const GoogleLogoIcon(size: 22),
                                      onTap: () => _oauth(_auth.signInWithGoogle),
                                    ),
                                    const SizedBox(height: 10),
                                    AuthContinueButton(
                                      enabled: !_loading,
                                      label: s.authContinueWithApple,
                                      leading: const AppleLogoIcon(size: 24, color: Colors.black),
                                      onTap: () => _oauthMaybeComplete(_auth.signInWithApple),
                                    ),
                                    const SizedBox(height: 10),
                                    AuthContinueButton(
                                      enabled: !_loading,
                                      label: s.authContinueWithLine,
                                      leading: const LineLogoIcon(size: 24),
                                      onTap: _continueWithLine,
                                    ),
                                    if (_showEmailForm) ...[
                                      const SizedBox(height: 20),
                                      AuthFormField(
                                        controller: _email,
                                        label: s.authEmailOrUsername,
                                        hint: s.authEmailOrUsername,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 12),
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
                                          child: Text(s.forgotPassword, style: authBodyTextStyle()),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: _loading ? null : _submitEmail,
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
                                    ] else ...[
                                      const SizedBox(height: 14),
                                      TextButton(
                                        onPressed: () => setState(() => _showEmailForm = true),
                                        child: Text(
                                          s.authEmailSignInLink,
                                          style: authLinkStyle(color: p.primary),
                                        ),
                                      ),
                                    ],
                                    if (Env.allowPasswordlessLogin) ...[
                                      const SizedBox(height: 4),
                                      if (!_redirectIsAdmin)
                                        TextButton(
                                          onPressed: _loading ? null : _enterTrial,
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                          ),
                                          child: Text(
                                            s.authQuickEntryFront,
                                            style: authBodyTextStyle(
                                              color: AppTheme.textSecondary,
                                              weight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      TextButton(
                                        onPressed: _loading ? null : _enterAdminTrial,
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                        ),
                                        child: Text(
                                          s.authQuickEntryAdmin,
                                          style: authBodyTextStyle(
                                            color: AppTheme.textSecondary,
                                            weight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _loading ? null : _enterOwnerTrial,
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                        ),
                                        child: Text(
                                          s.authQuickEntryOwner,
                                          style: authBodyTextStyle(
                                            color: AppTheme.textSecondary,
                                            weight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              LegalPolicyRichText(
                                s: s,
                                prefix: '${s.authLegalFooterPrefix} ',
                                middle: ' ${s.signUpTermsAnd} ',
                                suffix: s.authLegalFooterOf.isEmpty ? '' : ' ${s.authLegalFooterOf}',
                                fontSize: 12,
                              ),
                              const SizedBox(height: 8),
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
                                  style: authLinkStyle(color: p.primary).copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Color(0x11000000),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: p.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: p.primary.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.asset(
          BrandAssets.logoMark,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: context.palette.border, thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: authBodyTextStyle()),
        ),
        line,
      ],
    );
  }
}
