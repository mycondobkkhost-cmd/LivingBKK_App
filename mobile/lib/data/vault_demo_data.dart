import '../models/vault_asset.dart';

/// ข้อมูลจำลองคลังลับ — หน้าตาเดียวกับ vault_assets จริงหลังซิงค์
class VaultDemoData {
  VaultDemoData._();

  static final DateTime _syncedAt = DateTime(2026, 6, 6, 9, 15);

  static List<VaultAssetSummary> summaries({String? entityType}) {
    final all = [
      VaultAssetSummary(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        entityType: 'listing_import',
        entityId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        sourcePlatform: 'livinginsider',
        titlePreview: 'ให้เช่า คอนโด 2 นอน อ่อนนุช อุดมสุข 25,000',
        listingCode: null,
        importId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        hasPhones: true,
        hasLines: true,
        sourceUrl:
            'https://www.livinginsider.com/istockdetail/DIoooI_beoIejf.html',
        capturedAt: _syncedAt.subtract(const Duration(days: 2)),
        updatedAt: _syncedAt,
      ),
      VaultAssetSummary(
        id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        entityType: 'listing_import',
        entityId: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        sourcePlatform: 'facebook',
        titlePreview: 'FB · ปล่อยเช่าทาวน์เฮาส์ ลาดพร้าว 3 ชั้น',
        importId: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        hasPhones: true,
        hasLines: true,
        sourceUrl: 'https://www.facebook.com/groups/bkk.rent/posts/1234567890',
        capturedAt: _syncedAt.subtract(const Duration(days: 1, hours: 4)),
        updatedAt: _syncedAt.subtract(const Duration(hours: 2)),
      ),
      VaultAssetSummary(
        id: 'c3d4e5f6-a7b8-9012-cdef-123456789012',
        entityType: 'listing_import',
        entityId: 'c3d4e5f6-a7b8-9012-cdef-123456789012',
        sourcePlatform: 'propertyhub',
        titlePreview: 'PH · ขายคอนโด ไอดีโอ โมบิ สุขุมวิท อีสต์พอยต์',
        listingCode: 'RXT-2026-004521',
        listingId: 'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
        importId: 'c3d4e5f6-a7b8-9012-cdef-123456789012',
        hasPhones: true,
        hasLines: false,
        sourceUrl: 'https://propertyhub.in.th/listing/condo-ideo-mobi-sukhumvit',
        capturedAt: _syncedAt.subtract(const Duration(days: 3)),
        updatedAt: _syncedAt.subtract(const Duration(hours: 5)),
      ),
      VaultAssetSummary(
        id: 'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
        entityType: 'listing',
        entityId: 'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
        sourcePlatform: 'propertyhub',
        titlePreview: 'ขายคอนโด ไอดีโอ โมบิ สุขุมวิท อีสต์พอยต์ 2 นอน',
        listingCode: 'RXT-2026-004521',
        listingId: 'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
        profileId: '11111111-1111-1111-1111-111111111111',
        hasPhones: true,
        hasLines: true,
        sourceUrl: 'https://propertyhub.in.th/listing/condo-ideo-mobi-sukhumvit',
        capturedAt: _syncedAt.subtract(const Duration(days: 5)),
        updatedAt: _syncedAt.subtract(const Duration(hours: 4)),
      ),
      VaultAssetSummary(
        id: 'e8d7c6b5-a493-210f-edcb-a98765432109',
        entityType: 'listing',
        entityId: 'e8d7c6b5-a493-210f-edcb-a98765432109',
        titlePreview: 'ให้เช่า คอนโด ไลฟ์ อ่อนนุช 1 นอน — เจ้าของปล่อยเอง',
        listingCode: 'RXT-2026-004522',
        listingId: 'e8d7c6b5-a493-210f-edcb-a98765432109',
        profileId: '11111111-1111-1111-1111-111111111111',
        hasPhones: true,
        hasLines: true,
        capturedAt: _syncedAt.subtract(const Duration(days: 4)),
        updatedAt: _syncedAt.subtract(const Duration(days: 1)),
      ),
      VaultAssetSummary(
        id: '11111111-1111-1111-1111-111111111111',
        entityType: 'profile',
        entityId: '11111111-1111-1111-1111-111111111111',
        titlePreview: 'คุณสมชาย ใจดี (เจ้าของทรัพย์)',
        profileId: '11111111-1111-1111-1111-111111111111',
        hasPhones: true,
        hasLines: true,
        capturedAt: _syncedAt.subtract(const Duration(days: 10)),
        updatedAt: _syncedAt.subtract(const Duration(hours: 3)),
      ),
      VaultAssetSummary(
        id: '33333333-3333-3333-3333-333333333333',
        entityType: 'profile',
        entityId: '33333333-3333-3333-3333-333333333333',
        titlePreview: 'วิชัย นายหน้า RealXtate',
        profileId: '33333333-3333-3333-3333-333333333333',
        hasPhones: true,
        hasLines: true,
        capturedAt: _syncedAt.subtract(const Duration(days: 14)),
        updatedAt: _syncedAt.subtract(const Duration(days: 2)),
      ),
    ];
    if (entityType == null) return all;
    return all.where((a) => a.entityType == entityType).toList();
  }

