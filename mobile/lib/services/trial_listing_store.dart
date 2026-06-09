import '../models/listing_occupancy.dart';
import 'listing_create_repository.dart';

/// สถานะประกาศในหน่วยความจำ — โหมดทดลอง (อนุมัติ/ปฏิเสธ/ส่งตรวจ)
class TrialListingStore {
  TrialListingStore._();

  static final TrialListingStore instance = TrialListingStore._();

  final List<Map<String, dynamic>> _rows = [];
  bool _seeded = false;
  int _codeSeq = 201;

  void reset() {
    _rows.clear();
    _seeded = false;
    _codeSeq = 201;
  }

  void _ensureSeed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now().toUtc().toIso8601String();
    _rows.addAll([
      {
        'id': 'trial-listing-pending',
        'listing_code': 'LB-2026-000101',
        'title': 'บ้านเช่า นานา (รอตรวจ)',
        'status': 'pending_review',
        'listing_type': 'rent',
        'property_type': 'house',
        'price_net': 35000,
        'district': 'คลองเตย',
        'project_name': null,
        'cover_image_url': 'https://picsum.photos/seed/lb-nana-rent/240/180',
        'updated_at': now,
      },
      {
        'id': 'trial-listing-pending-2',
        'listing_code': 'LB-2026-000104',
        'title': 'คอนโด 2 นอน เอกมัย (รอตรวจ)',
        'status': 'pending_review',
        'listing_type': 'rent',
        'property_type': 'condo',
        'price_net': 42000,
        'district': 'วัฒนา',
        'project_name': 'The Lofts Ekkamai',
        'cover_image_url': 'https://picsum.photos/seed/lb-ekkamai-rent/240/180',
        'updated_at': now,
      },
      {
        'id': 'trial-listing-published',
        'listing_code': 'LB-2026-000102',
        'title': 'คอนโด อโศก',
        'title_display': 'The Esse Asoke · คอนโด 1 นอน วิวเมือง',
        'description_display':
            'คอนโดหรูใจกลางอโศก ใกล้ BTS · ตกแต่งครบ · เหมาะทำงานหรืออยู่อาศัย (ข้อความหน้าบ้านโดยทีม)',
        'description_public':
            'คอนโดหรูใจกลางอโศก ใกล้ BTS · ตกแต่งครบ · เหมาะทำงานหรืออยู่อาศัย (ข้อความหน้าบ้านโดยทีม)',
        'status': 'published',
        'listing_type': 'rent',
        'property_type': 'condo',
        'price_net': 28000,
        'district': 'วัฒนา',
        'project_name': 'The Esse Asoke',
        'bedrooms': 1,
        'bathrooms': 1,
        'area_sqm': 45,
        'last_bump_at': DateTime.now()
            .subtract(const Duration(days: 8))
            .toUtc()
            .toIso8601String(),
        'published_at': now,
        'expires_at':
            DateTime.now().add(const Duration(days: 22)).toUtc().toIso8601String(),
        'cover_image_url': 'https://picsum.photos/seed/lb-asoke-condo/240/180',
        'owner_data_status': 'pending',
        'updated_at': now,
      },
      {
        'id': 'trial-listing-installment',
        'listing_code': 'LB-2026-000103',
        'title': 'บ้านขายฝาก รามอินทรา',
        'status': 'draft',
        'listing_type': 'sale_installment',
        'property_type': 'house',
        'price_net': 4200000,
        'district': 'บางเขน',
        'project_name': null,
        'cover_image_url': 'https://picsum.photos/seed/lb-ramintra-sale/240/180',
        'updated_at': now,
      },
    ]);
  }

  bool updateOwnerListingFields(
    String listingId,
    Map<String, dynamic> fields,
  ) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    row.addAll(fields);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return true;
  }

  bool updateOwnerListingFieldsByCode(
    String listingCode,
    Map<String, dynamic> fields,
  ) {
    _ensureSeed();
    final code = listingCode.trim();
    for (final row in _rows) {
      if (row['listing_code']?.toString() != code) continue;
      row.addAll(fields);
      row['updated_at'] = DateTime.now().toUtc().toIso8601String();
      return true;
    }
    return false;
  }

  Map<String, dynamic>? rowById(String id) {
    _ensureSeed();
    final row = _rowById(id);
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  List<Map<String, dynamic>> myListings({bool includeArchived = true}) {
    _ensureSeed();
    var list = List<Map<String, dynamic>>.from(_rows);
    if (!includeArchived) {
      list = list.where((r) => r['status'] == 'published').toList();
    }
    list.sort((a, b) {
      final au = a['updated_at']?.toString() ?? '';
      final bu = b['updated_at']?.toString() ?? '';
      return bu.compareTo(au);
    });
    return list;
  }

  List<Map<String, dynamic>> pendingReview() {
    _ensureSeed();
    return _rows
        .where((r) => r['status']?.toString() == 'pending_review')
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  String registerDraft(ListingCreateInput input) {
    _ensureSeed();
    final id = 'trial-draft-${DateTime.now().millisecondsSinceEpoch}';
    final code = 'LB-2026-${(_codeSeq++).toString().padLeft(6, '0')}';
    final now = DateTime.now().toUtc().toIso8601String();
    _rows.insert(0, {
      'id': id,
      'listing_code': code,
      'title': input.title,
      'status': 'draft',
      'listing_type': input.listingType,
      'property_type': input.propertyType,
      'price_net': input.priceNet,
      if (input.priceSaleNet != null && input.priceSaleNet! > 0)
        'price_sale_net': input.priceSaleNet,
      'district': input.district,
      'project_name': input.projectName,
      if (input.promoPriceNet != null && input.promoPriceNet! > 0)
        'price_internal': input.promoPriceNet,
      if (input.promoSalePriceNet != null && input.promoSalePriceNet! > 0)
        'price_sale_promo_net': input.promoSalePriceNet,
      'updated_at': now,
      'owner_exclusive_mandate': input.ownerExclusiveMandate,
      if (input.ownerExclusiveContractDays != null)
        'owner_exclusive_contract_days': input.ownerExclusiveContractDays,
      'agent_exclusive': input.agentExclusive,
      'viewing_access': input.viewingAccess.toJson(),
      ...input.occupancy.toDbFields(
        salePrice: input.priceSaleNet ?? input.priceNet,
      ),
      ...input.petPolicy.toDbFields(),
    });
    return id;
  }

  bool submitForReview(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    row['status'] = 'pending_review';
    row['owner_data_status'] = 'complete';
    row['owner_data_complete'] = true;
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return true;
  }

  bool approveForPublish(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    final now = DateTime.now().toUtc().toIso8601String();
    row['status'] = 'published';
    row['published_at'] = now;
    row['last_bump_at'] = now;
    row['expires_at'] =
        DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String();
    row['updated_at'] = now;
    return true;
  }

  bool rejectToDraft(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    row['status'] = 'draft';
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return true;
  }

  bool bump(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null || row['status'] != 'published') return false;
    _applyBump(row);
    return true;
  }

  bool bumpByCode(String listingCode) {
    _ensureSeed();
    final code = listingCode.trim();
    for (final r in _rows) {
      if (r['listing_code']?.toString() == code) {
        if (r['status'] != 'published') return false;
        _applyBump(r);
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? rowByCode(String listingCode) {
    _ensureSeed();
    final code = listingCode.trim();
    for (final r in _rows) {
      if (r['listing_code']?.toString() == code) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
  }

  void _applyBump(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc().toIso8601String();
    row['last_bump_at'] = now;
    row['expires_at'] =
        DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String();
    row['updated_at'] = now;
  }

  bool archiveRent(String listingId, {required DateTime availableAgain}) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null || row['status'] != 'published') return false;
    final now = DateTime.now().toUtc().toIso8601String();
    row['status'] = 'archived';
    row['closed_at'] = now;
    row['closed_reason'] = 'owner_closed_rent';
    row['available_again'] = availableAgain.toIso8601String().split('T').first;
    row['reuse_blocked'] = false;
    row['updated_at'] = now;
    return true;
  }

  bool archiveRentPermanent(String listingId, {required String reason}) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    final status = row['status']?.toString() ?? '';
    if (status != 'published' && status != 'archived') return false;
    final now = DateTime.now().toUtc().toIso8601String();
    row['status'] = 'archived';
    row['closed_at'] = now;
    row['closed_reason'] = reason;
    row['reuse_blocked'] = true;
    row.remove('available_again');
    row['updated_at'] = now;
    return true;
  }

  bool archiveSale(String listingId, {String? reason}) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null || row['status'] != 'published') return false;
    final now = DateTime.now().toUtc().toIso8601String();
    row['status'] = 'archived';
    row['closed_at'] = now;
    row['closed_reason'] = reason ?? 'sold';
    row['reuse_blocked'] = true;
    row['updated_at'] = now;
    return true;
  }

  bool republishRentEarly(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null || row['status'] != 'archived') return false;
    if (row['listing_type']?.toString() != 'rent') return false;
    final now = DateTime.now().toUtc().toIso8601String();
    row['status'] = 'published';
    row['closed_at'] = null;
    row['closed_reason'] = null;
    row['occupancy_status'] = 'tenanted';
    row['reuse_blocked'] = false;
    _applyBump(row);
    row['updated_at'] = now;
    return true;
  }

  bool updateAvailableAgain(String listingId, DateTime date) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    row['available_again'] = date.toIso8601String().split('T').first;
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return true;
  }

  bool softDelete(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    _rows.remove(row);
    return true;
  }

  Map<String, dynamic>? _rowById(String id) {
    for (final r in _rows) {
      if (r['id'] == id) return r;
    }
    return null;
  }
}
