import '../models/chat_message.dart';
import '../models/profile_tag.dart';
import '../services/profile_tag_repository.dart';

/// แปลง @SP-2026-000101 ในแชท → ลิงก์แท็ก
abstract final class TagMentionUtils {
  static final mentionPattern = RegExp(
    r'@(SP|CL|PR)-2026-\d{6}',
    caseSensitive: false,
  );

  static final bareTagPattern = RegExp(
    r'\b(SP|CL|PR)-2026-\d{6}\b',
    caseSensitive: false,
  );

  static List<String> extractMentionCodes(String text) {
    final codes = <String>[];
    for (final m in mentionPattern.allMatches(text)) {
      codes.add(m.group(0)!.substring(1).toUpperCase());
    }
    return codes;
  }

  static Future<List<ChatMessageLink>> buildLinksForText(String text) async {
    final codes = extractMentionCodes(text);
    if (codes.isEmpty) return const [];

    final links = <ChatMessageLink>[];
    final seen = <String>{};
    for (final raw in codes) {
      if (!seen.add(raw)) continue;
      ProfileTag? tag = ProfileTagRepository.instance.tagByCode(raw);
      tag ??= await ProfileTagRepository.instance.fetchTagByCode(raw);
      links.add(
        ChatMessageLink.profileTag(
          raw,
          tag?.displayLabel ?? raw,
        ),
      );
    }
    return links;
  }

  static List<({int start, int end, String code})> mentionSpans(String text) {
    return mentionPattern
        .allMatches(text)
        .map(
          (m) => (
            start: m.start,
            end: m.end,
            code: m.group(0)!.substring(1).toUpperCase(),
          ),
        )
        .toList();
  }
}
