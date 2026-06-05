import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import 'property_chat_page.dart';

/// เปิดแชท AI ต่อทรัพย์ (ไม่เก็บข้อมูลลูกค้าจนกด "ขอนัดดูห้อง")
void showLeadBotSheet(
  BuildContext context, {
  String? listingCode,
  String? listingId,
  ListingPublic? listing,
}) {
  if (listing != null) {
    openPropertyChat(context, listing);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppStrings.of(context).chatSelectListingFirst)),
  );
}
