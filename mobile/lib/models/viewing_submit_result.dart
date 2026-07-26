/// ผลลัพธ์หลังส่งฟอร์มขอนัดดู
class ViewingSubmitResult {
  const ViewingSubmitResult({
    required this.summary,
    required this.savedToDatabase,
    this.duplicatePhoneSuffix = false,
    this.leadTransactionRef,
  });

  final Map<String, String> summary;
  final bool savedToDatabase;
  final bool duplicatePhoneSuffix;
  final String? leadTransactionRef;
}
