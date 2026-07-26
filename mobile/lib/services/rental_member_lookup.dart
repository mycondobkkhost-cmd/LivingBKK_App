import '../data/hub_demo_data.dart';
import '../models/profile_tag.dart';
import 'auth_service.dart';
import 'profile_tag_repository.dart';
import 'supabase_service.dart';

class RentalMemberLookupResult {
  const RentalMemberLookupResult({
    required this.userId,
    required this.displayLabelHint,
    this.profileTagCode,
  });

  final String userId;
  final String displayLabelHint;
  final String? profileTagCode;
}

/// ค้นหาผู้ใช้สำหรับเพิ่มสมาชิกกลุ่มเช่า — แท็ก / UUID / demo
class RentalMemberLookup {
  RentalMemberLookup._();

  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _tagRe = RegExp(
    r'^(SP|CL|PR)-2026-\d{6}$',
    caseSensitive: false,
  );

  static bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  static Future<RentalMemberLookupResult?> resolve(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    if (_tagRe.hasMatch(q.toUpperCase())) {
      final tag = await ProfileTagRepository.instance.fetchTagByCode(q.toUpperCase());
      if (tag == null) return null;
      return RentalMemberLookupResult(
        userId: tag.ownerUserId,
        profileTagCode: tag.code,
        displayLabelHint: _labelFromTag(tag),
      );
    }

    if (_uuidRe.hasMatch(q)) {
      if (_live) {
        try {
          final row = await SupabaseService.client!
              .from('profiles')
              .select('id, display_name')
              .eq('id', q)
              .maybeSingle();
          if (row != null) {
            final map = Map<String, dynamic>.from(row);
            final name = map['display_name']?.toString().trim();
            return RentalMemberLookupResult(
              userId: q,
              displayLabelHint: name?.isNotEmpty == true ? name! : q,
            );
          }
        } catch (_) {}
      }
      return RentalMemberLookupResult(userId: q, displayLabelHint: q);
    }

    final demoId = HubDemoData.resolveUserId(q);
    if (demoId != null) {
      for (final row in HubDemoData.demoUserDirectory) {
        if (row.$2 == demoId) {
          return RentalMemberLookupResult(
            userId: demoId,
            displayLabelHint: row.$1,
          );
        }
      }
      return RentalMemberLookupResult(userId: demoId, displayLabelHint: demoId);
    }

    return null;
  }

  static String _labelFromTag(ProfileTag tag) {
    final name = tag.subjectDisplayName?.trim().isNotEmpty == true
        ? tag.subjectDisplayName!.trim()
        : tag.label.trim();
    return name.isNotEmpty ? name : tag.code;
  }
}
