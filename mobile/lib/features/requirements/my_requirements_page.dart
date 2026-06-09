import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/demand_board_menu_config.dart';
import '../../data/demo_listings_factory.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../l10n/app_strings.dart';
import '../../models/customer_requirement.dart';
import '../../models/listing_route_extra.dart';
import '../../models/listing_public.dart';
import '../../services/customer_requirement_repository.dart';
import '../../services/listing_repository.dart';
import '../../services/requirement_match_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/demand/demand_urgent_rush_strip.dart';
import '../../widgets/listing_grid.dart';
import '../contact/property_chat_page.dart';
import '../../services/chat_service.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class MyRequirementsPage extends StatefulWidget {
  const MyRequirementsPage({super.key});

  @override
  State<MyRequirementsPage> createState() => _MyRequirementsPageState();
}

class _MyRequirementsPageState extends State<MyRequirementsPage> {
  final _repo = ListingRepository();
  List<dynamic> _pool = [];
  bool _loadingPool = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomerRequirementRepository.instance.refreshFromServer();
    });
  }

  Future<void> _loadPool() async {
    try {
      _pool = await _repo.fetchPublished();
    } catch (_) {
      _pool = DemoListingsFactory.cached;
    }
    if (mounted) setState(() => _loadingPool = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final reqRepo = CustomerRequirementRepository.instance;

    return ConsumerPageShell(
      title: s.myRequirementsTitle,
      onBack: () => context.pop(),
      actions: [
        ConsumerHeaderTextButton(
          label: s.requirementCreateCta,
          onTap: () => DemandBoardNavigation.openCreateRequirement(context),
        ),
      ],
      body: ListenableBuilder(
        listenable: reqRepo,
        builder: (context, _) {
          final items = reqRepo.listForDisplay();
          final showingDemo = reqRepo.isShowingDemo;

          return ListView(
            padding: PageSafeInsets.padLTRB(
              context,
              left: LiLayout.pagePadding,
              top: LiLayout.pagePadding,
              right: LiLayout.pagePadding,
              bottom: 16,
              addHomeIndicator: false,
            ),
            children: [
              Card(
                color: AppTheme.accentDeepLight,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    s.requirementListIntro,
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
              ),
              if (showingDemo)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Text(
                    '(${s.demoSampleLabel})',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ...items.map(
                (r) => _RequirementCard(
                  requirement: r,
                  isDemo: showingDemo,
                  pool: _pool,
                  loadingPool: _loadingPool,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => DemandBoardNavigation.openCreateRequirement(context),
                icon: const Icon(Icons.add),
                label: Text(s.requirementCreateCta),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.requirement,
    required this.isDemo,
    required this.pool,
    required this.loadingPool,
  });

  final CustomerRequirement requirement;
  final bool isDemo;
  final List<dynamic> pool;
  final bool loadingPool;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final created = requirement.createdAt;
    final dateLabel = created != null
        ? DateFormat('d MMM yyyy', 'th').format(created)
        : null;
    final matches = loadingPool
        ? <ListingPublic>[]
        : RequirementMatchService.instance.match(
            req: requirement,
            pool: pool.cast<ListingPublic>(),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    requirement.localizedTitle(s.isEnglish),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (requirement.urgentRush) ...[
                  const RequirementUrgentChip(),
                  const SizedBox(width: 6),
                ],
                _StatusChip(label: requirement.statusLabel(s.isEnglish)),
              ],
            ),
            if (requirement.notes != null && requirement.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                requirement.notes!,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            if (dateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                s.requirementSubmittedOn(dateLabel),
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
            if (requirement.demandPostCode != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: requirement.demandPostId != null
                    ? () => context.push(
                          DemandBoardMenuConfig.boardDetailRoute(
                            requirement.demandPostId!,
                          ),
                        )
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.requirementBoardCodeLabel(requirement.demandPostCode!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (requirement.demandPostId != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: AppTheme.primary),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isDemo
                  ? null
                  : () async {
                      final room = await ChatService.instance
                          .openRequirementChat(requirement);
                      if (!context.mounted || room == null) return;
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PropertyChatPage(room: room),
                        ),
                      );
                    },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(s.requirementOpenChat),
            ),
            if (!isDemo && !requirement.savedToDatabase) ...[
              const SizedBox(height: 8),
              Text(
                s.requirementLocalOnlyNote,
                style: TextStyle(fontSize: 11, color: AppTheme.accentMid),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              s.lookingToMatch,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (loadingPool)
              const LinearProgressIndicator(minHeight: 2)
            else if (matches.isEmpty)
              Text(
                s.t('ยังไม่พบทรัพย์ตรงเงื่อนไขในระบบ', 'No matching listings yet'),
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              )
            else ...[
              Text(
                s.matchCount(matches.length),
                style: TextStyle(fontSize: 12, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              ListingGrid(
                items: matches.take(6).toList(),
                showFavorite: false,
                onTapListing: (l) => context.push(
                  '/listing/${l.id}',
                  extra: ListingRouteExtra(listing: l, isAgent: false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
