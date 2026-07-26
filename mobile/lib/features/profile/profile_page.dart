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
import '../../theme/living_bkk_brand.dart';
import '../../theme/profile_shell_theme.dart';
import '../../widgets/language_switch_button.dart';
import '../../widgets/theme_mode_switch_button.dart';
import '../../widgets/demand/demand_board_profile_menu.dart';
import '../../widgets/post_listing/post_listing_profile_menu.dart';
import '../../widgets/profile/profile_menu_tile.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../navigation/post_listing_navigation.dart';

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
      return auth.displayEmail;
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

  void _showProfileSummary(AppStrings s, AuthService auth) {
    final name = _displayName(auth, s);
    final badge = _badgeLabel(s, auth);
    final status = _statusLine(s, auth);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('โปรไฟล์ของฉัน', 'My profile'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ProfileAvatar(
                      imageUrl: UserProfileService.instance.avatarUrl,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              badge,
                              style: TextStyle(
                                color: LivingBkkBrand.brandRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (status != null && status.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: ProfileShellTheme.textSecondary(ctx),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
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

        final demandTiles = DemandBoardProfileMenu(
          roleController: widget.roleController,
          asTilesOnly: true,
        ).buildTiles(context);
        final postTiles = PostListingProfileMenu(
          roleController: widget.roleController,
          asTilesOnly: true,
        ).buildTiles(context);

        final activityTiles = <Widget>[
          ProfileMenuTile(
            icon: Icons.favorite_rounded,
            title: s.savedListingsTitle,
            iconColor: LivingBkkBrand.brandRed,
            iconBackground: LivingBkkBrand.brandRedTint,
            accentChevron: true,
            onTap: isGuest
                ? () => _requireLogin('/saved-listings')
                : () => context.push('/saved-listings'),
          ),
          ...demandTiles,
          ...postTiles,
          if (auth.isSignedIn && perspective == AppPerspective.agent)
            ProfileMenuTile(
              icon: Icons.calculate_outlined,
              title: s.agentTools,
              iconColor: LivingBkkBrand.servicePurple,
              iconBackground: const Color(0xFFF3ECFB),
              accentChevron: true,
              onTap: () => context.push('/agent-tools'),
            ),
          if (auth.isSignedIn &&
              (perspective == AppPerspective.agent ||
                  perspective == AppPerspective.owner))
            ProfileMenuTile(
              icon: Icons.real_estate_agent_outlined,
              title: s.rentalManagementTitle,
              subtitle: s.rentalManagementIntro,
              iconColor: LivingBkkBrand.serviceGreen,
              iconBackground: const Color(0xFFE8F7F1),
              accentChevron: true,
              onTap: () => context.push('/rental-management'),
            ),
        ];

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
                avatarUrl:
                    isGuest ? null : UserProfileService.instance.avatarUrl,
                uploadingAvatar: _uploadingAvatar,
                onAvatarTap: auth.isRealSupabaseSession ? _changeAvatar : null,
                onViewProfile: isGuest
                    ? () => context.push('/login')
                    : () => _showProfileSummary(s, auth),
                onEditProfile: isGuest
                    ? () => context.push('/login')
                    : (auth.isRealSupabaseSession
                        ? _changeAvatar
                        : () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.profileAvatarNeedLogin)),
                            )),
                onLoginTap: isGuest ? () => context.push('/login') : null,
                loginCtaLabel: s.profileGuestCta,
                viewLabel: s.t('ดูโปรไฟล์', 'View profile'),
                editLabel: s.t('แก้ไขโปรไฟล์', 'Edit profile'),
              ),
              const SizedBox(height: 14),
              _QuickActionRow(
                leftTitle: s.savedListingsTitle,
                leftSubtitle: s.t('ทรัพย์ที่บันทึกไว้', 'Your saved homes'),
                leftCta: s.t('ดูรายการ', 'View list'),
                leftIcon: Icons.favorite_rounded,
                leftColor: LivingBkkBrand.brandRed,
                onLeft: isGuest
                    ? () => _requireLogin('/saved-listings')
                    : () => context.push('/saved-listings'),
                rightTitle: s.t('ลงประกาศฟรี', 'Post for free'),
                rightSubtitle: s.t(
                  'ปล่อยเช่า / ขาย ฟรี',
                  'List rent or sale free',
                ),
                rightCta: s.t('เริ่มโพสต์', 'Start posting'),
                rightIcon: Icons.add_home_work_rounded,
                rightColor: LivingBkkBrand.accentOrange,
                onRight: () =>
                    PostListingNavigation.openCreateWithAuthGate(context),
              ),
              const SizedBox(height: 18),
              ProfileMenuSection(
                title: s.t('เมนูของฉัน', 'My menu'),
                children: activityTiles,
              ),
              const SizedBox(height: 18),
              ProfileMenuSection(
                title: s.t('ตั้งค่าบัญชี', 'Account settings'),
                children: [
                  ProfileMenuTile(
                    icon: Icons.language_outlined,
                    title: s.displayLanguage,
                    subtitle: widget.localeController.isEnglish
                        ? s.languageEn
                        : s.languageTh,
                    iconColor: LivingBkkBrand.servicePurple,
                    iconBackground: const Color(0xFFF3ECFB),
                    trailing: LanguageSwitchButton(
                      controller: widget.localeController,
                    ),
                    showChevron: false,
                  ),
                  ProfileMenuTile(
                    icon: Icons.dark_mode_outlined,
                    title: s.themeSetting,
                    subtitle: widget.themeController.label(s.isEnglish),
                    iconColor: LivingBkkBrand.navy,
                    iconBackground: const Color(0xFFEEEEEE),
                    trailing: ThemeModeSwitchButton(
                      controller: widget.themeController,
                    ),
                    showChevron: false,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ProfileMenuSection(
                title: s.t('อื่นๆ', 'Other'),
                children: [
                  ProfileMenuTile(
                    icon: Icons.headset_mic_outlined,
                    title: s.contactChat,
                    iconColor: LivingBkkBrand.brandRed,
                    iconBackground: LivingBkkBrand.brandRedTint,
                    accentChevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactTabPage(),
                      ),
                    ),
                  ),
                  if (auth.isRealSupabaseSession)
                    ProfileMenuTile(
                      icon: Icons.remove_circle_outline,
                      title: s.deleteAccount,
                      subtitle: s.deleteAccountHint,
                      iconColor: LivingBkkBrand.brandRedDark,
                      iconBackground: LivingBkkBrand.brandRedTint,
                      showChevron: false,
                      destructive: true,
                      onTap: _deletingAccount
                          ? null
                          : () => _confirmDeleteAccount(s, auth),
                    ),
                  if (kIsWeb)
                    ProfileMenuTile(
                      icon: Icons.smartphone_outlined,
                      title: s.useOnMobile,
                      subtitle: s.pwaHint,
                      iconColor: LivingBkkBrand.serviceGreen,
                      iconBackground: const Color(0xFFE8F7F1),
                      showChevron: false,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ProfileMenuSection(
                title: s.t(
                  'เงื่อนไขและความเป็นส่วนตัว',
                  'Terms & privacy',
                ),
                children: [
                  ProfileMenuTile(
                    icon: Icons.menu_book_outlined,
                    title: s.t('คู่มือการใช้งาน', 'User guide'),
                    iconColor: LivingBkkBrand.accentOrange,
                    iconBackground: const Color(0xFFFFF4E8),
                    accentChevron: true,
                    onTap: () => context.push('/legal/terms'),
                  ),
                  ProfileMenuTile(
                    icon: Icons.lock_outline_rounded,
                    title: s.t(
                      'จัดการข้อมูลความเป็นส่วนตัว',
                      'Manage privacy',
                    ),
                    iconColor: LivingBkkBrand.navy,
                    iconBackground: const Color(0xFFEEEEEE),
                    accentChevron: true,
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  ProfileMenuTile(
                    icon: Icons.description_outlined,
                    title: s.signUpTermsLink,
                    iconColor: LivingBkkBrand.servicePurple,
                    iconBackground: const Color(0xFFF3ECFB),
                    accentChevron: true,
                    onTap: () => context.push('/legal/terms'),
                  ),
                  ProfileMenuTile(
                    icon: Icons.shield_outlined,
                    title: s.signUpPrivacyLink,
                    iconColor: LivingBkkBrand.serviceGreen,
                    iconBackground: const Color(0xFFE8F7F1),
                    accentChevron: true,
                    onTap: () => context.push('/legal/privacy'),
                  ),
                ],
              ),
              if (auth.isSignedIn) ...[
                const SizedBox(height: 22),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _signOut(s, auth),
                    icon: Icon(
                      Icons.logout_rounded,
                      color: LivingBkkBrand.brandRed,
                      size: 20,
                    ),
                    label: Text(
                      auth.isTrialSignedIn ? s.exitTrial : s.signOut,
                      style: const TextStyle(
                        color: LivingBkkBrand.brandRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'App version 1.0.0 (1)',
                  style: TextStyle(
                    color: ProfileShellTheme.textSecondary(context)
                        .withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: PageSafeInsets.shellScrollBottom().bottom + 12),
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
    this.onViewProfile,
    this.onEditProfile,
    this.onLoginTap,
    this.loginCtaLabel,
    required this.viewLabel,
    required this.editLabel,
  });

  final bool isGuest;
  final String name;
  final String? status;
  final String? badge;
  final String? avatarUrl;
  final bool uploadingAvatar;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onViewProfile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLoginTap;
  final String? loginCtaLabel;
  final String viewLabel;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final p = ProfileShellTheme.palette(context);
    final textPrimary = p.textPrimary;
    final textSecondary = p.textSecondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: p.border) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? p.cardShadow : Colors.black.withOpacity(0.04),
            blurRadius: isDark ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                          color: LivingBkkBrand.brandRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.surface, width: 2),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (!isGuest) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: LivingBkkBrand.serviceGreen,
                          ),
                        ],
                      ],
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LivingBkkBrand.brandRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (status != null && status!.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
                  ],
                ),
              ),
            ],
          ),
          if (isGuest && onLoginTap != null && loginCtaLabel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onLoginTap,
                style: FilledButton.styleFrom(
                  backgroundColor: LivingBkkBrand.brandRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(loginCtaLabel!),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeaderActionButton(
                    label: viewLabel,
                    onTap: onViewProfile,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderActionButton(
                    label: editLabel,
                    onTap: onEditProfile,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = ProfileShellTheme.palette(context);
    return Material(
      color: p.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: p.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.leftTitle,
    required this.leftSubtitle,
    required this.leftCta,
    required this.leftIcon,
    required this.leftColor,
    required this.onLeft,
    required this.rightTitle,
    required this.rightSubtitle,
    required this.rightCta,
    required this.rightIcon,
    required this.rightColor,
    required this.onRight,
  });

  final String leftTitle;
  final String leftSubtitle;
  final String leftCta;
  final IconData leftIcon;
  final Color leftColor;
  final VoidCallback onLeft;
  final String rightTitle;
  final String rightSubtitle;
  final String rightCta;
  final IconData rightIcon;
  final Color rightColor;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _QuickCard(
            title: leftTitle,
            subtitle: leftSubtitle,
            cta: leftCta,
            icon: leftIcon,
            color: leftColor,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            title: rightTitle,
            subtitle: rightSubtitle,
            cta: rightCta,
            icon: rightIcon,
            color: rightColor,
            onTap: onRight,
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ProfileShellTheme.palette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: p.border) : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? p.cardShadow
                    : Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    child: Text(cta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
