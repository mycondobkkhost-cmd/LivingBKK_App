import '../data/viewing_staff_catalog.dart';

/// ชื่อเจ้าหน้าที่พานัดชม — Agent One … Five
abstract final class AppointmentStaffLabels {
  static List<({String id, String th, String en, String phone})> get options =>
      ViewingStaffCatalog.pickerOptions;

  static String label(String? assignedTo, {required bool isEn}) =>
      ViewingStaffCatalog.label(assignedTo, isEn: isEn);

  static String? phone(String? assignedTo) => ViewingStaffCatalog.phone(assignedTo);
}
