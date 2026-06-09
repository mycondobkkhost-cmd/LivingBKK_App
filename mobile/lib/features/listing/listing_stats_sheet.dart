import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/listing_activity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_insights_strip.dart';

Future<void> showListingStatsSheet(
  BuildContext context, {
  required Map<String, dynamic> row,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _StatsSheet(row: row),
  );
}

class _StatsSheet extends StatelessWidget {
  const _StatsSheet({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final id = row['id']?.toString() ?? '';
    final activity = ListingActivityService.instance;
    final views = activity.viewCount(id);
    final shares = activity.shareCount(id);
    final chats = activity.chatCount(id);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.listingAnalytics,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            row['title']?.toString() ?? row['listing_code']?.toString() ?? '',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statTile('$views', s.listingInsightViews)),
              Expanded(child: _statTile('$shares', s.listingInsightShares)),
              Expanded(child: _statTile('$chats', s.listingInsightChats)),
            ],
          ),
          const SizedBox(height: 12),
          ListingInsightsStrip(listingId: id),
          const SizedBox(height: 8),
          Text(
            s.listingStatsSheetHint,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
