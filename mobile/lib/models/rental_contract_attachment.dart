/// ไฟล์สัญญาที่แอดมินแนบในกลุ่มเช่า (metadata — 27b จะอัปโหลด Storage จริง)
class RentalContractAttachment {
  const RentalContractAttachment({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.uploadedBy,
    this.note,
    this.mimeType,
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? note;
  final String? mimeType;

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'uploaded_at': uploadedAt.toIso8601String(),
        'uploaded_by': uploadedBy,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (mimeType != null) 'mime_type': mimeType,
      };

  factory RentalContractAttachment.fromJson(Map<String, dynamic> j) {
    return RentalContractAttachment(
      id: j['id']?.toString() ?? '',
      fileName: j['file_name']?.toString() ?? '',
      uploadedAt: DateTime.tryParse(j['uploaded_at']?.toString() ?? '') ??
          DateTime.now(),
      uploadedBy: j['uploaded_by']?.toString() ?? '',
      note: j['note']?.toString(),
      mimeType: j['mime_type']?.toString(),
    );
  }
}
