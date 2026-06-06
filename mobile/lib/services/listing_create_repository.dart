import 'package:geolocator/geolocator.dart';

import '../config/legal_config.dart';
import '../models/listing_create_rules.dart';
import '../models/listing_occupancy.dart';
import '../models/listing_pet_policy.dart';
import '../models/listing_viewing_access.dart';
import '../models/offer_commission_scheme.dart';
import 'auth_service.dart';
import 'trial_listing_store.dart';
import 'supabase_service.dart';

class ListingCreateInput {
  const ListingCreateInput({
    required this.title,
    required this.listingType,
    required this.propertyType,
    required this.priceNet,
    required this.district,
    required this.posterRole,
    this.description,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.floorRange,
    this.coAgentListingType,
    this.monthlyRentNet,
    this.promoPriceNet,
    this.videoUrl,
    this.tiktokUrl,
    this.locationLink,
    this.externalPostUrl,
    required this.commissionScheme,
    this.commissionNote,
    this.netReceiveTarget,
    this.transferTerms,
    this.leaseMonths = 12,
    this.projectId,
    this.projectName,
    this.projectSlug,
    this.geoZoneId,
    this.lat,
    this.lng,
    this.btsStation,
    this.acceptCoAgent = true,
    this.petPolicy = const ListingPetPolicyInput(),
    this.lineId,
    this.listingLanguages = const ['th'],
    this.titleEn,
    this.descriptionEn,
    this.titleZh,
    this.descriptionZh,
    this.policyAccepted = false,
    this.ownerExclusiveMandate = false,
    this.ownerExclusiveContractDays,
    this.agentExclusive = false,
    this.viewingAccess = const ListingViewingAccess(),
    this.brokerCommissionPercent,
    this.occupancy = const ListingOccupancyInput(),
  });

  bool get petAllowed => petPolicy.allowed;

  final String title;
  final String listingType;
  final String propertyType;
  final double priceNet;
  final String district;
  final ListingPosterRole posterRole;
  final String? description;
  final double? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final String? floorRange;
  final String? coAgentListingType;
  final double? monthlyRentNet;
  final double? promoPriceNet;
  final String? videoUrl;
  final String? tiktokUrl;
  /// ลิงก์ Google Maps — บังคับเมื่อบ้านนอกโครงการ (เก็บใน source_url)
  final String? locationLink;
  final String? externalPostUrl;
  final String commissionScheme;
  final String? commissionNote;
  final double? netReceiveTarget;
  final String? transferTerms;
  final int leaseMonths;
  final String? projectId;
  final String? projectName;
  final String? projectSlug;
  final String? geoZoneId;
  final double? lat;
  final double? lng;
  final String? btsStation;
  final bool acceptCoAgent;
  final ListingPetPolicyInput petPolicy;
  final String? lineId;
  final List<String> listingLanguages;
  final String? titleEn;
  final String? descriptionEn;
  final String? titleZh;
  final String? descriptionZh;
  final bool policyAccepted;
  final bool ownerExclusiveMandate;
  final int? ownerExclusiveContractDays;
  final bool agentExclusive;
  final ListingViewingAccess viewingAccess;
  /// เมื่อเจ้าของเลือกรับสุทธิ — % ที่นายหน้าบวกเพิ่ม
  final double? brokerCommissionPercent;
  final ListingOccupancyInput occupancy;
}

class ListingCreateRepository {
  Future<String> createDraft(ListingCreateInput input) async {
    if (AuthService.instance.trialSimulatesBackend) {
      await Future.delayed(const Duration(milliseconds: 350));
      return TrialListingStore.instance.registerDraft(input);
    }
    if (!SupabaseService.isReady) {
      throw Exception('ต้องล็อกอินและตั้งค่า Supabase');
    }

    final uid = AuthService.instance.effectiveUserId;
    if (uid == null) {
      throw Exception('ต้องล็อกอินก่อนลงประกาศ');
    }

    double lat;
    double lng;
    if (input.lat != null && input.lng != null) {
      lat = input.lat!;
      lng = input.lng!;
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        lat = 13.7367;
        lng = 100.5608;
      }
    }

    final listedBy = ListingCreateRules.listedByRoleDb(input.posterRole);
    final ownerVerified = ListingCreateRules.ownerVerifiedFor(input.posterRole);

