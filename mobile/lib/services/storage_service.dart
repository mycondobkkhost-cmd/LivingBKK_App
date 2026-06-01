import 'dart:io';

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
      final ext = file.path.split('.').last;
      final path = '$uid/$listingId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final bytes = await File(file.path).readAsBytes();

      await SupabaseService.client!.storage
          .from('listing-images')
          .uploadBinary(path, bytes);

      final publicUrl = SupabaseService.client!.storage
          .from('listing-images')
          .getPublicUrl(path);

      urls.add(publicUrl);

      await SupabaseService.client!.from('listing_images').insert({
        'listing_id': listingId,
        'storage_path': path,
        'public_url': publicUrl,
        'sort_order': i,
      });
    }

    return urls;
  }
}
