import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/listing_activity_service.dart';
import '../theme/app_theme.dart';

/// สถิติประกาศบนอุปกรณ์ — views / แชร์ / เริ่มแชท
class ListingInsightsStrip extends StatelessWidget {
  const ListingInsightsStrip({
    super.key,
    required this.listingId,
    this.compact = false,
  });

  final String listingId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final activity = ListingActivityService.instance;
    final views = activity.viewCount(listingId);
    final shares = activity.shareCount(listingId);
    final chats = activity.chatCount(listingId);
    final hasData = views > 0 || shares > 0 || chats > 0;

    if (!hasData) {
      return Padding(
        padding: EdgeInsets.only(top: compact ? 4 : 6),
        child: Text(
          s.listingInsightsEmpty,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _chip(Icons.visibility_outlined, s.listingViews(views)),
          if (shares > 0) _chip(Icons.ios_share, s.listingShares(shares)),
          if (chats > 0) _chip(Icons.chat_bubble_outline, s.listingChats(chats)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// สรุปพอร์ตประกาศทั้งหมด
class ListingPortfolioSummary extends StatelessWidget {
  const ListingPortfolioSummary({
    super.key,
    required this.listingIds,
    required this.publishedCount,
  });

  final List<String> listingIds;
  final int publishedCount;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final activity = ListingActivityService.instance;
    var views = 0;
    var shares = 0;
    var chats = 0;
    for (final id in listingIds) {
      views += activity.viewCount(id);
      shares += activity.shareCount(id);
      chats += activity.chatCount(id);
    }

    return Card(
      color: AppTheme.primaryLight.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.listingAnalytics,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.listingPortfolioHint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat('$publishedCount', s.listingPortfolioActive)),
                Expanded(child: _stat('$views', s.listingInsightViews)),
                Expanded(child: _stat('$chats', s.listingInsightChats)),
              ],
            ),
            if (shares > 0) ...[
              const SizedBox(height: 8),
              Text(
                s.listingShares(shares),
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
