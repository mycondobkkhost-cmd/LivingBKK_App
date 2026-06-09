import '../config/env.dart';
import '../models/customer_requirement.dart';

/// เคสตัวอย่างหลังบ้าน — `TRIAL_MODE` หรือ `ADMIN_DEMO_CASES` เมื่อ DB ว่าง
class AdminDemoData {
  AdminDemoData._();

  static bool get enabled => Env.adminDemoCases;

  static bool useWhenEmpty<T>(List<T> live) => enabled && live.isEmpty;

  static final DateTime _base = DateTime(2026, 6, 5, 10, 0);

  // ── ความต้องการลูกค้า ─────────────────────────────────────────────

  static List<CustomerRequirement> pendingRequirements() => [
        CustomerRequirement(
          id: 'demo-req-1',
          transactionType: 'rent',
          propertyType: 'condo',
          zone: 'ทองหล่อ',
          locationLabels: const ['ทองหล่อ', 'เอกมัย'],
          minPriceNet: 22000,
          maxPriceNet: 28000,
          minAreaSqm: 35,
          furnishing: 'furnished',
          notes: 'ต้องการห้องมุม วิวเมือง สัตว์เลี้ยงได้',
          decisionTimeframe: 'within_2_weeks',
          contactName: 'คุณมิ้นท์',
          contactPhone: '0812345678',
          status: 'pending',
          createdAt: _base.subtract(const Duration(days: 2)),
          urgentRush: true,
          threadId: 'demo-req-thread-1',
        ),
        CustomerRequirement(
          id: 'demo-req-2',
          transactionType: 'sale',
          propertyType: 'condo',
          zone: 'อโศก',
          preferredProjectName: 'The Esse Asoke',
          minPriceNet: 5500000,
          maxPriceNet: 7500000,
          minAreaSqm: 45,
          furnishing: 'any',
          notes: 'ลงทุนปล่อยเช่า ผลตอบแทนดี',
          decisionTimeframe: 'still_comparing',
          contactName: 'คุณก้อง',
          contactPhone: '0898765432',
          status: 'pending',
          createdAt: _base.subtract(const Duration(days: 4)),
        ),
        CustomerRequirement(
          id: 'demo-req-3',
          transactionType: 'rent',
          propertyType: 'condo',
          zone: 'อารีย์',
          requesterRole: 'agent',
          locationLabels: const ['อารีย์', 'พหลโยธิน'],
          maxPriceNet: 18000,
          minAreaSqm: 28,
          furnishing: 'unfurnished',
          notes: 'ลูกค้านายหน้า — สตูดิโอ ใกล้ BTS',
          contactName: 'วิชัย โคเอ',
          contactPhone: '0654321098',
          status: 'pending',
          createdAt: _base.subtract(const Duration(hours: 18)),
          threadId: 'demo-req-thread-3',
        ),
        CustomerRequirement(
          id: 'demo-req-4',
          transactionType: 'rent',
          propertyType: 'house',
          zone: 'รามอินทรา',
          locationLabels: const ['รามอินทรา', 'หลักสี่'],
          minPriceNet: 25000,
          maxPriceNet: 35000,
          minAreaSqm: 120,
          furnishing: 'any',
          notes: 'ครอบครัว 2 คน มีที่จอดรถ',
          contactName: 'คุณแป้ง',
          contactPhone: '0823456789',
          status: 'pending',
          createdAt: _base.subtract(const Duration(days: 1)),
        ),
      ];

  // ── เคสลูกค้า (leads) ────────────────────────────────────────────

