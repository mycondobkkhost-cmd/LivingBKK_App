/// ตรวจว่า id ใช้กับคอลัมน์ uuid ใน Supabase ได้หรือไม่
bool isListingUuid(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(raw);
}

String? listingIdForBackend(String? raw) =>
    isListingUuid(raw) ? raw : null;
