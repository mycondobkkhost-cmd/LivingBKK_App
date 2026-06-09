/// แท็กโปรไฟล์นัดดู — แยกจากบัญชีแอป · immutable (แก้ = เวอร์ชันใหม่)
enum ProfileTagRole {
  seekerSelf,
  coAgentPresenter,
  clientSubject,
}

extension ProfileTagRoleCodes on ProfileTagRole {
  String get codePrefix => switch (this) {
        ProfileTagRole.seekerSelf => 'SP',
        ProfileTagRole.coAgentPresenter => 'PR',
        ProfileTagRole.clientSubject => 'CL',
      };
}

class ProfileTag {
  const ProfileTag({
    required this.id,
    required this.code,
    required this.role,
    required this.version,
    required this.label,
    required this.snapshot,
    required this.ownerUserId,
    required this.createdAt,
    this.subjectDisplayName,
  });

  final String id;
  final String code;
  final ProfileTagRole role;
  final int version;
  final String label;
  final Map<String, String> snapshot;
  final String ownerUserId;
  final DateTime createdAt;
  final String? subjectDisplayName;

  /// สำหรับเจ้าของ — ไม่มีเบอร์/Line
  Map<String, String> get publicSnapshot {
    const hidden = {'phone', 'line', 'เบอร์', 'โทร', 'Line', 'summaryPhone'};
    return Map.fromEntries(
      snapshot.entries.where((e) => !hidden.contains(e.key)),
    );
  }

  String get displayLabel =>
      subjectDisplayName != null && subjectDisplayName!.isNotEmpty
          ? '$label · $subjectDisplayName'
          : label;
}
