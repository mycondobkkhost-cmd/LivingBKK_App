import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../services/admin_repository.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// แอดมิน — ดาวน์โหลดรูปต้นฉบับจาก Storage (ไม่มีลายน้ำ)
class AdminListingImageDownload {
  static Future<void> downloadOriginals(
    BuildContext context, {
    required String listingId,
    required String listingCode,
  }) async {
    final s = AppStrings.of(context);
    final admin = AdminRepository();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminDownloadOriginalsPreparing)),
      );
    }

    try {
      final files = <XFile>[];

      if (AuthService.instance.trialSimulatesBackend || !SupabaseService.isReady) {
        final preview = await admin.fetchListingForPublicPreview(listingId);
        final urls = preview?.imageUrls ?? [];
        if (urls.isEmpty) throw Exception(s.noPhotosToShare);
        for (var i = 0; i < urls.length; i++) {
          final res = await http.get(Uri.parse(urls[i]));
          if (res.statusCode != 200) continue;
          files.add(XFile.fromData(
            res.bodyBytes,
            name: '${listingCode}_original_${i + 1}.jpg',
            mimeType: 'image/jpeg',
          ));
        }
      } else {
        final rows = await admin.listingImageOriginals(listingId);
        if (rows.isEmpty) throw Exception(s.noPhotosToShare);
        for (var i = 0; i < rows.length; i++) {
          final path = rows[i]['storage_path']?.toString() ?? '';
          if (path.isEmpty) continue;
          final bytes = await SupabaseService.client!.storage
              .from('listing-images')
              .download(path);
          final ext = path.contains('.') ? path.split('.').last : 'jpg';
          files.add(XFile.fromData(
            bytes,
            name: '${listingCode}_original_${i + 1}.$ext',
            mimeType: _mimeForExt(ext),
          ));
        }
      }

      if (files.isEmpty) throw Exception(s.downloadPhotosFailed);
      if (!context.mounted) return;
      await Share.shareXFiles(
        files,
        text: s.adminDownloadOriginalsShareText(listingCode),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.savePhotosFailed('$e'))),
        );
      }
    }
  }

  static String _mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
