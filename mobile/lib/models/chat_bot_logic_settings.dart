class ChatBotLogicSettings {
  const ChatBotLogicSettings({
    this.voiceExtraRules = '',
    this.unclearEscalateThreshold = 2,
    this.coachWhenLowConfidence = true,
    this.strategyHints = const {},
  });

  final String voiceExtraRules;
  final int unclearEscalateThreshold;
  final bool coachWhenLowConfidence;
  final Map<String, String> strategyHints;

  static const strategyKeys = [
    'build_trust',
    'answer_question',
    'invite_viewing',
    'collect_requirement',
    'close_ready',
    'negotiate_soft',
  ];

  ChatBotLogicSettings copyWith({
    String? voiceExtraRules,
    int? unclearEscalateThreshold,
    bool? coachWhenLowConfidence,
    Map<String, String>? strategyHints,
  }) {
    return ChatBotLogicSettings(
      voiceExtraRules: voiceExtraRules ?? this.voiceExtraRules,
      unclearEscalateThreshold:
          unclearEscalateThreshold ?? this.unclearEscalateThreshold,
      coachWhenLowConfidence:
          coachWhenLowConfidence ?? this.coachWhenLowConfidence,
      strategyHints: strategyHints ?? this.strategyHints,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice_extra_rules': voiceExtraRules,
        'unclear_escalate_threshold': unclearEscalateThreshold,
        'coach_when_low_confidence': coachWhenLowConfidence,
        'strategy_hints': strategyHints,
      };

  factory ChatBotLogicSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return const ChatBotLogicSettings();
    final hintsRaw = j['strategy_hints'];
    final hints = <String, String>{};
    if (hintsRaw is Map) {
      for (final e in hintsRaw.entries) {
        hints[e.key.toString()] = e.value?.toString() ?? '';
      }
    }
    return ChatBotLogicSettings(
      voiceExtraRules: j['voice_extra_rules']?.toString() ?? '',
      unclearEscalateThreshold:
          (j['unclear_escalate_threshold'] as num?)?.toInt().clamp(1, 5) ?? 2,
      coachWhenLowConfidence: j['coach_when_low_confidence'] != false,
      strategyHints: hints.isEmpty ? _defaultHints : hints,
    );
  }

  static const _defaultHints = {
    'build_trust': 'ทักทายอบอุ่น ไม่เร่งขาย ชวนถามต่ออย่างนุ่มนวล',
    'answer_question': 'ตอบคำถามให้ครบก่อน แล้วค่อยชวนนัดดู',
    'invite_viewing': 'ลูกค้าสนใจแล้ว — ชวนนัดดูชัด ไม่กดดัน',
    'collect_requirement': 'ทรัพย์นี้อาจไม่ fit — ชวนกรอกฟอร์มช่วยหาห้อง',
    'close_ready': 'ลูกค้าพร้อมปิด — สรุปขั้นตอนถัดไปชัดเจน',
    'negotiate_soft': 'ราคา Net แล้ว — ถ้าจริงจังหลังนัดดู แอดมินช่วยคุยเจ้าของ',
  };

  static ChatBotLogicSettings defaults() {
    return ChatBotLogicSettings(strategyHints: Map.from(_defaultHints));
  }
}