  static VaultAssetDetail? detailFor({
    required String entityType,
    required String entityId,
  }) {
    final key = '$entityType:$entityId';
    return _details[key];
  }

  static final Map<String, VaultAssetDetail> _details = {
    'listing_import:a1b2c3d4-e5f6-7890-abcd-ef1234567890': VaultAssetDetail(
      summary: summaries().first,
      capturedAt: _syncedAt,
      payload: {
        'source_url':
            'https://www.livinginsider.com/istockdetail/DIoooI_beoIejf.html',
        'source_external_id': '1408495',
        'import_status': 'parsed',
        'post_text_full':
            'ให้เช่า คอนโด 2 ห้องนอน อ่อนนุช อุดมสุข\n'
            'ขนาด 65 ตร.ม. ชั้น 18 วิวเมือง\n'
            'เจ้าของปล่อยเอง รับเอเจ้นท์ร่วม\n'
            'โทร 081-234-5678 / 089-876-5432\n'
            'Line: @owner_li',
        'post_links': [
          'https://line.me/ti/p/@owner_li',
          'https://www.livinginsider.com/istockdetail/DIoooI_beoIejf.html',
        ],
        'poster_name': 'คุณสมชาย',
        'poster_url': 'https://www.livinginsider.com/member/12345',
        'post_url':
            'https://www.livinginsider.com/istockdetail/DIoooI_beoIejf.html',
        'phones': ['0812345678', '0898765432'],
        'lines': ['@owner_li'],
        'contact_private': {
          'phones': ['0812345678', '0898765432'],
          'lines': ['@owner_li'],
        },
        'source_meta': {
          'postText': 'ให้เช่า คอนโด 2 ห้องนอน...',
          'posterName': 'คุณสมชาย',
        },
        'description_public_stripped':
            'ให้เช่า คอนโด 2 ห้องนอน ใกล้ BTS อ่อนนุช ราคา 25,000 บาท/เดือน',
        'recorded_by': 'demo-admin@livingbkk.local',
        'recorded_at': _syncedAt.toIso8601String(),
        'owner_display_name': 'คุณสมชาย',
        'chat_tag': 'IMP-a1b2c3d4',
        'edit_history': [
          {
            'actor': 'demo-admin@livingbkk.local',
            'action': 'นำเข้าจาก livinginsider และบันทึกในคลัง',
            'at': _syncedAt.toIso8601String(),
          },
        ],
        'synced_from': 'listing_imports',
        'synced_at': _syncedAt.toIso8601String(),
      },
    ),
    'listing_import:b2c3d4e5-f6a7-8901-bcde-f12345678901': VaultAssetDetail(
      summary: summaries()[1],
      capturedAt: _syncedAt.subtract(const Duration(hours: 2)),
      payload: {
        'source_url': 'https://www.facebook.com/groups/bkk.rent/posts/1234567890',
        'source_external_id': '1234567890',
        'import_status': 'parsed',
        'post_text_full':
            '🏠 ปล่อยเช่าทาวน์เฮาส์ ลาดพร้าว 3 ชั้น\n'
            '3 นอน 3 น้ำ จอดรถ 2 คัน\n'
            'ค่าเช่า 45,000/เดือน\n'
            'สนใจทักแชทหรือโทร 092-345-6789\n'
            'Line: townhouse_ladprao',
        'post_links': [
          'https://www.facebook.com/groups/bkk.rent/posts/1234567890',
          'https://line.me/ti/p/~townhouse_ladprao',
        ],
        'poster_name': 'พี่นุ้ย ปล่อยเช่า',
        'poster_url': 'https://www.facebook.com/profile.php?id=100012345678',
        'post_url': 'https://www.facebook.com/groups/bkk.rent/posts/1234567890',
        'phones': ['0923456789'],
        'lines': ['townhouse_ladprao'],
        'contact_private': {
          'phones': ['0923456789'],
          'lines': ['townhouse_ladprao'],
        },
        'source_meta': {
          'platform': 'facebook',
          'groupName': 'เช่า-ซื้อ บ้านคอนโด กทม.',
        },
        'synced_from': 'listing_imports',
        'synced_at': _syncedAt.subtract(const Duration(hours: 2)).toIso8601String(),
      },
    ),
    'listing_import:c3d4e5f6-a7b8-9012-cdef-123456789012': VaultAssetDetail(
      summary: summaries()[2],
      capturedAt: _syncedAt.subtract(const Duration(hours: 5)),
      payload: {
        'source_url':
            'https://propertyhub.in.th/listing/condo-ideo-mobi-sukhumvit',
        'source_external_id': 'ph-882910',
        'import_status': 'published',
        'post_text_full':
            'ขายคอนโด ไอดีโอ โมบิ สุขุมวิท อีสต์พอยต์\n'
            '2 นอน 2 น้ำ 55 ตร.ม. ชั้น 12\n'
            'ราคา 4.85 ล้าน (Net)\n'
            'ติดต่อเจ้าของ 081-234-5678',
        'phones': ['0812345678'],
        'lines': [],
        'contact_private': {'phones': ['0812345678'], 'lines': []},
        'description_public_stripped':
            'ขายคอนโด ไอดีโอ โมบิ สุขุมวิท อีสต์พอยต์ 2 นอน',
        'synced_from': 'listing_imports',
        'synced_at':
            _syncedAt.subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ),
    'listing:f9e8d7c6-b5a4-3210-fedc-ba9876543210': VaultAssetDetail(
      summary: summaries()[3],
      capturedAt: _syncedAt.subtract(const Duration(hours: 4)),
      payload: {
        'source_url':
            'https://propertyhub.in.th/listing/condo-ideo-mobi-sukhumvit',
        'source_external_id': 'ph-882910',
        'listed_by_role': 'owner',
        'owner_profile_id': '11111111-1111-1111-1111-111111111111',
        'owner_display_name': 'คุณสมชาย ใจดี',
        'owner_phone': '0812345678',
        'owner_line': '@owner_li',
        'description_public':
            'ขายคอนโด ไอดีโอ โมบิ สุขุมวิท อีสต์พอยต์ 2 นอน 55 ตร.ม.',
        'synced_from': 'listings',
        'synced_at':
            _syncedAt.subtract(const Duration(hours: 4)).toIso8601String(),
      },
    ),
    'listing:e8d7c6b5-a493-210f-edcb-a98765432109': VaultAssetDetail(
      summary: summaries()[4],
      capturedAt: _syncedAt.subtract(const Duration(days: 1)),
      payload: {
        'listed_by_role': 'owner',
        'owner_profile_id': '11111111-1111-1111-1111-111111111111',
        'owner_display_name': 'คุณสมชาย ใจดี',
        'owner_phone': '0812345678',
        'owner_line': '@owner_li',
        'description_public':
            'ให้เช่า คอนโด ไลฟ์ อ่อนนุช 1 นอน 32 ตร.ม. ฿18,000/เดือน',
        'synced_from': 'listings',
        'synced_at': _syncedAt.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ),
    'profile:11111111-1111-1111-1111-111111111111': VaultAssetDetail(
      summary: summaries()[5],
      capturedAt: _syncedAt.subtract(const Duration(hours: 3)),
      payload: {
        'display_name': 'คุณสมชาย ใจดี',
        'phone': '0812345678',
        'line_id': '@owner_li',
        'role': 'owner',
        'admin_tier': null,
        'account_created_at': '2025-11-01T08:00:00Z',
        'synced_from': 'profiles',
        'synced_at':
            _syncedAt.subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ),
    'profile:33333333-3333-3333-3333-333333333333': VaultAssetDetail(
      summary: summaries()[6],
      capturedAt: _syncedAt.subtract(const Duration(days: 2)),
      payload: {
        'display_name': 'วิชัย นายหน้า RealXtate',
        'phone': '0654321098',
        'line_id': '@agent_wichai',
        'role': 'agent',
        'admin_tier': null,
        'account_created_at': '2025-08-15T10:30:00Z',
        'synced_from': 'profiles',
        'synced_at': _syncedAt.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ),
  };
}
