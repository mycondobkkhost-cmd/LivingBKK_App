import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// โปรไฟล์ผู้ใช้ — รูป / ชื่อที่แสดง (cache + อัปโหลด)
class UserProfileService extends ChangeNotifier {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final _picker = ImagePicker();

  String? _avatarUrl;
  String? _displayName;
  bool _loaded = false;

  String? get avatarUrl => _avatarUrl;
  String? get displayName => _displayName;
  bool get loaded => _loaded;

  void bindAuth() {
    AuthService.instance.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (!AuthService.instance.isRealSupabaseSession) {
      clear();
      return;
    }
    load();
  }

  void clear() {
    _avatarUrl = null;
    _displayName = null;
    _loaded = false;
    notifyListeners();
  }

  Future<void> load() async {
    final auth = AuthService.instance;
    if (!auth.isRealSupabaseSession || !SupabaseService.isReady) {
      clear();
      return;
    }

    final user = auth.currentUser!;
    try {
      final row = await SupabaseService.client!
          .from('profiles')
          .select('avatar_url, display_name')
          .eq('id', user.id)
          .maybeSingle();

      _avatarUrl = _nonEmpty(row?['avatar_url']?.toString()) ??
          _nonEmpty(user.userMetadata?['avatar_url']?.toString()) ??
          _nonEmpty(user.userMetadata?['picture']?.toString());

      _displayName = _nonEmpty(row?['display_name']?.toString()) ??
          _nonEmpty(user.userMetadata?['display_name']?.toString()) ??
          _nonEmpty(user.userMetadata?['full_name']?.toString());
    } catch (_) {
      _avatarUrl = _nonEmpty(user.userMetadata?['picture']?.toString());
      _displayName = _nonEmpty(user.userMetadata?['display_name']?.toString());
    }

    _loaded = true;
    notifyListeners();
  }

  String? _nonEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<void> pickAndUploadAvatar() async {
    if (!AuthService.instance.isRealSupabaseSession) {
      throw Exception('ต้องล็อกอินก่อนอัปโหลดรูปโปรไฟล์');
    }
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    var file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (file == null) {
      final multi = await _picker.pickMultiImage(imageQuality: 88);
      if (multi.isNotEmpty) file = multi.first;
    }
    if (file == null) return;
    await uploadAvatarFile(file);
  }

  Future<String> uploadAvatarFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadAvatarBytes(bytes, filename: file.name);
  }

  Future<String> uploadAvatarBytes(
    Uint8List bytes, {
    String filename = 'avatar.jpg',
  }) async {
    if (!SupabaseService.isReady || AuthService.instance.trialSimulatesBackend) {
      throw Exception('ต้องเชื่อมต่อ Supabase และล็อกอินจริง');
    }
    final uid = AuthService.instance.currentUser!.id;
    final ext = _extension(filename);
    final path = '$uid/avatar.$ext';

    await SupabaseService.client!.storage.from('profile-avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final baseUrl = SupabaseService.client!.storage
        .from('profile-avatars')
        .getPublicUrl(path);
    final publicUrl = '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await SupabaseService.client!
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', uid);

    _avatarUrl = publicUrl;
    _loaded = true;
    notifyListeners();
    return publicUrl;
  }

  String _extension(String name) {
    final parts = name.split('.');
    if (parts.length > 1) {
      final ext = parts.last.toLowerCase();
      if (ext == 'png' || ext == 'webp' || ext == 'jpg' || ext == 'jpeg') {
        return ext == 'jpeg' ? 'jpg' : ext;
      }
    }
    return 'jpg';
  }
}
