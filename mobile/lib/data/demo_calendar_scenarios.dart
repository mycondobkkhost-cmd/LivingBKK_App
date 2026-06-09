import '../models/appointment.dart';
import '../models/demo_cast_persona.dart';
import '../models/viewing_report.dart';
import '../utils/reference_codes.dart';
import 'demo_cast_catalog.dart';
import 'demo_cast_listing_pins.dart';

/// กลุ่มเคสปฏิทินทดลอง — อดีต / ใกล้ (1–2 วัน) / อนาคต
enum DemoCalendarBucket { past, near, future }

/// สถานะเคสต่อลีด — ใช้ร่วมกับนัด แชท และฟอร์มนัดดู
class DemoCalendarLeadScenario {
  const DemoCalendarLeadScenario({
    required this.leadNum,
    required this.leadId,
    required this.listingCode,
    required this.seekerNickname,
    required this.seekerPhone,
    required this.bucket,
    required this.dayOffset,
    required this.timeSlot,
    required this.isCoAgent,
    required this.adminClaimed,
    required this.guideAssigned,
    required this.viewingAccepted,
    required this.hasViewingReport,
  });

  final int leadNum;
  final String leadId;
  final String listingCode;
  final String seekerNickname;
  final String seekerPhone;
  final DemoCalendarBucket bucket;
  final int dayOffset;
  final String timeSlot;
  final bool isCoAgent;
  final bool adminClaimed;
  final bool guideAssigned;
  final bool viewingAccepted;
  final bool hasViewingReport;

  String get appointmentId => 'demo-appt-lead-$leadNum';

  String get threadId => 'demo-lead-chat-$leadId';

  String get projectName {
    final title = DemoCastListingPins.titles[listingCode] ?? listingCode;
    return title.split(' · ').first;
  }
}

/// ชุดเคสปฏิทินหลังบ้าน — 12 ลีด หนึ่งนัดต่อลีด
abstract final class DemoCalendarScenarios {
  static const _nicknames = {
    1: 'คุณสมชาย',
    2: 'คุณบี',
    3: 'คุณต้น',
    4: 'คุณเจ',
    5: 'คุณแพร',
    6: 'คุณพลอย',
    7: 'คุณต้น',
    8: 'คุณแนน',
    9: 'คุณก้อง',
    10: 'คุณมิ้น',
    11: 'คุณนภา',
    12: 'คุณวิชัย',
  };

  static const _codes = [
    'LB-2026-000102',
    'RENT-CD-2026-000015',
    'SALE-HS-2026-000003',
    'RENT-CD-2026-000021',
    'SALE-CD-2026-000012',
    'RENT-CD-2026-000033',
    'RENT-CD-2026-000044',
    'RENT-CD-2026-000055',
    'SALE-HS-2026-000008',
    'RENT-CD-2026-000066',
    'RENT-CD-2026-000077',
    'SALE-CD-2026-000099',
  ];

  static const _phones = [
    '0812345678',
    '0898765432',
    '0623456789',
    '0891112233',
    '0654321987',
    '0865432190',
    '0819988776',
    '0923344556',
    '0631122334',
    '0845566778',
    '0856677889',
    '0867788990',
  ];

