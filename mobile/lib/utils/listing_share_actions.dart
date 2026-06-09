import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../utils/localized_content.dart';
import '../models/listing_public.dart';

class ListingShareActions {
  static String listingUrl(ListingPublic listing) {
    final origin = kIsWeb ? Uri.base.origin : null;
    final url = Env.listingShareUrl(listing.id, origin: origin);
    if (url.startsWith('http')) return url;
    if (kIsWeb && origin != null && origin.isNotEmpty) return '$origin$url';
    return 'https://realxtateth.com$url';
  }

  static String shareText(ListingPublic listing, {bool isEnglish = false}) {
    final s = AppStrings(isEnglish);
    final type = s.listingTransactionLabel(listing.listingType);
    return 'RealXtate · ${listing.listingCode}\n'
        '${listing.localizedTitle(isEnglish)}\n'
        '฿${listing.priceNet.toStringAsFixed(0)} ($type)\n'
        '${listingUrl(listing)}';
  }

  static Future<void> shareLink(ListingPublic listing, {bool isEnglish = false}) async {
    await Share.share(
      shareText(listing, isEnglish: isEnglish),
      subject: listing.localizedTitle(isEnglish),
    );
  }

  static Future<void> downloadAllPhotos(
    BuildContext context,
    ListingPublic listing,
  ) async {
    final s = AppStrings.of(context);
    final urls = listing.imageUrls;
    if (urls.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.noPhotosToShare)),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.preparingPhotos(urls.length))),
      );
    }

    try {
      final files = <XFile>[];
      for (var i = 0; i < urls.length; i++) {
        final res = await http.get(Uri.parse(urls[i]));
        if (res.statusCode != 200) continue;
        files.add(XFile.fromData(
          res.bodyBytes,
          name: '${listing.listingCode}_${i + 1}.jpg',
          mimeType: 'image/jpeg',
        ));
      }
      if (files.isEmpty) throw Exception(s.downloadPhotosFailed);
      await Share.shareXFiles(
        files,
        text: s.sharePhotosText(listing.listingCode),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.savePhotosFailed('$e'))),
        );
      }
    }
  }

  static Future<void> copyLink(BuildContext context, ListingPublic listing) async {
    final s = AppStrings.of(context);
    await Clipboard.setData(ClipboardData(text: shareText(listing, isEnglish: s.isEnglish)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.linkCopied)),
      );
    }
  }
}
