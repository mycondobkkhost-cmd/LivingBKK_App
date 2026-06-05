import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../models/app_perspective.dart';
import '../contact/contact_tab_page.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_strings.dart';
import '../../state/locale_controller.dart';
import '../../state/session_gate.dart';
import '../../state/theme_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/profile_shell_theme.dart';
import '../../widgets/language_switch_button.dart';
import '../../widgets/demand/demand_board_profile_menu.dart';
import '../../widgets/post_listing/post_listing_profile_menu.dart';
import '../../widgets/profile/profile_menu_tile.dart';

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
  String _statusLine(AppStrings s, AuthService auth) {
    if (auth.isTrialSignedIn) {
      return s.statusTrial(auth.trialDisplayName ?? '');
    }
    if (!Env.isConfigured) return s.demoModeEditEnv;
    if (auth.isRealSupabaseSession) return s.singleAccountSwitchHome;
    if (Env.trialMode) return s.configuredLoginOrTrial;
    return s.configuredNotLoggedIn;
  }

  String _displayName(AuthService auth, AppStrings s) {
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

  String _badgeLabel(AppStrings s, AuthService auth) {
    if (auth.isTrialSignedIn) return s.t('โหมดทดลอง', 'Trial mode');
    return widget.roleController.perspective.label(s.isEnglish);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthService.instance,
        widget.roleController,
        widget.localeController,
        widget.themeController,
      ]),
      builder: (context, _) {
        final auth = AuthService.instance;
        final perspective = widget.roleController.perspective;
        final s = AppStrings(widget.localeController.isEnglish);

        return Scaffold(
          backgroundColor: ProfileShellTheme.background(context),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: _displayName(auth, s),
                  status: _statusLine(s, auth),
                  badge: _badgeLabel(s, auth),
                ),
                Expanded(
                  child: ListView(
                    children: [
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
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: widget.themeController.mode,
                            dropdownColor: ProfileShellTheme.surface(context),
                            style: TextStyle(
                              color: ProfileShellTheme.textPrimary(context),
                              fontSize: 13,
                            ),
                            icon: Icon(
                              Icons.expand_more,
                              color: ProfileShellTheme.textSecondary(context),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(s.themeLight),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(s.themeDark),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(s.themeSystem),
                              ),
                            ],
                            onChanged: (m) {
                              if (m != null) widget.themeController.setMode(m);
                            },
                          ),
                        ),
                        showChevron: false,
                      ),
                      const ProfileMenuDivider(),
                      ProfileMenuTile(
                        icon: Icons.favorite_border,
                        title: s.savedListingsTitle,
                        onTap: () => context.push('/saved-listings'),
                      ),
                      const ProfileMenuDivider(),
                      ProfileMenuTile(
                        icon: Icons.swap_horiz,
                        title: s.perspectiveLabel,
                        subtitle: perspective.label(s.isEnglish),
                        onTap: () => context.go('/'),
                      ),
                      const ProfileMenuDivider(),
                      DemandBoardProfileMenu(roleController: widget.roleController),
                      PostListingProfileMenu(roleController: widget.roleController),
                      ProfileMenuTile(
                        icon: Icons.notifications_active_outlined,
                        title: s.notifications,
                        subtitle: auth.isSignedIn && Env.isConfigured
                            ? Env.firebaseEnabled
                                ? s.notificationsRealtimeFcm
                                : s.notificationsPartial
                            : s.notificationsDemo,
                        showChevron: false,
                      ),
                      const ProfileMenuDivider(),
                      ProfileMenuTile(
                        icon: Icons.bookmark_outline,
                        title: s.savedSearchTitle,
                        onTap: () => context.push('/saved-searches'),
                      ),
                      if (perspective == AppPerspective.agent) ...[
                        const ProfileMenuDivider(),
                        ProfileMenuTile(
                          icon: Icons.calculate_outlined,
                          title: s.agentTools,
                          onTap: () => context.push('/agent-tools'),
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
                      if (kIsWeb) ...[
                        const ProfileMenuDivider(),
                        ProfileMenuTile(
                          icon: Icons.smartphone_outlined,
                          title: s.useOnMobile,
                          subtitle: s.pwaHint,
                          showChevron: false,
                        ),
                      ],
                      const ProfileMenuDivider(),
                      ProfileMenuTile(
                        icon: Icons.menu_book_outlined,
                        title: s.setupGuide,
                        subtitle: s.setupGuidePaths,
                        onTap: () {},
                      ),
                      if (Env.trialMode || Env.isConfigured) ...[
                        const ProfileMenuDivider(),
                        if (!auth.isSignedIn)
                          ProfileMenuTile(
                            icon: Icons.login_outlined,
                            title: Env.trialMode ? s.loginOrTrial : s.loginOrSignUp,
                            onTap: () => context.push('/login'),
                          )
                        else
                          ProfileMenuTile(
                            icon: Icons.logout_outlined,
                            title: auth.isTrialSignedIn ? s.exitTrial : s.signOut,
                            onTap: () async {
                              final wasTrial = auth.isTrialSignedIn;
                              await auth.signOut();
                              widget.roleController
                                  .setPerspective(AppPerspective.customer);
                              widget.roleController.setPlatformAdmin(false);
                              await SessionGate.instance?.resetToWelcome();
                              if (context.mounted) {
                                context.go('/login');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      wasTrial ? s.signedOutTrial : s.signedOut,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.status,
    required this.badge,
  });

  final String name;
  final String status;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final textPrimary = ProfileShellTheme.textPrimary(context);
    final textSecondary = ProfileShellTheme.textSecondary(context);
    final badgeBackground = ProfileShellTheme.badgeBackground(context);
    final accent = ProfileShellTheme.accent(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ProfileShellTheme.horizontalPadding,
        20,
        ProfileShellTheme.horizontalPadding,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: badgeBackground,
            child: Icon(
              Icons.person_outline,
              size: 36,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('ยินดีต้อนรับกลับ', 'Welcome back,'),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          badge,
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
                const SizedBox(height: 6),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