    final payload = <String, dynamic>{
      'owner_id': uid,
      'created_by_id': uid,
      'listed_by_role': listedBy,
      'owner_verified': ownerVerified,
      'title': input.title,
      'listing_type': input.listingType,
      'property_type': input.propertyType,
      'price_net': input.priceNet,
      'district': input.district,
      'description_public': input.description,
      'area_sqm': input.areaSqm,
      'bedrooms': input.bedrooms,
      'bathrooms': input.bathrooms,
      'floor_range': input.floorRange,
      'co_agent_listing_type': input.coAgentListingType,
      'owner_co_agent_opt_in': input.acceptCoAgent,
      'co_agent_eligible': input.acceptCoAgent,
      ...input.petPolicy.toDbFields(),
      'owner_exclusive_mandate': input.ownerExclusiveMandate,
      if (input.ownerExclusiveContractDays != null)
        'owner_exclusive_contract_days': input.ownerExclusiveContractDays,
      if (input.ownerExclusiveMandate) 'owner_exclusive_status': 'interested',
      'agent_exclusive': input.agentExclusive,
      'viewing_access': input.viewingAccess.toJson(),
      ...input.occupancy.toDbFields(salePrice: input.priceNet),
      if (input.promoPriceNet != null) 'price_internal': input.promoPriceNet,
      if (input.videoUrl != null && input.videoUrl!.isNotEmpty)
        'video_url': input.videoUrl,
      if (input.locationLink != null && input.locationLink!.isNotEmpty)
        'source_url': input.locationLink,
      if (input.projectId != null) 'project_id': input.projectId,
      if (input.projectName != null && input.projectName!.isNotEmpty)
        'project_name': input.projectName,
      if (input.geoZoneId != null) 'geo_zone_id': input.geoZoneId,
      'status': 'draft',
      'location_exact': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
      'location_public': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    };

    if (input.btsStation != null && input.btsStation!.isNotEmpty) {
      final desc = payload['description_public'] as String? ?? '';
      final btsLine = 'ใกล้: ${input.btsStation}';
      payload['description_public'] =
          desc.isEmpty ? btsLine : '$desc\n$btsLine';
    }

    if (input.tiktokUrl != null && input.tiktokUrl!.trim().isNotEmpty) {
      final desc = payload['description_public'] as String? ?? '';
      payload['description_public'] = desc.isEmpty
          ? 'TikTok: ${input.tiktokUrl!.trim()}'
          : '$desc\nTikTok: ${input.tiktokUrl!.trim()}';
    }
    payload['description_public'] = _withCommissionBlock(
      _withLocalizationBlock(
        payload['description_public'] as String? ?? '',
        input,
      ),
      input,
    );

    final row = await SupabaseService.client!
        .from('listings')
        .insert(payload)
        .select('id')
        .single();

    return row['id'] as String;
  }

  /// ส่งให้หลังบ้านตรวจ — ยังไม่ขึ้นประกาศสาธารณะ
  Future<void> submitForReview(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) {
      if (!TrialListingStore.instance.submitForReview(listingId)) {
        throw Exception('ไม่พบร่างประกาศ (โหมดทดลอง)');
      }
      return;
    }
    await SupabaseService.client!
        .from('listings')
        .update({
          'status': 'pending_review',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', listingId);
  }

  /// แอดมินอนุมัติแล้ว — ใช้ภายหลัง
  Future<void> publish(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!
        .from('listings')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'last_bump_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at':
              DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
        })
        .eq('id', listingId);
  }
}

String _withLocalizationBlock(String desc, ListingCreateInput input) {
  final lines = <String>[
    if (input.policyAccepted) ...[
      'listing_policy_accepted: true',
      'listing_policy_version: ${LegalConfig.version}',
      'listing_policy_accepted_at: ${DateTime.now().toUtc().toIso8601String()}',
    ],
    if (input.ownerExclusiveMandate) ...[
      'owner_exclusive_mandate: true',
      if (input.ownerExclusiveContractDays != null)
        'owner_exclusive_contract_days: ${input.ownerExclusiveContractDays}',
    ],
    if (input.agentExclusive) 'agent_exclusive: true',
    'listing_langs: ${input.listingLanguages.join(',')}',
    if (input.lineId != null && input.lineId!.trim().isNotEmpty)
      'poster_line_id: ${input.lineId!.trim()}',
    if (input.titleEn != null && input.titleEn!.trim().isNotEmpty)
      'title_en: ${input.titleEn!.trim()}',
    if (input.descriptionEn != null && input.descriptionEn!.trim().isNotEmpty)
      'description_en: ${input.descriptionEn!.trim()}',
    if (input.titleZh != null && input.titleZh!.trim().isNotEmpty)
      'title_zh: ${input.titleZh!.trim()}',
    if (input.descriptionZh != null && input.descriptionZh!.trim().isNotEmpty)
      'description_zh: ${input.descriptionZh!.trim()}',
  ];
  if (lines.isEmpty) return desc;
  final block = lines.join('\n');
  return desc.isEmpty ? block : '$desc\n$block';
}

String _withCommissionBlock(String desc, ListingCreateInput input) {
  final lines = <String>[
    'commission_scheme: ${input.commissionScheme}',
    if (input.commissionNote != null && input.commissionNote!.trim().isNotEmpty)
      'commission_note: ${input.commissionNote!.trim()}',
    if (input.netReceiveTarget != null)
      'net_receive_target: ${input.netReceiveTarget!.toStringAsFixed(0)}',
    if (input.brokerCommissionPercent != null)
      'broker_commission_percent: ${input.brokerCommissionPercent!.toStringAsFixed(2)}',
    if (input.transferTerms != null && input.transferTerms!.trim().isNotEmpty)
      'transfer_terms: ${input.transferTerms!.trim()}',
    if (!OfferCommissionScheme.isSaleListing(input.listingType))
      'lease_months: ${input.leaseMonths}',
  ];
  final block = lines.join('\n');
  return desc.isEmpty ? block : '$desc\n$block';
}
