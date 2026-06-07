import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// รูปโฆษณาหน้าแรก — รองรับ JPEG/PNG/WebP/GIF (รวม GIF แอนิเมชัน)
class PromoImageUtil {
  PromoImageUtil._();

  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

  /// เลือกไฟล์รูป/ GIF โดยไม่บีบอัดเป็น JPEG (หลีกเลี่ยง imageQuality)
  static Future<XFile?> pickPromoImage(ImagePicker picker) async {
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    final media = await picker.pickMedia();
    if (media != null && isAllowedPromoFile(media)) return media;

    var file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      final multi = await picker.pickMultiImage();
      if (multi.isNotEmpty) file = multi.first;
    }
    if (file != null && !isAllowedPromoFile(file)) return null;
    return file;
  }

  static bool isAllowedPromoFile(XFile file) {
    return allowedExtensions.contains(extension(file));
  }

  static String extension(XFile file) {
    final parts = file.name.split('.');
    if (parts.length > 1) return parts.last.toLowerCase();
    final pathParts = file.path.split('.');
    if (pathParts.length > 1) return pathParts.last.toLowerCase();
    return 'jpg';
  }

  static String mimeTypeForExtension(String ext) {
    switch (ext) {
      case 'gif':
        return 'image/gif';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  static bool isGifBytes(Uint8List bytes) {
    if (bytes.length < 6) return false;
    return bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
  }

  static bool isGifUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.gif');
  }

  static bool isAnimatedPromo({
    Uint8List? memoryBytes,
    String? imageUrl,
  }) {
    if (memoryBytes != null && memoryBytes.isNotEmpty) {
      return isGifBytes(memoryBytes);
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return isGifUrl(imageUrl);
    }
    return false;
  }
}
