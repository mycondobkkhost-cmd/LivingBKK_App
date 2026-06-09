import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/calendar_event.dart';
import '../../theme/admin_theme.dart';
import '../../theme/living_bkk_brand.dart';

class AdminCalendarEventCard extends StatelessWidget {
  const AdminCalendarEventCard({
    super.key,
    required this.event,
    required this.s,
    required this.onTap,
    this.onConfirm,
    this.busy = false,
  });

  final CalendarEvent event;
  final AppStrings s;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final bool busy;

  Color get _accent {
    if (event.isAiDraft) return LivingBkkBrand.purplePrimary;
    switch (event.colorHint) {
      case 'blue':
        return Colors.lightBlue.shade700;
      case 'green':
        return Colors.green.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: event.isAiDraft
          ? LivingBkkBrand.purplePrimary.withOpacity(0.06)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (event.isAiDraft)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: LivingBkkBrand.purplePrimary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.adminCalendarAiDraftBadge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: LivingBkkBrand.purplePrimary,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.timeSlotLabel} · ${event.locationLabel ?? event.listingCode ?? '—'}',
                          style: AdminTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.description != null &&
                  event.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption.copyWith(fontSize: 11),
                ),
              ],
              if (event.fieldLocks.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  s.adminCalendarHumanLockedCount(event.fieldLocks.length),
                  style: AdminTheme.caption.copyWith(
                    fontSize: 10,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
              if (event.isAiDraft && onConfirm != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: busy ? null : onConfirm,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(s.adminCalendarConfirmAiDraft),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
