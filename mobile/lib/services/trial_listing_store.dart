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
        'updated_at': now,
      },
      {
        'id': 'trial-listing-published',
        'listing_code': 'LB-2026-000102',
        'title': 'คอนโด อโศก',
        'status': 'published',
        'listing_type': 'rent',
        'property_type': 'condo',
        'price_net': 28000,
        'district': 'วัฒนา',
        'project_name': 'The Esse Asoke',
        'last_bump_at': now,
        'published_at': now,
        'expires_at':
            DateTime.now().add(const Duration(days: 22)).toUtc().toIso8601String(),
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
        'updated_at': now,
      },
    ]);
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
      'district': input.district,
      'project_name': input.projectName,
      'promo_price_net': input.promoPriceNet,
      'updated_at': now,
      'owner_exclusive_mandate': input.ownerExclusiveMandate,
      if (input.ownerExclusiveContractDays != null)
        'owner_exclusive_contract_days': input.ownerExclusiveContractDays,
      'agent_exclusive': input.agentExclusive,
      'viewing_access': input.viewingAccess.toJson(),
      ...input.occupancy.toDbFields(salePrice: input.priceNet),
      ...input.petPolicy.toDbFields(),
    });
    return id;
  }

  bool submitForReview(String listingId) {
    _ensureSeed();
    final row = _rowById(listingId);
    if (row == null) return false;
    row['status'] = 'pending_review';
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
    final now = DateTime.now().toUtc().toIso8601String();
    row['last_bump_at'] = now;
    row['expires_at'] =
        DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String();
    row['updated_at'] = now;
    return true;
  }

  Map<String, dynamic>? _rowById(String id) {
    for (final r in _rows) {
      if (r['id'] == id) return r;
    }
    return null;
  }
}
