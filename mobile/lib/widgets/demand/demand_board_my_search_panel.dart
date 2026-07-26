import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/demand_board_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../models/customer_requirement.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/customer_requirement_repository.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../demand/demand_urgent_rush_strip.dart';

/// แท็บ「ที่ฉันหา」— คำขอหาทรัพย์ของลูกค้าพร้อมสถานะบนบอร์ด
class DemandBoardMySearchPanel extends StatefulWidget {
  const DemandBoardMySearchPanel({super.key});

  @override
  State<DemandBoardMySearchPanel> createState() =>
      _DemandBoardMySearchPanelState();
}

class _DemandBoardMySearchPanelState extends State<DemandBoardMySearchPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomerRequirementRepository.instance.refreshFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final repo = CustomerRequirementRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final items = repo.listForDisplay();
        final showingDemo = repo.isShowingDemo;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.manage_search_outlined,
                    size: 48,
                    color: context.palette.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.demandBoardMySearchEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: PageSafeInsets.padLTRB(
            context,
            left: LiLayout.pagePadding,
            top: 12,
            right: LiLayout.pagePadding,
            bottom: 80,
            addHomeIndicator: false,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            return DemandMySearchCard(
              requirement: items[i],
              isDemo: showingDemo,
            );
          },
        );
      },
    );
  }
}

class DemandMySearchCard extends StatelessWidget {
  const DemandMySearchCard({
    super.key,
    required this.requirement,
    this.isDemo = false,
  });

  final CustomerRequirement requirement;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final created = requirement.createdAt;
    final dateLabel = created != null
        ? DateFormat('d MMM yyyy', 'th').format(created)
        : null;

    return Material(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: p.border.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    requirement.localizedTitle(s.isEnglish),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: LiLayout.homeCardSubtitle,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                if (requirement.urgentRush) ...[
                  const RequirementUrgentChip(),
                  const SizedBox(width: 6),
                ],
                _StatusChip(
                  label: requirement.statusLabel(s.isEnglish),
                  palette: p,
                ),
              ],
            ),
            if (requirement.notes != null &&
                requirement.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                requirement.notes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
            ],
            if (dateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                s.requirementSubmittedOn(dateLabel),
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
            ],
            if (requirement.demandPostCode != null) ...[
              const SizedBox(height: 8),
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
                      Icon(Icons.campaign_outlined, size: 14, color: p.primary),
                      const SizedBox(width: 4),
                      Text(
                        s.requirementBoardCodeLabel(requirement.demandPostCode!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.primary,
                        ),
                      ),
                      if (requirement.demandPostId != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: p.primary),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (!isDemo && !requirement.savedToDatabase) ...[
              const SizedBox(height: 8),
              Text(
                s.requirementLocalOnlyNote,
                style: TextStyle(fontSize: 11, color: AppTheme.accentMid),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isDemo
                  ? null
                  : () => DemandBoardNavigation.openMyRequirements(context),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: Text(s.myRequirementsTitle),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.primary,
                side: BorderSide(color: p.primary.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.palette});

  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: palette.primary,
        ),
      ),
    );
  }
}
