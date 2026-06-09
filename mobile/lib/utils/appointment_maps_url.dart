import '../l10n/app_strings.dart';
import '../models/appointment.dart';
import '../models/chat_message.dart';

/// สร้างลิงก์ Google Maps จากนัดชม
String? appointmentMapsUrl(Appointment appointment) {
  final lat = appointment.lat;
  final lng = appointment.lng;
  if (lat != null && lng != null) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
  final label = appointment.locationLabel?.trim();
  final code = appointment.listingCode?.trim();
  final query = (label != null && label.isNotEmpty)
      ? label
      : (code != null && code.isNotEmpty ? code : null);
  if (query == null) return null;
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
}

List<ChatMessageLink> viewingLocationLinks(Appointment appointment, AppStrings s) {
  final url = appointmentMapsUrl(appointment);
  if (url == null) return const [];
  return [
    ChatMessageLink.viewingLocation(
      label: s.chatLinkViewingLocation,
      mapsUrl: url,
    ),
  ];
}

List<ChatMessageLink> viewingLocationLinksFromUrl(String? mapsUrl, AppStrings s) {
  final url = mapsUrl?.trim();
  if (url == null || url.isEmpty) return const [];
  return [
    ChatMessageLink.viewingLocation(
      label: s.chatLinkViewingLocation,
      mapsUrl: url,
    ),
  ];
}

List<ChatMessageLink> viewingAppointmentLinks(Appointment appointment, AppStrings s) {
  final ref = appointment.transactionRef?.trim();
  final label = ref != null && ref.isNotEmpty
      ? '${s.chatLinkViewingAppointment} · $ref'
      : s.chatLinkViewingAppointment;
  return [
    ChatMessageLink.viewingAppointment(
      label: label,
      appointmentId: appointment.id,
    ),
  ];
}

/// ลิงก์เสริมเมื่อยังไม่มีบันทึกนัด — เฉพาะพิกัด (ไม่ใส่ APPT ในแชทลูกค้า)
List<ChatMessageLink> viewingConfirmNoticeLinks(
  Appointment appointment,
  AppStrings s,
) {
  return viewingLocationLinks(appointment, s);
}
