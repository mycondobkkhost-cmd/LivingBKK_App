import '../config/env.dart';
import '../data/admin_demo_data.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_dashboard_overview.dart';
import '../models/listing_public.dart';
import '../models/customer_requirement.dart';
import '../models/platform_exclusive_settings.dart';
import '../models/platform_watermark_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/demand_offer_acceptance.dart';
import 'auth_service.dart';
import '../data/demo_cast_simulation.dart';
import 'appointment_repository.dart';
import 'demo_cast_bootstrap.dart';
import 'demo_cast_session.dart';
import 'viewing_calendar_alert_service.dart';
import 'chat_repository.dart';
import 'platform_settings_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';
import '../utils/phone_suffix_util.dart';

class AdminRepository {
  bool get _ready => SupabaseService.isReady;

  static const demoAdminEmail = 'demo-admin@livingbkk.local';

  /// `admin` | `lead` | `super` | `ceo` — จาก profiles.admin_tier
  Future<String> fetchAdminTier() async {
    final castTier = DemoCastSession.instance.adminTierOverride();
    if (castTier != null) return castTier;
    if (AuthService.instance.isTrialAdmin || Env.trialMode) return 'ceo';
    final email = AuthService.instance.currentUser?.email?.toLowerCase();
    if (email == demoAdminEmail) return 'ceo';
    if (!Env.isConfigured || Env.trialMode) return 'admin';
    if (!_ready) return 'admin';
    try {
      final uid = SupabaseService.client?.auth.currentUser?.id;
      if (uid == null) return 'admin';
      final row = await SupabaseService.client!
          .from('profiles')
          .select('admin_tier')
          .eq('id', uid)
          .maybeSingle();
      final tier = row?['admin_tier']?.toString() ?? 'admin';
      // migrate legacy DB value
      if (tier == 'standard') return 'admin';
      return tier;
    } catch (_) {
      return 'admin';
    }
  }

  Future<bool> isAdmin() async {
    if (DemoCastSession.instance.isStaffTierCast) return true;
    if (DemoCastSession.instance.isViewingGuideCast) return false;
    if (AuthService.instance.isTrialAdmin) return true;
    if (!Env.isConfigured) return true;
    if (Env.trialMode) return true;
    if (!_ready) return false;
    try {
      final role = await AuthService.instance.fetchProfileRole();
      return role == 'admin';
    } catch (_) {
      return Env.trialMode;
    }
  }

  Future<bool> isViewingStaff() async {
    if (DemoCastSession.instance.isViewingGuideCast) return true;
    if (DemoCastSession.instance.isStaffTierCast) return false;
    if (!Env.isConfigured || Env.trialMode) return false;
    if (!_ready) return false;
    try {
      final role = await AuthService.instance.fetchProfileRole();
      return role == 'viewing_staff';
    } catch (_) {
      return false;
    }
  }

  Future<bool> canAccessBackOffice() async {
    if (DemoCastSession.hubEnabled) return true;
    if (await isAdmin()) return true;
    return isViewingStaff();
  }

