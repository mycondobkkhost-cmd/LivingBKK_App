/// Mirror supabase/functions/_shared/chat_text_normalize.ts (subset for mobile routing).
library;

const _typoCanonical = <String, String>{
  'มั้ย': 'ไหม',
  'ป่าว': 'เปล่า',
  'นัดดุ': 'นัดดู',
  'นัดชมม': 'นัดชม',
  'สนใจนัดดุ': 'สนใจนัดดู',
  'โลเคชั่นน': 'โลเคชั่น',
  'โลเคชัน': 'โลเคชั่น',
  'ต่อลองได้': 'ต่อรอง',
  'ต่อรองได้': 'ต่อรอง',
  'ดูห้อง': 'นัดดู',
  'เข้าชม': 'นัดดู',
  'view room': 'นัดดูห้อง',
  'book viewing': 'นัดดูห้อง',
};

String normalizeChatText(String text) {
  var s = text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final keys = _typoCanonical.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final typo in keys) {
    s = s.replaceAll(typo, _typoCanonical[typo]!);
  }
  return s;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final row = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    var prev = row[0];
    row[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final tmp = row[j];
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      row[j] = [row[j] + 1, row[j - 1] + 1, prev + cost]
          .reduce((x, y) => x < y ? x : y);
      prev = tmp;
    }
  }
  return row[b.length];
}

int _fuzzyThreshold(int patternLen) {
  if (patternLen <= 3) return 0;
  if (patternLen <= 5) return 1;
  if (patternLen <= 8) return 2;
  return patternLen ~/ 4 > 3 ? 3 : patternLen ~/ 4;
}

bool fuzzyIncludes(String text, String pattern) {
  final hay = normalizeChatText(text);
  final needle = normalizeChatText(pattern);
  if (needle.isEmpty) return false;
  if (hay.contains(needle)) return true;
  if (needle.length < 3) return false;

  final maxDist = _fuzzyThreshold(needle.length);
  if (maxDist == 0) return false;

  final win = needle.length;
  for (var start = 0; start <= hay.length - 3; start++) {
    for (var size = win - maxDist; size <= win + maxDist; size++) {
      if (size < 3 || start + size > hay.length) continue;
      if (_levenshtein(hay.substring(start, start + size), needle) <= maxDist) {
        return true;
      }
    }
  }
  return false;
}
