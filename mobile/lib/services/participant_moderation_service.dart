import 'package:flutter/foundation.dart';

/// ตั้งค่าบัญชีผู้ใช้ — in-memory (รอ DB)
class ParticipantModerationState {
  const ParticipantModerationState({
    this.notificationsMuted = false,
    this.flaggedDisruptive = false,
    this.suspended = false,
    this.suspendReason,
  });

  final bool notificationsMuted;
  final bool flaggedDisruptive;
  final bool suspended;
  final String? suspendReason;

  ParticipantModerationState copyWith({
    bool? notificationsMuted,
    bool? flaggedDisruptive,
    bool? suspended,
    String? suspendReason,
  }) {
    return ParticipantModerationState(
      notificationsMuted: notificationsMuted ?? this.notificationsMuted,
      flaggedDisruptive: flaggedDisruptive ?? this.flaggedDisruptive,
      suspended: suspended ?? this.suspended,
      suspendReason: suspendReason ?? this.suspendReason,
    );
  }
}

class ParticipantModerationService extends ChangeNotifier {
  ParticipantModerationService._();
  static final instance = ParticipantModerationService._();

  final _state = <String, ParticipantModerationState>{};

  ParticipantModerationState stateFor(String userId) =>
      _state[userId] ?? const ParticipantModerationState();

  void setMuted(String userId, bool muted) {
    _state[userId] = stateFor(userId).copyWith(notificationsMuted: muted);
    notifyListeners();
  }

  void setFlagged(String userId, bool flagged) {
    _state[userId] = stateFor(userId).copyWith(flaggedDisruptive: flagged);
    notifyListeners();
  }

  void setSuspended(String userId, bool suspended, {String? reason}) {
    _state[userId] = stateFor(userId).copyWith(
      suspended: suspended,
      suspendReason: reason,
    );
    notifyListeners();
  }
}
