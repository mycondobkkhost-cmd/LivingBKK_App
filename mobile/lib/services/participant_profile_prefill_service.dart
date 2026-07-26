import '../models/participant_profile_data.dart';
import '../models/profile_tag.dart';
import 'auth_service.dart';
import 'profile_tag_repository.dart';
import 'supabase_service.dart';

/// เติมโปรไฟล์มาตรฐานจากแท็กล่าสุด / บัญชีแอป
class ParticipantProfilePrefillService {
  ParticipantProfilePrefillService._();
  static final instance = ParticipantProfilePrefillService._();

  Future<ParticipantProfileData> load({
    ProfileTagRole role = ProfileTagRole.seekerSelf,
    ProfileTag? existingTag,
    String applicantType = 'seeker_self',
  }) async {
    final data = ParticipantProfileData(applicantType: applicantType);

    if (existingTag != null) {
      data.applyFromTag(existingTag);
      return data;
    }

    await ProfileTagRepository.instance.ensureLoaded();
    final latest = ProfileTagRepository.instance.latestTag(role: role);
    if (latest != null) {
      data.applyFromTag(latest);
      return data;
    }

    await _applyAccountProfile(data);
    return data;
  }

  Future<void> _applyAccountProfile(ParticipantProfileData data) async {
    if (!SupabaseService.isReady) return;
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null) return;

    try {
      final row = await SupabaseService.client!
          .from('profiles')
          .select('display_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return;
      final map = Map<String, dynamic>.from(row as Map);
      final name = map['display_name']?.toString().trim();
      final phone = map['phone']?.toString().trim();
      if (name != null && name.isNotEmpty && data.nickname.isEmpty) {
        data.nickname = name;
      }
      if (phone != null && phone.isNotEmpty && data.phone.isEmpty) {
        data.phone = phone;
      }
    } catch (_) {}
  }

  Future<ParticipantProfileData> loadCoAgentPair({
    ProfileTag? clientTag,
    ProfileTag? presenterTag,
  }) async {
    final data = await load(
      applicantType: 'co_agent_request',
      role: ProfileTagRole.clientSubject,
      existingTag: clientTag,
    );

    if (presenterTag != null) {
      data.applyFromTag(presenterTag);
    } else {
      final pr = ProfileTagRepository.instance.latestTag(
        role: ProfileTagRole.coAgentPresenter,
      );
      if (pr != null) data.applyFromTag(pr);
    }

    return data;
  }
}
