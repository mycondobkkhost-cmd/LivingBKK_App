import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'auth_service.dart';
import 'supabase_service.dart';

/// อัปโหลดเอกสารกลุ่มเช่า → bucket `rental-docs`
class RentalStorageService {
  RentalStorageService._();
  static final RentalStorageService instance = RentalStorageService._();

  static const bucket = 'rental-docs';

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  /// คืน storage path ใน bucket (ไม่ใช่ public URL — bucket private)
  Future<String?> uploadDocument({
    required String leaseId,
    required String fileName,
    required List<int> bytes,
  }) async {
    if (!_live || leaseId.startsWith('demo-')) return null;
    if (bytes.isEmpty) return null;

    final safeName = _safeFileName(fileName);
    final uid = AuthService.instance.effectiveUserId ?? 'unknown';
    final path = '$leaseId/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await SupabaseService.client!.storage.from(bucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: false),
          );
      return path;
    } catch (e) {
      debugPrint('RentalStorageService.uploadDocument: $e');
      rethrow;
    }
  }

  Future<String?> signedUrl(String storagePath, {int expiresInSeconds = 3600}) async {
    if (!_live || storagePath.isEmpty) return null;
    try {
      return await SupabaseService.client!.storage
          .from(bucket)
          .createSignedUrl(storagePath, expiresInSeconds);
    } catch (e) {
      debugPrint('RentalStorageService.signedUrl: $e');
      return null;
    }
  }

  String _safeFileName(String name) {
    final base = name.split('/').last.split('\\').last.trim();
    if (base.isEmpty) return 'document.bin';
    return base.replaceAll(RegExp(r'[^\w.\-()ก-๙\s]'), '_');
  }
}
