/// ดึงรหัสทรัพย์จากข้อความค้นหา
String? extractListingCodeFromQuery(String query) {
  final q = query.trim();
  if (q.isEmpty) return null;
  final upper = q.toUpperCase();

  final exact = RegExp(
    r'^(RENT|SALE)-[A-Z]{2}-\d{4}-\d{6}$',
    caseSensitive: false,
  );
  final pir = RegExp(r'^PIR\d{6}-\d{4}$', caseSensitive: false);
  final inv = RegExp(r'^(RXT|PPTR|PTP)-\d{4}-\d{6}$', caseSensitive: false);

  if (exact.hasMatch(upper) || pir.hasMatch(upper) || inv.hasMatch(upper)) {
    return upper;
  }

  final inline = RegExp(
    r'\b((?:RENT|SALE)-[A-Z]{2}-\d{4}-\d{6}|PIR\d{6}-\d{4}|(?:RXT|PPTR|PTP)-\d{4}-\d{6})\b',
    caseSensitive: false,
  ).firstMatch(q);
  return inline?.group(1)?.toUpperCase();
}

bool isListingCodeQuery(String query) =>
    extractListingCodeFromQuery(query) != null;
