/// ตัวอย่างนัดหมาย / Lead สำหรับ Demo
class DemoAppointments {
  static List<Map<String, dynamic>> get myLeads => [
        {
          'id': 'demo-my-lead-1',
          'listing_code': 'RENT-CD-2026-000011',
          'transaction_ref': 'LEAD-2026-000011',
          'status': 'new',
          'seeker_nickname': 'คุณ (ตัวอย่าง)',
        },
        {
          'id': 'demo-my-lead-2',
          'listing_code': 'SALE-HS-2026-000003',
          'transaction_ref': 'LEAD-2026-000003',
          'status': 'routed',
          'seeker_nickname': 'คุณ (ตัวอย่าง)',
        },
      ];

  static List<Map<String, dynamic>> get offers => [
        {
          'id': 'demo-offer-1',
          'status': 'pending',
          'offerer_capacity': 'owner_direct_100',
        },
      ];

  static List<Map<String, dynamic>> get coAgentReqs => [
        {
          'id': 'demo-co-1',
          'listing_id': 'demo-rhythm-sukhumvit-36-0',
          'status': 'pending',
        },
      ];

  static List<Map<String, dynamic>> get inbox => [
        {
          'id': 'demo-lead-1',
          'listing_code': 'RENT-CD-2026-000011',
          'transaction_ref': 'LEAD-2026-000011',
          'seeker_nickname': 'น้องมิ้นท์',
          'seeker_phone_censored': '08x-xxx-5725',
          'qualification_json': {
            'viewing_schedule': '12/6/2569 · 14:00 น.',
          },
          'status': 'routed',
        },
      ];
}