  Future<List<Map<String, dynamic>>> allDemandOffers() async {
    if (DemoCastBootstrap.shouldUseCastWorld) {
      return AdminDemoData.demandOffers();
    }
    if (!_ready) return AdminDemoData.demandOffers();
    try {
      final data = await SupabaseService.client!
          .from('demand_offers')
          .select('*, demand_posts(title, post_code)')
          .order('created_at', ascending: false)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) return AdminDemoData.demandOffers();
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? AdminDemoData.demandOffers() : [];
    }
  }

  Future<List<Map<String, dynamic>>> recentLeads() async {
    if (DemoCastBootstrap.shouldUseCastWorld) {
      return DemoCastSimulation.leads();
    }
    if (!_ready) return AdminDemoData.leads();

    try {
      final data = await SupabaseService.client!
          .from('leads')
          .select(
            'id, listing_id, listing_code, transaction_ref, status, seeker_nickname, seeker_phone, '
            'occupation, move_plan, contract_duration, budget, qualification_json, created_at',
          )
          .order('created_at', ascending: false)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) return AdminDemoData.leads();
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? AdminDemoData.leads() : [];
    }
  }

  Future<Map<String, dynamic>?> fetchLead(String leadId) async {
    if (leadId.startsWith('demo-lead')) {
      for (final l in DemoCastSimulation.leads()) {
        if (l['id'] == leadId) return l;
      }
    }
    if (DemoCastBootstrap.shouldUseCastWorld) {
      final leads = await recentLeads();
      for (final l in leads) {
        if (l['id'] == leadId) return l;
      }
      return null;
    }
    if (!_ready) {
      final leads = await recentLeads();
      for (final l in leads) {
        if (l['id'] == leadId) return l;
      }
      return leads.isNotEmpty ? leads.first : null;
    }

    try {
      return await SupabaseService.client!
          .from('leads')
          .select()
          .eq('id', leadId)
          .maybeSingle();
    } catch (_) {
      final leads = await recentLeads();
      for (final l in leads) {
        if (l['id'] == leadId) return l;
      }
      return leads.isNotEmpty ? leads.first : null;
    }
  }

  Future<Map<String, dynamic>?> fetchListingMapPoint(
    String? listingId, {
    String? listingCode,
  }) async {
    if (DemoCastBootstrap.shouldUseCastWorld) {
      return {
        'listing_code': listingCode ?? 'RENT-CD-2026-000001',
        'title': listingCode ?? 'ทรัพย์ตัวอย่าง',
        'lat': 13.7234,
        'lng': 100.5794,
        'district': 'วัฒนา',
        'listing_type': 'rent',
        'price_net': 28000,
      };
    }
    if (!_ready) {
      return {
        'listing_code': listingCode ?? 'RENT-CD-2026-000001',
        'title': 'ทรู ทองหล่อ',
        'lat': 13.7234,
        'lng': 100.5794,
        'district': 'วัฒนา',
      };
    }

    try {
      var query = SupabaseService.client!
          .from('listings_public')
          .select('listing_code, title, lat, lng, district, project_name, price_net, listing_type');
      if (listingId != null && listingId.isNotEmpty) {
        final row = await query.eq('id', listingId).maybeSingle();
        if (row != null) return row;
      }
      if (listingCode != null && listingCode.isNotEmpty) {
        return await query.eq('listing_code', listingCode).maybeSingle();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveLeadThreadId(Map<String, dynamic> lead) async {
    final leadId = lead['id']?.toString();
    if (leadId != null && leadId.startsWith('demo-lead')) {
      return 'demo-lead-chat-$leadId';
    }
    return ChatRepository().resolveThreadIdForLead(lead);
  }

  Future<Map<String, dynamic>?> fetchLeadByThreadId(String threadId) async {
    if (threadId.isEmpty) return null;
    if (threadId.startsWith('demo-lead-chat-demo-lead-')) {
      final leadId = threadId.replaceFirst('demo-lead-chat-', '');
      return fetchLead(leadId);
    }
    if (!_ready) return null;
    try {
      final byThread = await SupabaseService.client!
          .from('leads')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (byThread != null) return byThread;

      final thread = await SupabaseService.client!
          .from('chat_threads')
          .select('listing_code, user_id')
          .eq('id', threadId)
          .maybeSingle();
      if (thread == null) return null;
      final code = thread['listing_code']?.toString();
      final seekerId = thread['user_id']?.toString();
      if (code == null || code.isEmpty || seekerId == null) return null;
      return await SupabaseService.client!
          .from('leads')
          .select()
          .eq('listing_code', code)
          .eq('seeker_id', seekerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> leadStats() async {
    final demo = {
      'stat_date': DateTime.now().toIso8601String().split('T').first,
      ...(DemoCastBootstrap.shouldUseCastWorld
          ? DemoCastSimulation.leadStats()
          : AdminDemoData.leadStats()),
    };
    if (DemoCastBootstrap.shouldUseCastWorld || !_ready) return demo;

    try {
      final data = await SupabaseService.client!
          .from('lead_stats_daily')
          .select()
          .order('stat_date', ascending: false)
          .limit(7);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) return AdminDemoData.enabled ? demo : null;
      return rows.first;
    } catch (_) {
      return AdminDemoData.enabled ? demo : null;
    }
  }

  Future<List<Map<String, dynamic>>> platformStatsHistory({int days = 14}) async {
    if (!_ready) {
      final today = DateTime.now();
      return List.generate(days.clamp(1, 14), (i) {
        final d = today.subtract(Duration(days: i));
        return {
          'stat_date': d.toIso8601String().split('T').first,
          'lead_count': 8 + (i % 4),
          'accepted_count': 2 + (i % 3),
          'new_count': 1 + (i % 2),
          'appointment_count': 3 + (i % 2),
          'appointment_confirmed_count': 2,
          'appointment_completed_count': i % 2,
        };
      });
    }

    try {
      dynamic data = await SupabaseService.client!
          .from('analytics_platform_daily')
          .select()
          .order('stat_date', ascending: false)
          .limit(days);
      var rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) {
        data = await SupabaseService.client!
            .from('platform_stats_daily')
            .select()
            .order('stat_date', ascending: false)
            .limit(days);
        rows = List<Map<String, dynamic>>.from(data as List);
      }
      return rows;
    } catch (_) {
      final today = DateTime.now();
      return List.generate(days.clamp(1, 14), (i) {
        final d = today.subtract(Duration(days: i));
        return {
          'stat_date': d.toIso8601String().split('T').first,
          'lead_count': 8 + (i % 4),
          'accepted_count': 2 + (i % 3),
          'new_count': 1 + (i % 2),
          'appointment_count': 3 + (i % 2),
          'appointment_confirmed_count': 2,
          'appointment_completed_count': i % 2,
        };
      });
    }
  }

  Future<String> buildPlatformStatsTsv({int days = 30}) async {
    final rows = await platformStatsHistory(days: days);
    final buffer = StringBuffer(
      'stat_date\tlead_count\taccepted_count\tnew_count\t'
      'appointment_count\tappointment_confirmed\tappointment_completed\n',
    );
    for (final r in rows.reversed) {
      buffer.writeln(
        '${r['stat_date']}\t${r['lead_count']}\t${r['accepted_count']}\t'
        '${r['new_count']}\t${r['appointment_count']}\t'
        '${r['appointment_confirmed_count']}\t${r['appointment_completed_count']}',
      );
    }
    return buffer.toString();
  }

  Future<void> verifyOfferCapacity(String offerId, {required bool approved}) async {
    if (offerId.toString().startsWith('demo-offer-')) return;
    if (AuthService.instance.trialSimulatesBackend) return;
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('demand_offers').update({
      'capacity_verified': approved ? 'verified' : 'rejected',
      'capacity_verified_by': uid,
      'capacity_verified_at': DateTime.now().toUtc().toIso8601String(),
      'status': approved ? 'under_review' : 'rejected',
    }).eq('id', offerId);
  }

  Future<List<Map<String, dynamic>>> pendingListingImages() async {
    if (!_ready) return AdminDemoData.pendingListingImages();
    try {
      final data = await SupabaseService.client!
          .from('listing_images')
          .select('id, listing_id, public_url, moderation_status, perceptual_hash, created_at, listings(listing_code, title)')
          .eq('moderation_status', 'pending')
          .order('created_at', ascending: false)
          .limit(40);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) return AdminDemoData.pendingListingImages();
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? AdminDemoData.pendingListingImages() : [];
    }
  }

  Future<List<Map<String, dynamic>>> openModerationFlags() async {
    if (!_ready) return AdminDemoData.openModerationFlags();
    try {
      final data = await SupabaseService.client!
          .from('moderation_flags')
          .select('id, listing_id, flag_type, raw_match, created_at, listings(listing_code, title)')
          .filter('resolved_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(40);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) return AdminDemoData.openModerationFlags();
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? AdminDemoData.openModerationFlags() : [];
    }
  }

  Future<void> setImageModeration(String imageId, {required bool approved}) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!.from('listing_images').update({
      'moderation_status': approved ? 'approved' : 'rejected',
    }).eq('id', imageId);
  }

  /// รูปต้นฉบับใน Storage (`storage_path`) — ไม่มีลายน้ำ
  Future<List<Map<String, dynamic>>> listingImageOriginals(String listingId) async {
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('listing_images')
          .select('id, storage_path, sort_order, watermark_applied_at')
          .eq('listing_id', listingId)
          .neq('moderation_status', 'rejected')
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> resolveModerationFlag(String flagId) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('moderation_flags').update({
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': uid,
    }).eq('id', flagId);
  }

  Future<void> adminBumpListing(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!.from('listings').update({
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'last_reminder_at': null,
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'status': 'published',
    }).eq('id', listingId);
    await _audit('listing.admin_bump', listingId);
  }

  Future<void> forceHideListing(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!.from('listings').update({
      'status': 'hidden',
    }).eq('id', listingId);
    await _audit('listing.force_hide', listingId);
  }

  Future<List<Map<String, dynamic>>> pendingReviewListings() async {
    if (AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.pendingReview();
    }
    if (!_ready) return TrialListingStore.instance.pendingReview();
    try {
      final data = await SupabaseService.client!
          .from('listings')
          .select(
            'id, listing_code, title, listing_type, property_type, price_net, '
            'district, project_name, status, created_at, listed_by_role',
          )
          .eq('status', 'pending_review')
          .order('created_at', ascending: false)
          .limit(40);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) {
        return TrialListingStore.instance.pendingReview();
      }
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? TrialListingStore.instance.pendingReview() : [];
    }
  }

  /// โหลดประกาศสำหรับพรีวิวหน้าบ้าน (รวม pending / draft — ไม่ผ่าน listings_public)
  Future<ListingPublic?> fetchListingForPublicPreview(
    String listingId, {
    String? titleOverride,
    String? descriptionOverride,
  }) async {
    final trimmed = listingId.trim();
    if (trimmed.isEmpty) return null;

    if (AuthService.instance.trialSimulatesBackend) {
      Map<String, dynamic>? row;
      for (final r in TrialListingStore.instance.myListings(includeArchived: true)) {
        if (r['id']?.toString() == trimmed) {
          row = r;
          break;
        }
      }
      if (row == null) return null;
      return _listingPublicFromRow(
        row,
        _trialPreviewImageUrls(trimmed),
        titleOverride: titleOverride,
        descriptionOverride: descriptionOverride,
      );
    }

    if (!_ready) return null;
    try {
      final row = await SupabaseService.client!
          .from('listings')
          .select()
          .eq('id', trimmed)
          .maybeSingle();
      if (row == null) return null;

      final imageRows = await SupabaseService.client!
          .from('listing_images')
          .select('public_url, moderation_status, sort_order')
          .eq('listing_id', trimmed)
          .neq('moderation_status', 'rejected')
          .order('sort_order', ascending: true);

      final urls = <String>[];
      for (final img in imageRows as List) {
        final url = (img as Map)['public_url']?.toString().trim();
        if (url != null && url.isNotEmpty) urls.add(url);
      }

      return _listingPublicFromRow(
        Map<String, dynamic>.from(row),
        urls,
        titleOverride: titleOverride,
        descriptionOverride: descriptionOverride,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _trialPreviewImageUrls(String listingId) {
    return List.generate(
      4,
      (i) => 'https://picsum.photos/seed/$listingId-$i/800/600',
    );
  }

  ListingPublic _listingPublicFromRow(
    Map<String, dynamic> row,
    List<String> imageUrls, {
    String? titleOverride,
    String? descriptionOverride,
  }) {
    final merged = Map<String, dynamic>.from(row);
    merged['image_urls'] = imageUrls;
    if (titleOverride != null && titleOverride.isNotEmpty) {
      merged['title'] = titleOverride;
    }
    if (descriptionOverride != null) {
      merged['description'] = descriptionOverride;
    }
    return ListingPublic.fromJson(merged);
  }

  Future<bool> approveListingForPublish(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.approveForPublish(listingId);
    }
    await SupabaseService.client!.from('listings').update({
      'status': 'published',
      'published_at': DateTime.now().toUtc().toIso8601String(),
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
    }).eq('id', listingId);
    await _audit('listing.approve_publish', listingId);
    await _watermarkPublishedImages(listingId);
    return true;
  }

  /// ฝังลายน้ำ RealXtate ในไฟล์รูปหลังเผยแพร่ (Edge Function)
  Future<Map<String, dynamic>?> _watermarkPublishedImages(String listingId) async {
    if (!_ready) return null;
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'listing-watermark-images',
        body: {'listing_id': listingId},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> rejectListingToDraft(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.rejectToDraft(listingId);
    }
    await SupabaseService.client!.from('listings').update({
      'status': 'draft',
    }).eq('id', listingId);
    await _audit('listing.reject_to_draft', listingId);
    return true;
  }

  Future<Map<String, dynamic>?> runLifecycleCron() async {
    if (!_ready) return {'demo': true, 'expired': 0, 'hidden_stale': 0};
    final res = await SupabaseService.client!.functions.invoke(
      'listing-lifecycle-cron',
    );
    return res.data as Map<String, dynamic>?;
  }

  Future<void> _audit(String action, String entityId) async {
    final uid = SupabaseService.client?.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await SupabaseService.client!.from('admin_audit_log').insert({
        'actor_id': uid,
        'action': action,
        'entity_type': 'listing',
        'entity_id': entityId,
      });
    } catch (_) {}
  }

  Future<String?> createDemandPost({
    required String title,
    required String description,
    required String transactionType,
    String propertyType = 'condo',
    List<String> zones = const [],
    double? maxPriceNet,
    double? minAreaSqm,
    double? maxDistanceBtsKm,
    String acceptedOffererPolicy = 'owner_and_co_agent',
    String? leadSource,
    String? customerRequirementId,
    String? customerPhoneLast4,
    bool urgentRush = false,
  }) async {
    if (AuthService.instance.trialSimulatesBackend) {
      return 'demo-demand-${DateTime.now().millisecondsSinceEpoch}';
    }
    final uid = SupabaseService.client!.auth.currentUser!.id;
    String? seekerUserId;
    if (customerRequirementId != null) {
      final req = await SupabaseService.client!
          .from('customer_requirements')
          .select('user_id')
          .eq('id', customerRequirementId)
          .maybeSingle();
      seekerUserId = req?['user_id']?.toString();
    }

    final row = await SupabaseService.client!
        .from('demand_posts')
        .insert({
          'created_by': uid,
          if (seekerUserId != null) 'seeker_user_id': seekerUserId,
          'title': title,
          'description': description,
          'transaction_type': transactionType,
          'property_type': propertyType,
          'zones': zones,
          'max_price_net': maxPriceNet,
          'min_area_sqm': minAreaSqm,
          'max_distance_bts_km': maxDistanceBtsKm,
          'status': 'open',
          'open_until':
              DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
          'extra_criteria': {
            'accepted_offerer_policy': acceptedOffererPolicy,
            if (leadSource != null) 'lead_source': leadSource,
            if (customerRequirementId != null)
              'customer_requirement_id': customerRequirementId,
            if (customerPhoneLast4 != null)
              DemandBoardPostMeta.customerPhoneLast4Key: customerPhoneLast4,
            if (urgentRush) DemandBoardPostMeta.urgentRushKey: true,
          },
        })
        .select('id, post_code')
        .single();
    return row['id']?.toString();
  }

  Future<List<CustomerRequirement>> listPendingCustomerRequirements() async {
    if (!_ready) return AdminDemoRequirementStore.instance.listPending();
    try {
      final data = await SupabaseService.client!
          .from('customer_requirements')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final rows = (data as List).cast<Map<String, dynamic>>();
      if (AdminDemoData.useWhenEmpty(rows)) {
        return AdminDemoRequirementStore.instance.listPending();
      }
      return rows.map(CustomerRequirement.fromRow).toList();
    } catch (_) {
      return AdminDemoData.enabled
          ? AdminDemoRequirementStore.instance.listPending()
          : [];
    }
  }

  Future<String?> publishCustomerRequirementAsBoard({
    required String requirementId,
    required String title,
    required String description,
    required String transactionType,
    String propertyType = 'condo',
    List<String> zones = const [],
    double? maxPriceNet,
    double? minAreaSqm,
    double? maxDistanceBtsKm,
    bool urgentRush = false,
    String? requesterRole,
    String? contactPhone,
  }) async {
    final isAgentLead = requesterRole == 'agent';
    final phoneLast4 = PhoneSuffixUtil.last4(contactPhone);
    final postId = await createDemandPost(
      title: title,
      description: description,
      transactionType: transactionType,
      propertyType: propertyType,
      zones: zones,
      maxPriceNet: maxPriceNet,
      minAreaSqm: minAreaSqm,
      maxDistanceBtsKm: maxDistanceBtsKm,
      leadSource: isAgentLead ? 'co_agent_sourced' : 'customer_direct',
      customerRequirementId: requirementId,
      customerPhoneLast4: isAgentLead ? phoneLast4 : null,
      urgentRush: urgentRush,
    );
    if (postId == null) return null;
    if (AdminDemoRequirementStore.instance.isDemoId(requirementId)) {
      AdminDemoRequirementStore.instance.markPublished(requirementId);
      return postId;
    }
    if (!AuthService.instance.trialSimulatesBackend) {
      await SupabaseService.client!.from('customer_requirements').update({
        'status': 'published',
        'demand_post_id': postId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', requirementId);

      try {
        final post = await SupabaseService.client!
            .from('demand_posts')
            .select('post_code, title')
            .eq('id', postId)
            .single();
        await SupabaseService.client!.functions.invoke(
          'chat-notify-requirement-published',
          body: {
            'requirement_id': requirementId,
            'post_code': post['post_code'],
            'post_title': post['title'],
          },
        );
      } catch (_) {
        /* non-fatal */
      }
    }
    return postId;
  }

  Future<List<Map<String, dynamic>>> listOffersForDemandPost(
    String demandPostId,
  ) async {
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('demand_offers')
          .select(
            'id, offer_code, title, price_net, status, offerer_capacity, listing_id, created_at',
          )
          .eq('demand_post_id', demandPostId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> promoteDemandOffer(String offerId) async {
    if (!_ready) return null;
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'promote-demand-offer',
        body: {'offer_id': offerId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'promote failed');
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> closeCustomerRequirement(String requirementId) async {
    if (AdminDemoRequirementStore.instance.isDemoId(requirementId)) {
      AdminDemoRequirementStore.instance.close(requirementId);
      return;
    }
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!.from('customer_requirements').update({
      'status': 'closed',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requirementId);
  }

  Future<List<Map<String, dynamic>>> listChatFaqRules() async {
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('chat_faq_rules')
          .select('id, scope, patterns, reply_text, priority, is_active')
          .order('priority', ascending: true);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> updateChatFaqRule(
    String id, {
    String? replyText,
    bool? isActive,
  }) async {
    if (!_ready) return;
    final patch = <String, dynamic>{};
    if (replyText != null) patch['reply_text'] = replyText;
    if (isActive != null) patch['is_active'] = isActive;
    if (patch.isEmpty) return;
    await SupabaseService.client!.from('chat_faq_rules').update(patch).eq('id', id);
  }

  Future<int> _countRows(
    String table, {
    Map<String, dynamic> eq = const {},
    String? inColumn,
    List<String>? inValues,
  }) async {
    if (!_ready) return 0;
    try {
      dynamic q = SupabaseService.client!.from(table).count(CountOption.exact);
      eq.forEach((k, v) {
        q = q.eq(k, v);
      });
      if (inColumn != null && inValues != null && inValues.isNotEmpty) {
        q = q.inFilter(inColumn, inValues);
      }
      final count = await q;
      return count is int ? count : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countOpenModerationFlags() async {
    if (!_ready) return 0;
    try {
      final rows = await SupabaseService.client!
          .from('moderation_flags')
          .select('id')
          .filter('resolved_at', 'is', null);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// นับแชทรอรับงาน (ยังไม่มีผู้รับผิดชอบ)
  Future<int> _countAvailabilityAlertsDue() async {
    if (!_ready) return 2;
    try {
      final now = DateTime.now();
      final end = now.add(const Duration(days: 30));
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final rows = await SupabaseService.client!
          .from('listings')
          .select('id')
          .gte('available_again', fmt(now))
          .lte('available_again', fmt(end));
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countChatWaiting() async {
    if (!_ready) return 0;
    try {
      final rows = await SupabaseService.client!
          .from('chat_threads')
          .select('id')
          .eq('admin_reply_done', false)
          .isFilter('assigned_admin_id', null)
          .or(
            'viewing_submitted.eq.true,admin_escalated.eq.true,status.eq.waiting_admin,'
            'category.in.(escalation,viewing_request,demand_offer,discovery,staff_support,customer_requirement,booking_interest)',
          );
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  AdminDashboardOverview _demoDashboardBaseline() => AdminDashboardOverview(
        projects: 24,
        listingsPublished: 128,
        listingsTotal: 156,
        leadsTotal: 12,
        leadsNew: 3,
        chatWaiting: 5,
        appointmentsPending: 4,
        offersPending: 2,
        moderationImages: 2,
        moderationFlags: 1,
        importsPending: 2,
        usersTotal: 48,
        demandPostsOpen: 6,
        customerRequirementsPending: AdminDemoRequirementStore.instance.listPending().length,
        availabilityAlertsDue: 3,
        updatedAt: DateTime.now(),
      );

  AdminDashboardOverview _mergeDemoDashboard(AdminDashboardOverview live) {
    if (!AdminDemoData.enabled) return live;
    final base = _demoDashboardBaseline();
    int pick(int liveVal, int demoVal) => liveVal > 0 ? liveVal : demoVal;
    return AdminDashboardOverview(
      projects: pick(live.projects, base.projects),
      listingsPublished: pick(live.listingsPublished, base.listingsPublished),
      listingsTotal: pick(live.listingsTotal, base.listingsTotal),
      leadsTotal: pick(live.leadsTotal, base.leadsTotal),
      leadsNew: pick(live.leadsNew, base.leadsNew),
      chatWaiting: pick(live.chatWaiting, base.chatWaiting),
      appointmentsPending: pick(live.appointmentsPending, base.appointmentsPending),
      offersPending: pick(live.offersPending, base.offersPending),
      moderationImages: pick(live.moderationImages, base.moderationImages),
      moderationFlags: pick(live.moderationFlags, base.moderationFlags),
      importsPending: pick(live.importsPending, base.importsPending),
      usersTotal: pick(live.usersTotal, base.usersTotal),
      demandPostsOpen: pick(live.demandPostsOpen, base.demandPostsOpen),
      customerRequirementsPending: pick(
        live.customerRequirementsPending,
        AdminDemoRequirementStore.instance.listPending().length,
      ),
      availabilityAlertsDue: pick(live.availabilityAlertsDue, base.availabilityAlertsDue),
      updatedAt: DateTime.now(),
    );
  }

  Future<AdminDashboardOverview> _castWorldDashboardOverview(int calBadge) async {
    final stats = DemoCastSimulation.leadStats();
    final appts = await AppointmentRepository().fetchUpcoming(limit: 200);
    final pendingAppts = appts
        .where((a) => a.status == 'pending' || a.status == 'confirmed')
        .length;
    final base = _demoDashboardBaseline();
    return AdminDashboardOverview(
      projects: base.projects,
      listingsPublished: base.listingsPublished,
      listingsTotal: base.listingsTotal,
      leadsTotal: stats['lead_count'] as int,
      leadsNew: stats['new_count'] as int,
      chatWaiting: DemoCastSimulation.inboxWaitingCount(),
      appointmentsPending: pendingAppts,
      offersPending: base.offersPending,
      moderationImages: base.moderationImages,
      moderationFlags: base.moderationFlags,
      importsPending: base.importsPending,
      usersTotal: base.usersTotal,
      demandPostsOpen: base.demandPostsOpen,
      customerRequirementsPending: base.customerRequirementsPending,
      availabilityAlertsDue: base.availabilityAlertsDue,
      viewingCalendarAttention: calBadge,
      updatedAt: DateTime.now(),
    );
  }

  Future<int> _viewingCalendarAttentionCount() async {
    if (!AdminDemoData.enabled) return 0;
    try {
      final appts = await AppointmentRepository().fetchUpcoming(limit: 200);
      final alerts = await ViewingCalendarAlertService.analyze(
        appts.where((a) => a.status != 'cancelled').toList(),
      );
      return alerts.navBadgeCount;
    } catch (_) {
      return 0;
    }
  }

  Future<AdminDashboardOverview> fetchDashboardOverview() async {
    final calBadge = await _viewingCalendarAttentionCount();
    if (DemoCastBootstrap.shouldUseCastWorld) {
      return _castWorldDashboardOverview(calBadge);
    }
    if (!_ready) {
      return _demoDashboardBaseline().copyWith(
        viewingCalendarAttention: calBadge,
      );
    }

    try {
      final results = await Future.wait([
        _countRows('property_projects', eq: {'is_active': true}),
        _countRows('listings', eq: {'status': 'published'}),
        _countRows('listings'),
        _countRows('leads'),
        _countRows('leads', eq: {'status': 'new'}),
        _countChatWaiting(),
        _countRows('appointments', inColumn: 'status', inValues: ['pending', 'confirmed']),
        _countRows('demand_offers', eq: {'capacity_verified': 'pending'}),
        _countRows('listing_images', eq: {'moderation_status': 'pending'}),
        _countOpenModerationFlags(),
        _countRows('listing_imports', inColumn: 'status', inValues: ['queued', 'draft_ready', 'needs_fix']),
        _countRows('profiles'),
        _countRows('demand_posts', eq: {'status': 'open'}),
        _countRows('customer_requirements', eq: {'status': 'pending'}),
        _countAvailabilityAlertsDue(),
      ]);

      return _mergeDemoDashboard(
        AdminDashboardOverview(
          projects: results[0],
          listingsPublished: results[1],
          listingsTotal: results[2],
          leadsTotal: results[3],
          leadsNew: results[4],
          chatWaiting: results[5],
          appointmentsPending: results[6],
          offersPending: results[7],
          moderationImages: results[8],
          moderationFlags: results[9],
          importsPending: results[10],
          usersTotal: results[11],
          demandPostsOpen: results[12],
          customerRequirementsPending: results[13],
          availabilityAlertsDue: results[14],
          viewingCalendarAttention: calBadge,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      final base = AdminDemoData.enabled
          ? _demoDashboardBaseline()
          : AdminDashboardOverview(updatedAt: DateTime.now());
      return base.copyWith(viewingCalendarAttention: calBadge);
    }
  }

  Future<void> updateExclusiveSettings(PlatformExclusiveSettings settings) async {
    if (!_ready) {
      PlatformSettingsService.instance.applyExclusive(settings);
      return;
    }
    await SupabaseService.client!
        .from('app_platform_settings')
        .upsert({'id': 'default', ...settings.toUpdatePayload()});
  }

  Future<PlatformWatermarkSettings> fetchWatermarkSettings() async {
    if (!_ready) return PlatformWatermarkSettings.defaults;
    try {
      final row = await SupabaseService.client!
          .from('app_platform_settings')
          .select(
            'listing_watermark_enabled, listing_watermark_storage_path, '
            'listing_watermark_public_url, listing_watermark_opacity, '
            'listing_watermark_size_ratio',
          )
          .eq('id', 'default')
          .maybeSingle();
      if (row == null) return PlatformWatermarkSettings.defaults;
      return PlatformWatermarkSettings.fromJson(row);
    } catch (_) {
      return PlatformWatermarkSettings.defaults;
    }
  }

  Future<PlatformWatermarkSettings> uploadListingWatermark(XFile file) async {
    if (!_ready) {
      throw Exception('ต้องเชื่อม Supabase และล็อกอินแอดมิน');
    }
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'png';
    final safeExt = {'png', 'jpg', 'jpeg', 'webp'}.contains(ext) ? ext : 'png';
    final path = 'watermark/listing-watermark.$safeExt';

    final mime = safeExt == 'png'
        ? 'image/png'
        : safeExt == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await SupabaseService.client!.storage.from('brand-assets').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );

    final publicUrl =
        SupabaseService.client!.storage.from('brand-assets').getPublicUrl(path);

    final current = await fetchWatermarkSettings();
    final next = PlatformWatermarkSettings(
      enabled: true,
      storagePath: path,
      publicUrl: publicUrl,
      opacity: current.opacity,
      sizeRatio: current.sizeRatio,
    );

    await SupabaseService.client!.from('app_platform_settings').upsert({
      'id': 'default',
      ...next.toUpdatePayload(),
    });

    PlatformSettingsService.instance.applyWatermark(next);
    await _audit('settings.watermark_upload', 'default');
    return next;
  }

  Future<PlatformWatermarkSettings> saveWatermarkSettings(
    PlatformWatermarkSettings settings,
  ) async {
    if (!_ready) {
      PlatformSettingsService.instance.applyWatermark(settings);
      return settings;
    }
    await SupabaseService.client!.from('app_platform_settings').upsert({
      'id': 'default',
      ...settings.toUpdatePayload(),
    });
    PlatformSettingsService.instance.applyWatermark(settings);
    await _audit('settings.watermark_save', 'default');
    return settings;
  }

  Future<void> clearListingWatermark() async {
    if (!_ready) return;
    final current = await fetchWatermarkSettings();
    await SupabaseService.client!.from('app_platform_settings').update({
      'listing_watermark_storage_path': null,
      'listing_watermark_public_url': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', 'default');
    final next = PlatformWatermarkSettings(
      enabled: current.enabled,
      opacity: current.opacity,
      sizeRatio: current.sizeRatio,
    );
    PlatformSettingsService.instance.applyWatermark(next);
    await _audit('settings.watermark_clear', 'default');
  }

  /// บันทึก audit ย้อนหลัง — super+ ใน Governance / รายงาน
  Future<List<AdminAuditEntry>> fetchAuditLog({int limit = 80}) async {
    if (AuthService.instance.trialSimulatesBackend || !Env.isConfigured) {
      return _demoAuditLog();
    }
    if (!_ready) return _demoAuditLog();
    try {
      final rows = await SupabaseService.client!
          .from('admin_audit_log')
          .select('id, action, entity_type, entity_id, payload, created_at, actor:profiles!actor_id(display_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .whereType<Map>()
          .map((r) => _auditFromRow(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      return _demoAuditLog();
    }
  }

  List<AdminAuditEntry> _demoAuditLog() {
    final now = DateTime.now();
    return [
      AdminAuditEntry(
        id: 'demo-audit-1',
        action: 'vault.browse',
        entityType: 'listing_import',
        entityId: 'demo-import-1',
        actorName: 'Demo Admin',
        createdAt: now.subtract(const Duration(hours: 2)),
        payload: {'scope': 'contact_private'},
      ),
      AdminAuditEntry(
        id: 'demo-audit-2',
        action: 'access.approve',
        entityType: 'listing',
        entityId: 'demo-listing-1',
        actorName: 'Super Admin',
        createdAt: now.subtract(const Duration(hours: 5)),
        payload: {'scopes': ['contact.phone'], 'hours': 48},
      ),
      AdminAuditEntry(
        id: 'demo-audit-3',
        action: 'listing.reject_to_draft',
        entityType: 'listing',
        entityId: 'demo-listing-2',
        actorName: 'Ops Admin',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  AdminAuditEntry _auditFromRow(Map<String, dynamic> row) {
    final actor = row['actor'];
    String? name;
    if (actor is Map) {
      name = actor['display_name']?.toString();
    }
    final payloadRaw = row['payload'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};
    return AdminAuditEntry(
      id: row['id']?.toString() ?? '',
      action: row['action']?.toString() ?? '',
      entityType: row['entity_type']?.toString() ?? '',
      entityId: row['entity_id']?.toString(),
      actorName: name,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      payload: payload,
    );
  }
}
