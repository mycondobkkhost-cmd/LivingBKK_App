import '../data/listing_form_options.dart';
import 'listing_transaction_types.dart';
import 'listing_occupancy.dart';
import 'listing_pet_policy.dart';
import 'listing_viewing_access.dart';

/// ข้อมูลที่เจ้าของกรอก/แก้ไขเมื่อรับทรัพย์จากแอดมิน (ชั้น owner — ไม่ทับ display)
class PropertyCareOwnerDataInput {
  const PropertyCareOwnerDataInput({
    required this.title,
    required this.description,
    required this.priceNet,
    this.priceSaleNet,
    this.promoPriceNet,
    this.promoSalePriceNet,
    this.bedrooms,
    this.bathrooms,
    this.areaSqm,
    this.floorRange,
    this.petPolicy = const ListingPetPolicyInput(),
    this.occupancy = const ListingOccupancyInput(),
    this.viewingAccess = const ListingViewingAccess(),
    this.hashtagIds = const [],
    this.facilityIds = const [],
    this.ownerNote,
    this.listingLanguages = const ['th'],
    this.titleEn,
    this.descriptionEn,
    this.titleZh,
    this.descriptionZh,
  });

  final String title;
  final String description;
  final double priceNet;
  final double? priceSaleNet;
  final double? promoPriceNet;
  final double? promoSalePriceNet;
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqm;
  final String? floorRange;
  final ListingPetPolicyInput petPolicy;
  final ListingOccupancyInput occupancy;
  final ListingViewingAccess viewingAccess;
  final List<String> hashtagIds;
  final List<String> facilityIds;
  final String? ownerNote;
  final List<String> listingLanguages;
  final String? titleEn;
  final String? descriptionEn;
  final String? titleZh;
  final String? descriptionZh;

