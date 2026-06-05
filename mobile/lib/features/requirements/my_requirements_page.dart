import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../widgets/listing_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myRequirementsTitle),
        actions: [
          TextButton(
            onPressed: () => DemandBoardNavigation.openCreateRequirement(context),
            child: Text(s.requirementCreateCta),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: reqRepo,
        builder: (context, _) {
          final items = reqRepo.listForDisplay();
          final showingDemo = reqRepo.isShowingDemo;

          return ListView(
            padding: const EdgeInsets.all(16),
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
        ? const []
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
              ...matches.take(3).map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListingCard(
                        listing: l,
                        style: ListingCardStyle.list,
                        onTap: () => context.push(
                          '/listing/${l.id}',
                          extra: ListingRouteExtra(listing: l, isAgent: false),
                        ),
                      ),
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
