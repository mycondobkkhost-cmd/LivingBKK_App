/// ข้อความในห้องทดลองเทรนบอท (หลังบ้าน)
enum ChatBotSandboxMessageKind {
  customer,
  bot,
  coach,
  system,
}

/// บทบาทลูกค้าในแชททดลอง
enum ChatBotSandboxPersona {
  seeker,
  coAgent,
  owner,
}

class ChatBotSandboxMessage {
  const ChatBotSandboxMessage({
    required this.id,
    required this.kind,
    required this.text,
    required this.at,
    this.source,
    this.sourceLabel,
    this.persona,
    this.customerQuestion,
    this.reviewPassed,
    this.appliedTraining,
  });

  final String id;
  final ChatBotSandboxMessageKind kind;
  final String text;
  final DateTime at;
  final String? source;
  final String? sourceLabel;
  final ChatBotSandboxPersona? persona;
  final String? customerQuestion;
  final bool? reviewPassed;
  final String? appliedTraining;

  ChatBotSandboxMessage copyWith({
    bool? reviewPassed,
    String? appliedTraining,
  }) {
    return ChatBotSandboxMessage(
      id: id,
      kind: kind,
      text: text,
      at: at,
      source: source,
      sourceLabel: sourceLabel,
      persona: persona,
      customerQuestion: customerQuestion,
      reviewPassed: reviewPassed ?? this.reviewPassed,
      appliedTraining: appliedTraining ?? this.appliedTraining,
    );
  }
}

enum ChatBotSandboxRole {
  customer,
  coach,
}
