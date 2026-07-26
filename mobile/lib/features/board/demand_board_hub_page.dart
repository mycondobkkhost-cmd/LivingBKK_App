import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/board/demand_board_page.dart';
import '../../l10n/app_strings.dart';
import '../../models/demand_board_hub_section.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/auth_service.dart';
import '../../shell/main_shell_scope.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../widgets/demand/demand_board_my_search_panel.dart';

/// แท็บ「บอร์ด」— กดครั้งเดียว แล้วเลือก 2 ฟังก์ชันย่อย
class DemandBoardHubPage extends StatefulWidget {
  const DemandBoardHubPage({
    super.key,
    this.isShellTab = false,
    this.initialSection = DemandBoardHubSection.landing,
    this.fromHomeEntry = false,
  });

  final bool isShellTab;
  final DemandBoardHubSection initialSection;
  final bool fromHomeEntry;

  @override
  State<DemandBoardHubPage> createState() => _DemandBoardHubPageState();
}

class _DemandBoardHubPageState extends State<DemandBoardHubPage> {
  late DemandBoardHubSection _section = widget.initialSection;

  @override
  void didUpdateWidget(covariant DemandBoardHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSection != oldWidget.initialSection &&
        widget.initialSection != DemandBoardHubSection.landing) {
      _section = widget.initialSection;
    }
  }

  void _goLanding() => setState(() => _section = DemandBoardHubSection.landing);

  void _openFeed() => setState(() => _section = DemandBoardHubSection.feed);

  void _openLooking() =>
      setState(() => _section = DemandBoardHubSection.looking);

  String _greetingName(AppStrings s) {
    final auth = AuthService.instance;
    final trial = auth.trialDisplayName?.trim();
    if (trial != null && trial.isNotEmpty) return trial;
    final email = (auth.displayEmail ?? '').trim();
    if (email.contains('@')) return email.split('@').first;
    if (email.isNotEmpty && !email.contains('Demo')) return email;
    return LivingBkkBrand.name;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_section) {
      DemandBoardHubSection.landing => _LandingView(
          isShellTab: widget.isShellTab,
          greetingName: _greetingName(AppStrings.of(context)),
          onOpenFeed: _openFeed,
          onOpenLooking: _openLooking,
        ),
      DemandBoardHubSection.feed => DemandBoardPage(
          isShellTab: widget.isShellTab,
          fromHomeEntry: widget.fromHomeEntry,
          onBackToHub: _goLanding,
        ),
      DemandBoardHubSection.looking => _LookingSection(
          isShellTab: widget.isShellTab,
          onBack: _goLanding,
        ),
    };
  }
}

class _LandingView extends StatelessWidget {
  const _LandingView({
    required this.isShellTab,
    required this.greetingName,
    required this.onOpenFeed,
    required this.onOpenLooking,
  });

  final bool isShellTab;
  final String greetingName;
  final VoidCallback onOpenFeed;
  final VoidCallback onOpenLooking;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final top = PageSafeInsets.top(context);
    final headerTop = top >= 50 ? top + 8.0 : (top > 0 ? top + 6.0 : 12.0);

    return AppMobileScaffold(
      backgroundColor: LivingBkkBrand.pageBackgroundOf(context),
      safeBottomBody: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LivingBkkBrand.brandRedDark.withOpacity(0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LiLayout.pagePadding,
                  headerTop,
                  LiLayout.pagePadding,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isShellTab)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () =>
                                MainShellScope.maybeOf(context)?.selectTab(0),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            s.demandBoardHubGreeting(greetingName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.prompt(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              DemandBoardNavigation.openSavedBoard(context),
                          icon: const Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.demandBoardHubTitle,
                      style: GoogleFonts.prompt(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.demandBoardHubSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.demandBoardHubPolicyNote,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: PageSafeInsets.padLTRB(
                  context,
                  left: 16,
                  top: 20,
                  right: 16,
                  bottom: 88,
                  addHomeIndicator: false,
                ),
                children: [
                  Text(
                    s.demandBoardHubChoose,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HubOptionCard(
                    icon: Icons.campaign_rounded,
                    iconBg: LivingBkkBrand.brandRedTint,
                    iconColor: LivingBkkBrand.brandRed,
                    title: s.demandBoardHubFeedTitle,
                    body: s.demandBoardHubFeedBody,
                    badge: s.demandBoardHubFeedBadge,
                    onTap: onOpenFeed,
                  ),
                  const SizedBox(height: 12),
                  _HubOptionCard(
                    icon: Icons.manage_search_rounded,
                    iconBg: const Color(0xFFFFF0E6),
                    iconColor: LivingBkkBrand.accentOrange,
                    title: s.demandBoardHubLookingTitle,
                    body: s.demandBoardHubLookingBody,
                    badge: s.demandBoardHubLookingBadge,
                    onTap: onOpenLooking,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubOptionCard extends StatelessWidget {
  const _HubOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border.withOpacity(0.9)),
            boxShadow: LivingBkkBrand.warmCardShadow(opacity: 0.08),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LookingSection extends StatelessWidget {
  const _LookingSection({
    required this.isShellTab,
    required this.onBack,
  });

  final bool isShellTab;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final top = PageSafeInsets.top(context);
    final headerTop = top >= 50 ? top + 6.0 : (top > 0 ? top + 4.0 : 10.0);

    return AppMobileScaffold(
      backgroundColor: LivingBkkBrand.pageBackgroundOf(context),
      safeBottomBody: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DemandBoardNavigation.openCreateRequirement(context),
        backgroundColor: LivingBkkBrand.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.demandBoardHubLookingCta),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                LiLayout.pagePadding,
                headerTop,
                LiLayout.pagePadding,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: onBack,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.demandBoardHubLookingTitle,
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            DemandBoardNavigation.openMyRequirements(context),
                        child: Text(s.myRequirementsTitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: LivingBkkBrand.brandRedTint,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () =>
                          DemandBoardNavigation.openCreateRequirement(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: LivingBkkBrand.brandRed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.demandBoardComposeHint,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    s.demandBoardHubLookingBody,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: LivingBkkBrand.brandRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DemandBoardMySearchPanel(
              key: ValueKey(isShellTab),
            ),
          ),
        ],
      ),
    );
  }
}
