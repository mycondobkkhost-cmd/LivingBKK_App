import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/listing_public.dart';
import '../../theme/app_theme.dart';
import '../contact/lead_bot_sheet.dart';

class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({super.key, required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0)
        .format(listing.priceNet);

    return Scaffold(
      appBar: AppBar(title: Text(listing.listingCode)),
      body: ListView(
        children: [
          Container(
            height: 220,
            color: AppTheme.primaryLight,
            child: const Center(
              child: Icon(Icons.photo_library_outlined, size: 64, color: AppTheme.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$price${listing.listingType == 'rent' ? '/เดือน' : ''}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('แผนที่โซนโดยประมาณ\n(ไม่แสดงเลขห้อง/ชั้น)'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  [
                    if (listing.bedrooms != null) '${listing.bedrooms} ห้องนอน',
                    if (listing.areaSqm != null) '${listing.areaSqm!.toInt()} ตร.ม.',
                  ].join(' · '),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => showLeadBotSheet(context, listingCode: listing.listingCode),
                    child: const Text('สอบถาม / นัดเข้าชมทรัพย์'),
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
