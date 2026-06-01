import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/listing_public.dart';
import '../theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.showCoAgentStrip = false,
    this.onTap,
  });

  final ListingPublic listing;
  final bool showCoAgentStrip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    ).format(listing.priceNet);

    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 140,
                    color: AppTheme.primaryLight,
                    child: const Center(
                      child: Icon(Icons.apartment, size: 48, color: AppTheme.primary),
                    ),
                  ),
                  if (listing.yieldPercent != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Yield ${listing.yieldPercent!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$price${listing.listingType == 'rent' ? '/เดือน' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (listing.projectName != null) listing.projectName,
                        if (listing.district != null) listing.district,
                        if (listing.areaSqm != null) '${listing.areaSqm!.toInt()} ตร.ม.',
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (listing.coAgentListingType == 'owner_direct')
                          _badge('Owner Direct'),
                        if (listing.coAgentListingType == 'co_agent_50_50')
                          _badge('Co-Agent 50/50'),
                        if (listing.investorCategory == 'with_tenant')
                          _badge('พร้อมผู้เช่า'),
                        if (listing.petAllowed) _badge('สัตว์เลี้ยงได้'),
                      ],
                    ),
                    if (showCoAgentStrip && listing.coAgentEligible) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.handshake_outlined, size: 18, color: AppTheme.primary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'เปิดรับโคเอเจ้นท์',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
