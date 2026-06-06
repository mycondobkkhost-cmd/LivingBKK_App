import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../services/listing_repository.dart';

/// เปิดหน้ารายละเอียดทรัพย์จากหลังบ้าน (รองรับทั้ง id และ listing_code)
Future<void> openAdminListing(
  BuildContext context, {
  String? listingId,
  String? listingCode,
}) async {
  final s = AppStrings.of(context);
  final repo = ListingRepository();
  var id = listingId?.trim();
  if ((id == null || id.isEmpty) && listingCode != null && listingCode.isNotEmpty) {
    id = await repo.resolveIdByCode(listingCode);
  }
  if (!context.mounted) return;
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminListingNotFound)),
    );
    return;
  }
  context.push('/listing/$id');
}