  static PropertyCareOwnerDataInput fromListingRow(Map<String, dynamic> row) {
    final occStatus = row['occupancy_status']?.toString();
    ListingOccupancyInput occupancy = const ListingOccupancyInput();
    if (occStatus != null && occStatus.isNotEmpty) {
      DateTime? date;
      final raw =
          row['available_again']?.toString() ?? row['available_from']?.toString();
      if (raw != null) date = DateTime.tryParse(raw);
      occupancy = ListingOccupancyInput(
        status: occStatus,
        availableDate: date,
        viewingAllowedDuring: row['viewing_allowed_during'] == true,
        tenantMonthlyRent: (row['monthly_rent_for_yield'] as num?)?.toDouble(),
      );
    }

    ListingViewingAccess viewing = const ListingViewingAccess();
    final accessRaw = row['viewing_access'];
    if (accessRaw is Map) {
      viewing = ListingViewingAccess.fromJson(
        Map<String, dynamic>.from(accessRaw),
      );
    }

    ListingPetPolicyInput pets = const ListingPetPolicyInput();
    final petRaw = row['pet_policy'];
    if (petRaw is Map) {
      pets = ListingPetPolicyInput.fromJson(Map<String, dynamic>.from(petRaw));
    } else if (row['pet_allowed'] == true) {
      pets = const ListingPetPolicyInput(allowed: true, dogsAllowed: true);
    }

    List<String> parseIds(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    List<String> langs = const ['th'];
    final langRaw = row['listing_languages'];
    if (langRaw is List && langRaw.isNotEmpty) {
      langs = langRaw.map((e) => e.toString()).toList();
    }

    return PropertyCareOwnerDataInput(
      title: _seedText(row, [
        'title_owner',
        'title_display',
        'title',
      ]),
      description: _seedText(row, [
        'description_owner',
        'description_display',
        'description_public',
        'description',
      ]),
      priceNet: (row['price_net'] as num?)?.toDouble() ?? 0,
      priceSaleNet: (row['price_sale_net'] as num?)?.toDouble(),
      promoPriceNet: (row['price_internal'] as num?)?.toDouble(),
      promoSalePriceNet: (row['price_sale_promo_net'] as num?)?.toDouble(),
      bedrooms: (row['bedrooms'] as num?)?.toInt(),
      bathrooms: (row['bathrooms'] as num?)?.toInt(),
      areaSqm: (row['area_sqm'] as num?)?.toDouble(),
      floorRange: row['floor_range']?.toString(),
      petPolicy: pets,
      occupancy: occupancy,
      viewingAccess: viewing,
      hashtagIds: parseIds(row['hashtag_ids']),
      facilityIds: parseIds(row['facility_ids']),
      ownerNote: row['owner_note']?.toString(),
      listingLanguages: langs,
      titleEn: row['title_en']?.toString(),
      descriptionEn: row['description_en']?.toString(),
      titleZh: row['title_zh']?.toString(),
      descriptionZh: row['description_zh']?.toString(),
    );
  }

  static String _seedText(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final v = row[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  /// ข้อความแสดงผลที่ทีมลงให้แล้ว (อ้างอิงในขั้นภาพรวม)
  static String displayTitle(Map<String, dynamic> row) =>
      row['title_display']?.toString().trim().isNotEmpty == true
          ? row['title_display']!.toString()
          : row['title']?.toString() ?? '';

  static String displayDescription(Map<String, dynamic> row) =>
      row['description_display']?.toString().trim().isNotEmpty == true
          ? row['description_display']!.toString()
          : row['description_public']?.toString() ??
              row['description']?.toString() ??
              '';

  String composedDescriptionOwner({required bool isEnglish}) {
    final base = description.trim();
    final tags = ListingFormOptions.formatTagsSection(
      hashtagIds,
      facilityIds,
      isEnglish: isEnglish,
    );
    if (tags.isEmpty) return base;
    return base.isEmpty ? tags : '$base\n\n$tags';
  }

  bool isValidFor(String listingType) =>
      title.trim().length >= 5 &&
      description.trim().length >= 20 &&
      priceNet > 0 &&
      (!ListingTransactionTypes.isRentAndSale(listingType) ||
          (priceSaleNet != null && priceSaleNet! > 0)) &&
      occupancy.isValidForListingType(listingType) &&
      petPolicy.typesValidWhenAllowed &&
      (bedrooms != null && bedrooms! > 0) &&
      (bathrooms != null && bathrooms! > 0) &&
      (areaSqm != null && areaSqm! > 0);

  Map<String, dynamic> toListingFields({
    required String listingType,
    required bool isEnglish,
    bool titleChanged = false,
  }) {
    final descOwner = composedDescriptionOwner(isEnglish: isEnglish);
    final contactLeak = ListingContactGuard.containsLeak(descOwner) ||
        ListingContactGuard.containsLeak(title) ||
        (descriptionEn != null &&
            ListingContactGuard.containsLeak(descriptionEn!));
    final titleTrim = title.trim();

    return {
      'listing_type': listingType,
      'title_owner': titleTrim,
      'description_owner': descOwner,
      if (!titleChanged) ...{
        'title': titleTrim,
        'title_display': titleTrim,
      },
      'description_public': descOwner,
      'description_display': descOwner,
      'price_net': priceNet,
      if (ListingTransactionTypes.isRentAndSale(listingType) &&
          priceSaleNet != null &&
          priceSaleNet! > 0)
        'price_sale_net': priceSaleNet
      else
        'price_sale_net': null,
      if (promoPriceNet != null && promoPriceNet! > 0)
        'price_internal': promoPriceNet
      else
        'price_internal': null,
      if (promoSalePriceNet != null && promoSalePriceNet! > 0)
        'price_sale_promo_net': promoSalePriceNet
      else
        'price_sale_promo_net': null,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (areaSqm != null) 'area_sqm': areaSqm,
      if (floorRange != null && floorRange!.trim().isNotEmpty)
        'floor_range': floorRange!.trim(),
      'viewing_access': viewingAccess.toJson(),
      ...petPolicy.toDbFields(),
      ...occupancy.toDbFields(
        salePrice: ListingTransactionTypes.isRentAndSale(listingType)
            ? (priceSaleNet ?? priceNet)
            : priceNet,
      ),
      'hashtag_ids': hashtagIds,
      'facility_ids': facilityIds,
      if (ownerNote != null && ownerNote!.trim().isNotEmpty)
        'owner_note': ownerNote!.trim(),
      'listing_languages': listingLanguages,
      if (titleEn != null && titleEn!.trim().isNotEmpty) 'title_en': titleEn!.trim(),
      if (descriptionEn != null && descriptionEn!.trim().isNotEmpty)
        'description_en': descriptionEn!.trim(),
      if (titleZh != null && titleZh!.trim().isNotEmpty) 'title_zh': titleZh!.trim(),
      if (descriptionZh != null && descriptionZh!.trim().isNotEmpty)
        'description_zh': descriptionZh!.trim(),
      'display_contact_clean': !contactLeak,
      if (contactLeak)
        'display_moderation_flags': ['contact_in_owner_text'],
      // trial / legacy compat
      'description': descOwner,
      if (titleChanged) 'title_review_pending': true,
    };
  }
}

extension ListingOccupancyInputValidation on ListingOccupancyInput {
  bool isValidForListingType(String listingType) {
    if (!ListingOccupancyStatus.needsAvailableDate(status)) return true;
    return availableDate != null;
  }
}

/// ตรวจเบอร์/ไลน์ในข้อความเจ้าของ — ห้ามรั่วไปหน้าบ้าน
abstract final class ListingContactGuard {
  static final _phone = RegExp(r'0[689]\d{8}');
  static final _line = RegExp(
    r'(line\s*id|@\s*line|ไลน์\s*ไอดี|ไอดีไลน์|add\s*line)',
    caseSensitive: false,
  );

  static bool containsLeak(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    return _phone.hasMatch(t.replaceAll(RegExp(r'[\s\-]'), '')) || _line.hasMatch(t);
  }
}
