/// ผลลัพธ์หลังบันทึกฟอร์มเจ้าของ (เติมข้อมูล / แก้ไข)
class PropertyCareOwnerDataResult {
  const PropertyCareOwnerDataResult({
    required this.saved,
    this.titleSentForReview = false,
  });

  final bool saved;
  final bool titleSentForReview;
}
