/// โน้ตยาวแบบ LINE — ข้อความอธิบายรวม (ไม่ผูกกับรูปแต่ละใบ)
class RentalAlbumNote {
  const RentalAlbumNote({
    required this.body,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String body;
  final DateTime updatedAt;
  final String updatedBy;

  bool get isEmpty => body.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'updated_by': updatedBy,
      };

  factory RentalAlbumNote.fromJson(Map<String, dynamic> j) {
    return RentalAlbumNote(
      body: j['body']?.toString() ?? '',
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedBy: j['updated_by']?.toString() ?? '',
    );
  }
}
