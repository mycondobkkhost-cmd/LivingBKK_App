class ChatLearnedAnswer {
  const ChatLearnedAnswer({
    required this.id,
    required this.topicKey,
    required this.questionExample,
    required this.answerGuidance,
    required this.scope,
    this.propertyType,
    this.listingId,
    this.useCount = 0,
    this.isActive = true,
    this.updatedAt,
  });

  final String id;
  final String topicKey;
  final String questionExample;
  final String answerGuidance;
  /// global | property_type | listing
  final String scope;
  final String? propertyType;
  final String? listingId;
  final int useCount;
  final bool isActive;
  final DateTime? updatedAt;

  ChatLearnedAnswer copyWith({
    String? topicKey,
    String? questionExample,
    String? answerGuidance,
    String? scope,
    String? propertyType,
    bool? isActive,
  }) {
    return ChatLearnedAnswer(
      id: id,
      topicKey: topicKey ?? this.topicKey,
      questionExample: questionExample ?? this.questionExample,
      answerGuidance: answerGuidance ?? this.answerGuidance,
      scope: scope ?? this.scope,
      propertyType: propertyType ?? this.propertyType,
      listingId: listingId,
      useCount: useCount,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic_key': topicKey,
        'question_example': questionExample,
        'answer_guidance': answerGuidance,
        'scope': scope,
        if (propertyType != null) 'property_type': propertyType,
        if (listingId != null) 'listing_id': listingId,
        'use_count': useCount,
        'is_active': isActive,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory ChatLearnedAnswer.fromJson(Map<String, dynamic> j) {
    return ChatLearnedAnswer(
      id: j['id']?.toString() ?? '',
      topicKey: j['topic_key']?.toString() ?? '',
      questionExample: j['question_example']?.toString() ?? '',
      answerGuidance: j['answer_guidance']?.toString() ?? '',
      scope: j['scope']?.toString() ?? 'global',
      propertyType: j['property_type']?.toString(),
      listingId: j['listing_id']?.toString(),
      useCount: (j['use_count'] as num?)?.toInt() ?? 0,
      isActive: j['is_active'] != false,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
    );
  }
}
