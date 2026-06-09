/// รูปในอัลบั้ม — ไม่มีคำบรรยายต่อรูป
class RentalAlbumPhoto {
  const RentalAlbumPhoto({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final String uploadedBy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'uploaded_at': uploadedAt.toIso8601String(),
        'uploaded_by': uploadedBy,
      };

  factory RentalAlbumPhoto.fromJson(Map<String, dynamic> j) {
    return RentalAlbumPhoto(
      id: j['id']?.toString() ?? '',
      fileName: j['file_name']?.toString() ?? '',
      uploadedAt: DateTime.tryParse(j['uploaded_at']?.toString() ?? '') ??
          DateTime.now(),
      uploadedBy: j['uploaded_by']?.toString() ?? '',
    );
  }
}
