/// นัดดูห้อง — mirror viewing_request_voice.ts
library;

import 'chat_text_fuzzy.dart';

const _viewingKeys = [
  'นัดดู',
  'นัดชม',
  'ขอดู',
  'ดูห้อง',
  'เข้าชม',
  'สนใจนัดดู',
  'สนใจดู',
  'อยากนัดดู',
  'อยากดู',
  'จองนัด',
  'จองนัดดู',
  'นัดเข้า',
  'ขอนัด',
  'จะนัด',
  'ขอชม',
  'สนใจชม',
  'viewing',
  'view room',
  'book viewing',
  'see the room',
];

bool isViewingRequestIntent(String text) {
  final q = normalizeChatText(text);
  if (_viewingKeys.any((k) => q.contains(normalizeChatText(k)))) return true;
  return _viewingKeys.any((k) => fuzzyIncludes(text, k));
}

List<String> viewingRequestBurst(String text) {
  final q = normalizeChatText(text);
  final raw = text.toLowerCase().replaceAll('มั้ย', 'ไหม').replaceAll('นัดดุ', 'นัดดู');
  if (_containsAny(q, ['วันนี้', 'today', 'เย็นนี้', 'เช้านี้', 'บ่ายนี้', 'tonight']) ||
      _containsAny(raw, ['วันนี้', 'today', 'เย็นนี้', 'เช้านี้', 'บ่ายนี้', 'tonight'])) {
    return const [
      'ได้เลยค่ะ วันนี้ลูกค้าสะดวกประมาณกี่โมงคะ',
      'แอดมินจะสอบถามเจ้าของให้โดยประมาณนะคะ',
    ];
  }
  if (_containsAny(q, ['พรุ่งนี้', 'tomorrow']) ||
      _containsAny(raw, ['พรุ่งนี้', 'tomorrow'])) {
    return const [
      'ได้เลยค่ะ พรุ่งนี้สะดวกช่วงเช้าหรือบ่ายดีคะ',
      'แอดมินจะเช็กคิวและประสานงานให้ค่ะ',
    ];
  }
  if (_containsAny(q, ['เสาร์', 'อาทิตย์', 'weekend']) ||
      _containsAny(raw, ['เสาร์', 'อาทิตย์', 'weekend'])) {
    return const [
      'ได้เลยค่ะ เสาร์-อาทิตย์สะดวกช่วงไหนดีคะ',
      'แอดมินจะล็อกคิวและประสานงานให้ค่ะ',
    ];
  }
  return const [
    'ได้เลยค่ะ สะดวกเป็นช่วงวันไหนดีคะ',
    'แอดมินจะรีบเช็กคิวและประสานงานให้ค่ะ',
  ];
}

bool _containsAny(String hay, List<String> keys) =>
    keys.any((k) => hay.contains(k));
