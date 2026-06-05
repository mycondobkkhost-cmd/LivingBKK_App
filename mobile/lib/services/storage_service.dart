import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';

import 'supabase_service.dart';

class StorageService {
  final _picker = ImagePicker();

  Future<List<XFile>> pickImages({int max = 8}) async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    return files.take(max).toList();
  }

  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<XFile> files,
  }) async {
    if (!SupabaseService.isReady) {
      throw Exception('ต้องล็อกอินและตั้งค่า Supabase');
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = _extension(file);
      final path = '$uid/$listingId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final bytes = await file.readAsBytes();

      await SupabaseService.client!.storage
          .from('listing-images')
          .uploadBinary(path, bytes);

      final publicUrl = SupabaseService.client!.storage
          .from('listing-images')
          .getPublicUrl(path);

      urls.add(publicUrl);

      final hash = _perceptualHash(bytes);

      await SupabaseService.client!.from('listing_images').insert({
        'listing_id': listingId,
        'storage_path': path,
        'public_url': publicUrl,
        'sort_order': i,
        'perceptual_hash': hash,
        'moderation_status': 'pending',
      });

      try {
        await SupabaseService.client!.functions.invoke(
          'image-dedup-check',
          body: {'listing_id': listingId, 'perceptual_hash': hash},
        );
      } catch (_) {}
    }

    return urls;
  }

  String _perceptualHash(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes.take(16).toList());
  }

  Future<void> uploadDemandOfferImages({
    required String offerId,
    required List<XFile> files,
  }) async {
    if (!SupabaseService.isReady) {
      throw Exception('ต้องล็อกอินและตั้งค่า Supabase');
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = _extension(file);
      final path = '$uid/$offerId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final bytes = await file.readAsBytes();

      await SupabaseService.client!.storage
          .from('demand-offers')
          .uploadBinary(path, bytes);

      final publicUrl = SupabaseService.client!.storage
          .from('demand-offers')
          .getPublicUrl(path);

      await SupabaseService.client!.from('demand_offer_images').insert({
        'demand_offer_id': offerId,
        'storage_path': path,
        'public_url': publicUrl,
        'sort_order': i,
      });
    }
  }

  String _extension(XFile file) {
    final parts = file.name.split('.');
    if (parts.length > 1) return parts.last.toLowerCase();
    return 'jpg';
  }
}
