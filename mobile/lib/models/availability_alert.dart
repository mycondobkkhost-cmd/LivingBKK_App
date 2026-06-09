/// ประกาศที่มีวันว่างอีกครั้งในอนาคต — สำหรับทีมติดต่อเจ้าของล่วงหน้า
class AvailabilityAlertItem {
  const AvailabilityAlertItem({
    required this.listingId,
    required this.listingCode,
    required this.title,
    required this.availableAgain,
    this.projectName,
    this.district,
    this.listingType = 'rent',
    this.status = 'archived',
    this.ownerId,
    this.ownerName,
  });

  final String listingId;
  final String listingCode;
  final String title;
  final DateTime availableAgain;
  final String? projectName;
  final String? district;
  final String listingType;
  final String status;
  final String? ownerId;
  final String? ownerName;

  static int daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(target.year, target.month, target.day);
    return d.difference(today).inDays;
  }

  int get daysLeft => daysUntil(availableAgain);

  bool get withinOneMonth => daysLeft >= 0 && daysLeft <= 30;

  bool get urgent => daysLeft >= 0 && daysLeft <= 7;

  String locationLine(bool isEnglish) {
    final parts = <String>[];
    if (projectName != null && projectName!.trim().isNotEmpty) {
      parts.add(projectName!.trim());
    }
    if (district != null && district!.trim().isNotEmpty) {
      parts.add(district!.trim());
    }
    if (parts.isEmpty) {
      return isEnglish ? 'Bangkok area' : 'กทม. / ปริมณฑล';
    }
    return parts.join(' · ');
  }

  factory AvailabilityAlertItem.fromListingRow(Map<String, dynamic> row) {
    final againRaw = row['available_again']?.toString();
    final again = againRaw != null ? DateTime.tryParse(againRaw) : null;
    if (again == null) {
      throw ArgumentError('available_again required');
    }

    String? ownerName;
    final owner = row['owner'];
    if (owner is Map) {
      ownerName = owner['display_name']?.toString();
    }

    return AvailabilityAlertItem(
      listingId: row['id']?.toString() ?? '',
      listingCode: row['listing_code']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      availableAgain: again,
      projectName: row['project_name']?.toString(),
      district: row['district']?.toString(),
      listingType: row['listing_type']?.toString() ?? 'rent',
      status: row['status']?.toString() ?? '',
      ownerId: row['owner_id']?.toString(),
      ownerName: ownerName,
    );
  }
}
