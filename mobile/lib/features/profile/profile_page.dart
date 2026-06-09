import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../models/app_perspective.dart';
import '../contact/contact_tab_page.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../l10n/app_strings.dart';
import '../../state/locale_controller.dart';
import '../../state/session_gate.dart';
import '../../state/theme_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/profile_shell_theme.dart';
import '../../widgets/language_switch_button.dart';
import '../../widgets/theme_mode_switch_button.dart';
import '../../widgets/demand/demand_board_profile_menu.dart';
import '../../widgets/post_listing/post_listing_profile_menu.dart';
import '../../widgets/profile/profile_menu_tile.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.roleController,
    required this.localeController,
    required this.themeController,
  });

  final UserRoleController roleController;
  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploadingAvatar = false;
  bool _deletingAccount = false;

  Future<void> _confirmDeleteAccount(AppStrings s, AuthService auth) async {
    if (!auth.isRealSupabaseSession || _deletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccountTitle),
        content: Text(s.deleteAccountHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.deleteAccountCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await auth.deleteAccount();
      widget.roleController.setPerspective(AppPerspective.customer);
      widget.roleController.setPlatformAdmin(false);
      await SessionGate.instance?.resetToWelcome();
      if (!mounted) return;
      context.go(Env.trialMode ? '/login' : '/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteAccountDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _changeAvatar() async {
    final s = AppStrings(widget.localeController.isEnglish);
    if (!AuthService.instance.isRealSupabaseSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profileAvatarNeedLogin)),
      );
      return;
    }
    setState(() => _uploadingAvatar = true);
    try {
      await UserProfileService.instance.pickAndUploadAvatar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profileAvatarUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _requireLogin(String redirect) {
    context.push('/login?redirect=${Uri.encodeComponent(redirect)}');
  }

  String? _statusLine(AppStrings s, AuthService auth) {
    if (!auth.isSignedIn) {
      if (!Env.isConfigured) return s.demoModeEditEnv;
      if (Env.trialMode) return s.configuredLoginOrTrial;
      return s.profileGuestSubtitle;
    }
    if (auth.isTrialSignedIn && Env.trialMode) {
      return s.statusTrial(auth.trialDisplayName ?? '');
    }
    if (auth.isRealSupabaseSession) {
      if (Env.trialMode) return s.singleAccountSwitchHome;
      return null;
    }
    if (Env.trialMode) return s.configuredLoginOrTrial;
    return null;
  }

  String _displayName(AuthService auth, AppStrings s) {
    final profileName = UserProfileService.instance.displayName;
    if (profileName != null && profileName.isNotEmpty) return profileName;
    final email = auth.displayEmail;
    if (email != null && email.isNotEmpty) {
      final local = email.split('@').first;
      if (local.isNotEmpty) return local;
    }
    if (auth.trialDisplayName?.isNotEmpty == true) {
      return auth.trialDisplayName!;
    }
    return s.testUser;
  }

  String? _badgeLabel(AppStrings s, AuthService auth) {
    if (!auth.isSignedIn) return null;
    if (auth.isTrialSignedIn && Env.trialMode) return s.trialModeStatus;
    return widget.roleController.perspective.label(s.isEnglish);
  }

  Future<void> _signOut(AppStrings s, AuthService auth) async {
    final wasTrial = auth.isTrialSignedIn;
    await auth.signOut();
    widget.roleController.setPerspective(AppPerspective.customer);
    widget.roleController.clearBackOfficeAccess();
    await SessionGate.instance?.resetToWelcome();
    if (!context.mounted) return;
    context.go(Env.trialMode ? '/login' : '/');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasTrial ? s.signedOutTrial : s.signedOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthService.instance,
        UserProfileService.instance,
        widget.roleController,
        widget.localeController,
        widget.themeController,
      ]),
      builder: (context, _) {
        final auth = AuthService.instance;
        final perspective = widget.roleController.perspective;
        final s = AppStrings(widget.localeController.isEnglish);
        final isGuest = !auth.isSignedIn;
        final status = _statusLine(s, auth);
        final badge = _badgeLabel(s, auth);

        return ConsumerPageShell(
          title: s.navProfile,
          safeBottomBody: false,
          body: ListView(
            padding: PageSafeInsets.padLTRB(
              context,
              left: LiLayout.pagePadding,
              top: 12,
              right: LiLayout.pagePadding,
              bottom: 8,
              addHomeIndicator: false,
            ),
            children: [
              _ProfileHeader(
                isGuest: isGuest,
                name: isGuest ? s.profileGuestWelcome : _displayName(auth, s),
                status: status,
                badge: badge,
                avatarUrl: isGuest ? null : UserProfileService.instance.avatarUrl,
                uploadingAvatar: _uploadingAvatar,
                onAvatarTap: auth.isRealSupabaseSession ? _changeAvatar : null,
                onLoginTap: isGuest ? () => context.push('/login') : null,
                loginCtaLabel: s.profileGuestCta,
              ),
              const SizedBox(height: 8),
              if (auth.isSignedIn) ...[
                ProfileMenuTile(
                  icon: Icons.logout_outlined,
                  title: auth.isTrialSignedIn ? s.exitTrial : s.signOut,
                  onTap: () => _signOut(s, auth),
                ),
                const ProfileMenuDivider(),
              ],
              ProfileMenuTile(
                icon: Icons.language_outlined,
                title: s.displayLanguage,
                subtitle: widget.localeController.isEnglish
                    ? s.languageEn
                    : s.languageTh,
                trailing: LanguageSwitchButton(
                  controller: widget.localeController,
                ),
                showChevron: false,
              ),
              const ProfileMenuDivider(),
              ProfileMenuTile(
                icon: Icons.dark_mode_outlined,
                title: s.themeSetting,
                subtitle: widget.themeController.label(s.isEnglish),
                trailing: ThemeModeSwitchButton(
                  controller: widget.themeController,
                ),
                showChevron: false,
              ),
              const ProfileMenuDivider(),
              ProfileMenuTile(
                icon: Icons.favorite_border,
                title: s.savedListingsTitle,
                onTap: isGuest
                    ? () => _requireLogin('/saved-listings')
                    : () => context.push('/saved-listings'),
              ),
              const ProfileMenuDivider(),
              DemandBoardProfileMenu(roleController: widget.roleController),
              PostListingProfileMenu(roleController: widget.roleController),
              if (auth.isSignedIn && perspective == AppPerspective.agent) ...[
                const ProfileMenuDivider(),
                ProfileMenuTile(
                  icon: Icons.calculate_outlined,
                  title: s.agentTools,
                  onTap: () => context.push('/agent-tools'),
                ),
              ],
              if (auth.isSignedIn &&
                  (perspective == AppPerspective.agent ||
                      perspective == AppPerspective.owner)) ...[
                const ProfileMenuDivider(),
                ProfileMenuTile(
                  icon: Icons.real_estate_agent_outlined,
                  title: s.rentalManagementTitle,
                  subtitle: s.rentalManagementIntro,
                  onTap: () => context.push('/rental-management'),
                ),
              ],
              const ProfileMenuDivider(),
              ProfileMenuTile(
                icon: Icons.chat_bubble_outline,
                title: s.contactChat,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactTabPage(),
                  ),
                ),
              ),
              const ProfileMenuDivider(),
              ProfileMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: s.signUpPrivacyLink,
                onTap: () => context.push('/legal/privacy'),
              ),
              const ProfileMenuDivider(),
              ProfileMenuTile(
                icon: Icons.description_outlined,
                title: s.signUpTermsLink,
                onTap: () => context.push('/legal/terms'),
              ),
              if (kIsWeb) ...[
                const ProfileMenuDivider(),
                ProfileMenuTile(
                  icon: Icons.smartphone_outlined,
                  title: s.useOnMobile,
                  subtitle: s.pwaHint,
                  showChevron: false,
                ),
              ],
              if (auth.isRealSupabaseSession) ...[
                const ProfileMenuDivider(),
                ProfileMenuTile(
                  icon: Icons.delete_forever_outlined,
                  title: s.deleteAccount,
                  subtitle: s.deleteAccountHint,
                  showChevron: false,
                  onTap: _deletingAccount
                      ? null
                      : () => _confirmDeleteAccount(s, auth),
                ),
              ],
              SizedBox(height: PageSafeInsets.shellScrollBottom().bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isGuest,
    required this.name,
    this.status,
    this.badge,
    this.avatarUrl,
    this.uploadingAvatar = false,
    this.onAvatarTap,
    this.onLoginTap,
    this.loginCtaLabel,
  });

  final bool isGuest;
  final String name;
  final String? status;
  final String? badge;
  final String? avatarUrl;
  final bool uploadingAvatar;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLoginTap;
  final String? loginCtaLabel;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = ProfileShellTheme.palette(context);
    final textPrimary = p.textPrimary;
    final textSecondary = p.textSecondary;
    final badgeBackground = ProfileShellTheme.badgeBackground(context);
    final accent = ProfileShellTheme.accent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: p.border) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? p.cardShadow : Colors.black.withOpacity(0.04),
            blurRadius: isDark ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                imageUrl: avatarUrl,
                size: 64,
                onTap: uploadingAvatar ? null : onAvatarTap,
              ),
              if (uploadingAvatar)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.35),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              else if (onAvatarTap != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeBackground, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isGuest)
                  Text(
                    s.t('ยินดีต้อนรับกลับ', 'Welcome back,'),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                if (!isGuest) const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: isGuest ? 22 : 26,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: accent.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status != null && status!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    status!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
                if (isGuest && onLoginTap != null && loginCtaLabel != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: onLoginTap,
                      child: Text(loginCtaLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