  static List<Map<String, dynamic>> leads() => [
        {
          'id': 'demo-lead-1',
          'listing_id': 'trial-listing-published',
          'listing_code': 'LB-2026-000102',
          'transaction_ref': 'LEAD-2026-000011',
          'status': 'routed',
          'seeker_nickname': 'น้องมิ้นท์',
          'seeker_phone': '0812345678',
          'occupation': 'พนักงานออฟฟิศ',
          'move_plan': 'within_1_month',
          'budget': '28,000',
          'qualification_json': {
            'viewing_schedule': '12/6/2569 · 14:00 น.',
          },
          'created_at': _base.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'demo-lead-2',
          'listing_id': 'demo-rhythm-sukhumvit-36-0',
          'listing_code': 'RENT-CD-2026-000015',
          'transaction_ref': 'LEAD-2026-000015',
          'status': 'new',
          'seeker_nickname': 'คุณบี',
          'seeker_phone': '0898765432',
          'qualification_json': {
            'viewing_schedule': '15/6/2569 · 10:30 น.',
          },
          'created_at': _base.subtract(const Duration(hours: 6)).toIso8601String(),
        },
        {
          'id': 'demo-lead-3',
          'listing_code': 'SALE-HS-2026-000003',
          'transaction_ref': 'LEAD-2026-000003',
          'status': 'accepted',
          'seeker_nickname': 'คุณต้น',
          'seeker_phone': '0623456789',
          'qualification_json': {},
          'created_at': _base.subtract(const Duration(days: 3)).toIso8601String(),
        },
        {
          'id': 'demo-lead-4',
          'listing_code': 'RENT-CD-2026-000021',
          'transaction_ref': 'LEAD-2026-000021',
          'status': 'routed',
          'seeker_nickname': 'คุณเจ',
          'seeker_phone': '0891112233',
          'qualification_json': {'viewing_schedule': 'วันนี้ · 11:00 น.'},
          'created_at': _base.subtract(const Duration(hours: 12)).toIso8601String(),
        },
        {
          'id': 'demo-lead-6',
          'listing_code': 'SALE-CD-2026-000012',
          'transaction_ref': 'LEAD-2026-000012',
          'status': 'routed',
          'seeker_nickname': 'คุณพลอย',
          'seeker_phone': '0865432190',
          'qualification_json': {'viewing_schedule': 'วันนี้ · 15:00 น.'},
          'created_at': _base.subtract(const Duration(hours: 8)).toIso8601String(),
        },
        {
          'id': 'demo-lead-7',
          'listing_code': 'RENT-CD-2026-000033',
          'status': 'new',
          'seeker_nickname': 'คุณต้น',
          'seeker_phone': '0819988776',
          'qualification_json': {},
          'created_at': _base.subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'id': 'demo-lead-8',
          'listing_code': 'RENT-CD-2026-000044',
          'status': 'routed',
          'seeker_nickname': 'คุณแนน',
          'seeker_phone': '0923344556',
          'qualification_json': {},
          'created_at': _base.subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ];

  static Map<String, dynamic> leadStats() => {
        'lead_count': 12,
        'accepted_count': 5,
        'new_count': 3,
      };

  // ── ข้อเสนอ (offers) ─────────────────────────────────────────────

  static List<Map<String, dynamic>> demandOffers() => [
        {
          'id': 'demo-offer-1',
          'status': 'pending',
          'offerer_capacity': 'owner_direct_100',
          'capacity_verified': 'pending',
          'offer_type': 'external',
          'external_url': 'https://www.facebook.com/marketplace/item/demo-1',
          'description': 'เจ้าของตรง คอนโด 2 นอน ทองหล่อ — ราคาต่อรองได้',
          'demand_posts': {
            'title': 'หาเช่าคอนโด ทองหล่อ–เอกมัย',
            'post_code': 'BD-2026-000042',
          },
          'created_at': _base.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'demo-offer-2',
          'status': 'under_review',
          'offerer_capacity': 'agent_listing',
          'capacity_verified': 'verified',
          'offer_type': 'in_app',
          'description': 'นายหน้ามีห้องตรงสเปก โครงการ Origin Play',
          'demand_posts': {
            'title': 'หาเช่าคอนโด อุดมสุข',
            'post_code': 'BD-2026-000038',
          },
          'created_at': _base.subtract(const Duration(hours: 20)).toIso8601String(),
        },
      ];

  // ── ทะเบียนทรัพย์ RXT (RealXtate) ───────────────────────────────

  /// หา id เคสจำลองจากรหัส RXT (เช่น RXT-2026-000201 → demo-inv-1)
  static String? inventoryIdForCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final upper = code.trim().toUpperCase();
    for (final row in inventoryRoster()) {
      if ((row['inventory_code']?.toString().toUpperCase() ?? '') == upper) {
        return row['id']?.toString();
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> inventoryRoster() => [
        {
          'id': 'demo-inv-1',
          'inventory_code': 'RXT-2026-000201',
          'canonical_title': 'The Esse Asoke · 1BR 45 ตร.ม.',
          'property_type': 'condo',
          'district': 'วัฒนา',
          'member_count': 3,
          'primary_listing_code': 'LB-2026-000102',
          'has_open_alerts': true,
          'updated_at': _base.toIso8601String(),
        },
        {
          'id': 'demo-inv-2',
          'inventory_code': 'RXT-2026-000202',
          'canonical_title': 'บ้านเดี่ยว รามอินทรา ซ.5',
          'property_type': 'house',
          'district': 'บางเขน',
          'member_count': 2,
          'primary_listing_code': 'LB-2026-000103',
          'has_open_alerts': false,
          'updated_at': _base.subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'id': 'demo-inv-3',
          'inventory_code': 'RXT-2026-000203',
          'canonical_title': 'Rhythm Sukhumvit 36 · สตูดิโอ',
          'property_type': 'condo',
          'district': 'คลองเตย',
          'member_count': 4,
          'primary_listing_code': 'RENT-CD-2026-000015',
          'has_open_alerts': true,
          'updated_at': _base.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];

  static List<Map<String, dynamic>> inventoryMembers(String inventoryId) {
    if (inventoryId == 'demo-inv-1') {
      return [
        _member('demo-m-1', inventoryId, 'LB-2026-000102', 'owner_direct', true),
        _member('demo-m-2', inventoryId, 'RENT-CD-2026-000016', 'agent', false),
        _member('demo-m-3', inventoryId, 'RENT-CD-2026-000017', 'agent', false),
      ];
    }
    if (inventoryId == 'demo-inv-2') {
      return [
        _member('demo-m-4', inventoryId, 'LB-2026-000103', 'owner_direct', true),
        _member('demo-m-5', inventoryId, 'SALE-HS-2026-000003', 'agent', false),
      ];
    }
    return [
      _member('demo-m-6', inventoryId, 'RENT-CD-2026-000015', 'agent', true),
      _member('demo-m-7', inventoryId, 'RENT-CD-2026-000018', 'agent', false),
    ];
  }

  static Map<String, dynamic> _member(
    String id,
    String invId,
    String code,
    String role,
    bool primary,
  ) =>
      {
        'id': id,
        'inventory_id': invId,
        'listing_id': 'demo-listing-$code',
        'listing_code': code,
        'listed_by_role': role,
        'is_primary_contact': primary,
        'inventory_contact_priority': primary ? 1 : 2,
        'price_net': role == 'owner_direct' ? 28000 : 29500,
        'status': 'published',
      };

  // ── ตรวจสอบ (moderation) ─────────────────────────────────────────

  static List<Map<String, dynamic>> pendingListingImages() => [
        {
          'id': 'demo-img-1',
          'listing_id': 'trial-listing-pending',
          'public_url': 'https://picsum.photos/seed/mod-pending-1/400/300',
          'moderation_status': 'pending',
          'perceptual_hash': 'a1b2c3d4',
          'listings': {
            'listing_code': 'LB-2026-000101',
            'title': 'บ้านเช่า นานา (รอตรวจ)',
          },
        },
        {
          'id': 'demo-img-2',
          'listing_id': 'trial-listing-pending',
          'public_url': 'https://picsum.photos/seed/mod-pending-2/400/300',
          'moderation_status': 'pending',
          'perceptual_hash': 'e5f6g7h8',
          'listings': {
            'listing_code': 'LB-2026-000101',
            'title': 'บ้านเช่า นานา (รอตรวจ)',
          },
        },
      ];

  static List<Map<String, dynamic>> openModerationFlags() => [
        {
          'id': 'demo-flag-1',
          'listing_id': 'trial-listing-published',
          'flag_type': 'phone_in_description',
          'raw_match': '08x-xxx-xxxx',
          'listings': {
            'listing_code': 'LB-2026-000102',
            'title': 'คอนโด อโศก',
          },
        },
      ];

  // ── คำขอเข้าถึง / องค์กร (vault) ─────────────────────────────────

  static List<Map<String, dynamic>> accessRequests() => [
        {
          'id': 'demo-access-1',
          'entity_type': 'listing',
          'entity_code': 'LB-2026-000102',
          'requester': 'แอดมิน (Lead)',
          'reason': 'ติดต่อเจ้าของเรื่องนัดชมด่วน',
          'status': 'pending',
          'created_at': _base.subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'demo-access-2',
          'entity_type': 'vault_import',
          'entity_code': 'LI-3097128',
          'requester': 'แอดมิน (Ops)',
          'reason': 'ตรวจสอบเบอร์ซ้ำกับคลังลับ',
          'status': 'approved',
          'created_at': _base.subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];

  static List<Map<String, dynamic>> orgUnits() => [
        {
          'id': 'demo-org-1',
          'name': 'ทีมปฏิบัติการ กทม.',
          'tier': 'ops',
          'members': 4,
          'lead': 'คุณแอน',
        },
        {
          'id': 'demo-org-2',
          'name': 'ทีม Co-Agent',
          'tier': 'partner',
          'members': 12,
          'lead': 'วิชัย โคเอ',
        },
      ];
}

/// สถานะความต้องการ demo ในหน่วยความจำ (ปิดคำขอ / เผยแพร่แล้ว)
class AdminDemoRequirementStore {
  AdminDemoRequirementStore._();
  static final AdminDemoRequirementStore instance = AdminDemoRequirementStore._();

  List<CustomerRequirement> _items = AdminDemoData.pendingRequirements();

  void reset() => _items = AdminDemoData.pendingRequirements();

  List<CustomerRequirement> listPending() =>
      _items.where((r) => r.status == 'pending').toList(growable: false);

  bool isDemoId(String id) => id.startsWith('demo-req-');

  void close(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(status: 'closed');
  }

  void markPublished(String id, {String? postCode}) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(
      status: 'published',
      demandPostCode: postCode ?? 'BD-DEMO',
    );
  }
}
