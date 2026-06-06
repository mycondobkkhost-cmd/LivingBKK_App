import '../config/env.dart';
import '../models/admin_dashboard_overview.dart';
import '../models/customer_requirement.dart';
import '../models/platform_exclusive_settings.dart';
import '../models/platform_watermark_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/demand_offer_acceptance.dart';
import 'auth_service.dart';
import 'chat_repository.dart';
import 'platform_settings_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';
import '../utils/phone_suffix_util.dart';

class AdminRepository {
  bool get _ready => SupabaseService.isReady;

  Future<bool> isAdmin() async {
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

  Future<List<Map<String, dynamic>>> allDemandOffers() async {
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('demand_offers')
          .select('*, demand_posts(title, post_code)')
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> recentLeads() async {
    if (!_ready) {
      return List<Map<String, dynamic>>.from(
        [
          {
            'id': 'demo-lead-1',
            'listing_code': 'RENT-CD-2026-000001',
            'transaction_ref': 'LEAD-2026-000001',
            'status': 'routed',
            'seeker_nickname': 'น้องบี',
            'seeker_phone': '0812345678',
            'qualification_json': {
              'viewing_schedule': '5/7/2569 · 15:00 – 18:00 น.',
            },
          },
        ],
      );
    }

    try {
      final data = await SupabaseService.client!
          .from('leads')
          .select(
            'id, listing_id, listing_code, transaction_ref, status, seeker_nickname, seeker_phone, '
            'occupation, move_plan, contract_duration, budget, qualification_json, created_at',
          )
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return List<Map<String, dynamic>>.from(
        [
          {
            'id': 'demo-lead-1',
            'listing_code': 'RENT-CD-2026-000001',
            'transaction_ref': 'LEAD-2026-000001',
            'status': 'routed',
            'seeker_nickname': 'น้องบี',
            'seeker_phone': '0812345678',
            'qualification_json': {
              'viewing_schedule': '5/7/2569 · 15:00 – 18:00 น.',
            },
          },
        ],
      );
    }
  }

  Future<Map<String, dynamic>?> fetchLead(String leadId) async {
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
    return ChatRepository().resolveThreadIdForLead(lead);
  }

  Future<Map<String, dynamic>?> fetchLeadByThreadId(String threadId) async {
    if (threadId.isEmpty) return null;
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
    if (!_ready) {
      return {
        'stat_date': DateTime.now().toIso8601String().split('T').first,
        'lead_count': 12,
        'accepted_count': 4,
        'new_count': 3,
      };
    }

    try {
      final data = await SupabaseService.client!
          .from('lead_stats_daily')
          .select()
          .order('stat_date', ascending: false)
          .limit(7);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) return null;
      return rows.first;
    } catch (_) {
      return {
        'stat_date': DateTime.now().toIso8601String().split('T').first,
        'lead_count': 12,
        'accepted_count': 4,
        'new_count': 3,
      };
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
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('listing_images')
          .select('id, listing_id, public_url, moderation_status, perceptual_hash, created_at, listings(listing_code, title)')
          .eq('moderation_status', 'pending')
          .order('created_at', ascending: false)
          .limit(40);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> openModerationFlags() async {
    if (!_ready) return [];
    try {
      final data = await SupabaseService.client!
          .from('moderation_flags')
          .select('id, listing_id, flag_type, raw_match, created_at, listings(listing_code, title)')
          .filter('resolved_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(40);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> setImageModeration(String imageId, {required bool approved}) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    await SupabaseService.client!.from('listing_images').update({
      'moderation_status': approved ? 'approved' : 'rejected',
    }).eq('id', imageId);
  }

  Future<void> resolveModerationFlag(String flagId) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('moderation_flags').update({
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': uid,
    }).eq('id', flagId);
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
    if (!_ready) return [];
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
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
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

  /// ฝังลายน้ำ PROPPITER ในไฟล์รูปหลังเผยแพร่ (Edge Function)
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
    if (!_ready) return [CustomerRequirement.demo()];
    try {
      final data = await SupabaseService.client!
          .from('customer_requirements')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final rows = (data as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) return [];
      return rows.map(CustomerRequirement.fromRow).toList();
    } catch (_) {
      return [];
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
      dynamic q = SupabaseService.client!.from(table).select('id');
      eq.forEach((k, v) {
        q = q.eq(k, v);
      });
      if (inColumn != null && inValues != null && inValues.isNotEmpty) {
        q = q.inFilter(inColumn, inValues);
      }
      final rows = await q;
      return (rows as List).length;
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

  Future<AdminDashboardOverview> fetchDashboardOverview() async {
    if (!_ready) {
      return AdminDashboardOverview(
        projects: 24,
        listingsPublished: 128,
        listingsTotal: 156,
        leadsTotal: 12,
        leadsNew: 3,
        chatWaiting: 5,
        appointmentsPending: 4,
        offersPending: 2,
        moderationImages: 1,
        moderationFlags: 0,
        importsPending: 0,
        usersTotal: 48,
        demandPostsOpen: 6,
        customerRequirementsPending: 2,
        updatedAt: DateTime.now(),
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
      ]);

      return AdminDashboardOverview(
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
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return AdminDashboardOverview(updatedAt: DateTime.now());
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
}