  static final List<DemoCalendarLeadScenario> all = List.generate(12, (i) {
    final n = i + 1;
    final leadId = 'demo-lead-$n';
    DemoCalendarBucket bucket;
    int dayOffset;
    String timeSlot;
    bool isCoAgent;
    bool adminClaimed;
    bool guideAssigned;
    bool viewingAccepted;
    bool hasViewingReport;

    switch (n) {
      case 1:
        bucket = DemoCalendarBucket.past;
        dayOffset = -3;
        timeSlot = '10:00 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 2:
        bucket = DemoCalendarBucket.past;
        dayOffset = -3;
        timeSlot = '14:30 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 3:
        bucket = DemoCalendarBucket.past;
        dayOffset = -2;
        timeSlot = '11:00 น.';
        isCoAgent = true;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 4:
        bucket = DemoCalendarBucket.past;
        dayOffset = -2;
        timeSlot = '15:00 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 5:
        bucket = DemoCalendarBucket.past;
        dayOffset = -1;
        timeSlot = '10:30 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 6:
        bucket = DemoCalendarBucket.past;
        dayOffset = -1;
        timeSlot = '16:00 น.';
        isCoAgent = true;
        adminClaimed = true;
        guideAssigned = true;
        viewingAccepted = true;
        hasViewingReport = true;
      case 7:
        bucket = DemoCalendarBucket.near;
        dayOffset = 1;
        timeSlot = '10:00 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = false;
        viewingAccepted = true;
        hasViewingReport = false;
      case 8:
        bucket = DemoCalendarBucket.near;
        dayOffset = 1;
        timeSlot = '14:00 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = false;
        viewingAccepted = true;
        hasViewingReport = false;
      case 9:
        bucket = DemoCalendarBucket.near;
        dayOffset = 2;
        timeSlot = '11:30 น.';
        isCoAgent = true;
        adminClaimed = true;
        guideAssigned = false;
        viewingAccepted = true;
        hasViewingReport = false;
      case 10:
        bucket = DemoCalendarBucket.near;
        dayOffset = 2;
        timeSlot = '15:30 น.';
        isCoAgent = false;
        adminClaimed = true;
        guideAssigned = false;
        viewingAccepted = true;
        hasViewingReport = false;
      case 11:
        bucket = DemoCalendarBucket.future;
        dayOffset = 4;
        timeSlot = '11:00 น.';
        isCoAgent = true;
        adminClaimed = false;
        guideAssigned = false;
        viewingAccepted = false;
        hasViewingReport = false;
      default:
        bucket = DemoCalendarBucket.future;
        dayOffset = 5;
        timeSlot = '15:00 น.';
        isCoAgent = false;
        adminClaimed = false;
        guideAssigned = false;
        viewingAccepted = false;
        hasViewingReport = false;
    }

    return DemoCalendarLeadScenario(
      leadNum: n,
      leadId: leadId,
      listingCode: _codes[i],
      seekerNickname: _nicknames[n]!,
      seekerPhone: _phones[i],
      bucket: bucket,
      dayOffset: dayOffset,
      timeSlot: timeSlot,
      isCoAgent: isCoAgent,
      adminClaimed: adminClaimed,
      guideAssigned: guideAssigned,
      viewingAccepted: viewingAccepted,
      hasViewingReport: hasViewingReport,
    );
  });

  static DemoCalendarLeadScenario? byLeadId(String? leadId) {
    if (leadId == null || !leadId.startsWith('demo-lead-')) return null;
    final n = int.tryParse(leadId.replaceFirst('demo-lead-', ''));
    if (n == null || n < 1 || n > 12) return null;
    return all[n - 1];
  }

  static DemoCalendarLeadScenario byLeadNum(int n) => all[n - 1];

  static String _guideId(int leadNum) =>
      '33333333-3333-3333-3333-33333333${leadNum.toString().padLeft(4, '0')}';

  static String _adminNote(DemoCalendarLeadScenario s) {
    final admins = DemoCastCatalog.byKind(DemoCastKind.admin);
    final admin = s.adminClaimed && admins.isNotEmpty
        ? admins[(s.leadNum - 1) % admins.length].displayNameTh
        : null;
    switch (s.bucket) {
      case DemoCalendarBucket.past:
        final co = s.isCoAgent ? ' · โคเอเจ้น' : ' · ลูกค้าตรง';
        return 'พาชมเสร็จแล้ว — แอดมิน $admin$co';
      case DemoCalendarBucket.near:
        return 'แอดมิน $admin รับแชทแล้ว — รอมอบหมายเอเจ้นพานัด';
      case DemoCalendarBucket.future:
        final co = s.isCoAgent ? 'โคเอเจ้น' : 'ลูกค้าตรง';
        return 'รอแอดมินรับแชท · $co · คำขอนัดยังไม่ยืนยัน';
    }
  }

