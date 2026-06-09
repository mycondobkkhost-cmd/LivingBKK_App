import '../models/calendar_event.dart';

/// กิจกรรมปฏิทิน demo — ร่าง AI + งานยืนยันแล้ว
abstract final class DemoCalendarEvents {
  static List<CalendarEvent> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d1 = today.add(const Duration(days: 1));
    final d2 = today.add(const Duration(days: 2));

    return [
      CalendarEvent(
        id: 'demo-cal-ai-1',
        eventType: 'viewing',
        status: 'ai_draft',
        title: 'คุณพินนัดดูห้อง',
        description: '✅ โซน: เอกมัย, RCA\n'
            '✅ ผู้อยู่: 1\n✅ งบ: 13,000-16,000/เดือน\n'
            '✅ ย้ายเข้า: 2026/6/28\n✅ สัตว์เลี้ยง: ไม่\n✅ จอดรถ: ใช่',
        startAt: DateTime(d1.year, d1.month, d1.day, 12, 0),
        endAt: DateTime(d1.year, d1.month, d1.day, 13, 0),
        colorHint: 'red',
        listingCode: 'LB-2026-000102',
        locationLabel: 'The Niche Pride Thonglor-Petchaburi',
        threadId: 'demo-lead-chat-demo-lead-1',
        leadId: 'demo-lead-1',
        version: 1,
        aiDraft: {
          'title': 'คุณพินนัดดูห้อง',
          'source': 'ai_rules',
        },
      ),
      CalendarEvent(
        id: 'demo-cal-ai-2',
        eventType: 'maintenance',
        status: 'ai_draft',
        title: 'ซ่อมแอร์',
        description: 'AI แนะนำจากแชทเจ้าของ — ห้อง LB-2026-000015',
        startAt: DateTime(d2.year, d2.month, d2.day, 10, 0),
        endAt: DateTime(d2.year, d2.month, d2.day, 11, 0),
        colorHint: 'blue',
        listingCode: 'RENT-CD-2026-000015',
        version: 1,
        aiDraft: {'event_type': 'maintenance'},
      ),
      CalendarEvent(
        id: 'demo-cal-ops-1',
        eventType: 'ops',
        status: 'confirmed',
        title: 'นัดชมห้อง ชั้น 32 ลูกค้าตรง',
        description: 'ยืนยันโดยแอดมิน',
        startAt: DateTime(today.year, today.month, today.day, 15, 0),
        endAt: DateTime(today.year, today.month, today.day, 16, 0),
        colorHint: 'red',
        listingCode: 'SALE-HS-2026-000003',
        locationLabel: 'The Line Sukhumvit 101',
        version: 2,
        fieldLocks: const {'start_at': 'human', 'title': 'human'},
        humanEditedAt: now,
      ),
    ];
  }
}