  static String _status(DemoCalendarLeadScenario s) {
    switch (s.bucket) {
      case DemoCalendarBucket.past:
        return 'completed';
      case DemoCalendarBucket.near:
        return 'confirmed';
      case DemoCalendarBucket.future:
        return 'pending';
    }
  }

  static String _locationLabel(DemoCalendarLeadScenario s) {
    final project = s.projectName;
    switch (s.bucket) {
      case DemoCalendarBucket.past:
        return project;
      case DemoCalendarBucket.near:
        return '$project — ยังไม่ระบุคนพา';
      case DemoCalendarBucket.future:
        return '$project — รอยืนยันคำขอนัด';
    }
  }

  static ViewingReport? _report(DemoCalendarLeadScenario s, DateTime viewed) {
    if (!s.hasViewingReport) return null;
    const outcomes = [
      'ลูกค้าชอบห้อง อยากต่อรองค่าเช่า',
      'ลูกค้าพอใจ ขอใบเสนอราคา',
      'ลูกค้าสนใจมาก รอตัดสินใจกับครอบครัว',
      'ลูกค้าไม่ชอบทิศทางห้อง ขอดูยูนิตอื่น',
      'ลูกค้าชอบวิว ต้องการเช็กอินเฟอร์',
      'ลูกค้าไม่มาตามนัด (no-show)',
    ];
    const feedback = [
      'ห้องกว้าง วิวดี แสงเข้าดี',
      'ทำเลดี ใกล้ BTS',
      'ห้องสะอาด แต่เสียงดังเล็กน้อย',
      'ชอบฟิตเนสและสระว่ายน้ำ',
      'ราคาเหมาะสมกับงบ',
      'ไม่มีการติดต่อก่อนนัด',
    ];
    const wants = [
      'ขอใบเสนอราคา',
      'ขอดูยูนิตชั้นสูงกว่า',
      'ขอเวลาคิด 3 วัน',
      'ขอคุยกับเจ้าของเรื่องสัตว์เลี้ยง',
      'ขอนัดดูซ้ำพร้อมคู่สมรส',
      '—',
    ];
    final i = s.leadNum - 1;
    final decision = i == 5 ? 'closed' : 'continue';
    return ViewingReport(
      id: 'report-${s.appointmentId}',
      appointmentId: s.appointmentId,
      leadId: s.leadId,
      listingId: DemoCastListingPins.idForCode(s.listingCode),
      listingCode: s.listingCode,
      locationLabel: s.projectName,
      viewedDate: viewed,
      timeSlot: s.timeSlot,
      guideStaffId: s.guideAssigned ? _guideId(s.leadNum) : null,
      outcome: outcomes[i],
      customerFeedback: feedback[i],
      customerWants: wants[i],
      teamNotes: decision == 'continue'
          ? 'ติดตามภายใน 3 วัน · แท็ก SP-2026-${(100900 + s.leadNum).toString().padLeft(6, '0')}'
          : 'ปิดเคส no-show',
      decision: decision,
      seekerNickname: s.seekerNickname,
      seekerPhone: s.seekerPhone,
      recordedAt: viewed.add(const Duration(hours: 2)),
    );
  }

  static List<Appointment> buildAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.map((s) {
      final scheduled = today.add(Duration(days: s.dayOffset));
      final listing = DemoCastListingPins.all()
          .where((l) => l.listingCode == s.listingCode)
          .firstOrNull;
      final lat = listing?.lat;
      final lng = listing?.lng;

      return Appointment(
        id: s.appointmentId,
        leadId: s.leadId,
        listingId: DemoCastListingPins.idForCode(s.listingCode),
        listingCode: s.listingCode,
        transactionRef: ReferenceCodes.demoApptRef(s.appointmentId),
        seekerNickname: s.seekerNickname,
        seekerPhone: s.seekerPhone,
        scheduledDate: scheduled,
        timeSlot: s.timeSlot,
        status: _status(s),
        locationLabel: _locationLabel(s),
        lat: lat,
        lng: lng,
        adminNotes: _adminNote(s),
        assignedTo: s.guideAssigned ? _guideId(s.leadNum) : null,
        viewingReport: _report(s, scheduled),
      );
    }).toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
