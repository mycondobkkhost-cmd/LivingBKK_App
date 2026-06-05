import '../config/env.dart';
import '../models/admin_dashboard_overview.dart';
import '../models/platform_exclusive_settings.dart';
import '../models/demand_offer_acceptance.dart';
import 'auth_service.dart';
import 'platform_settings_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';

class AdminRepository {
  bool get _ready => SupabaseService.isReady;

  Future<bool> isAdmin() async {
    if (AuthService.instance.isTrialAdmin) return true;
    if (!Env.isConfigured) return true;
    if (Env.trialMode) return true;
    if (!_ready) return false;
    try {
      final uid = SupabaseService.client!.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await SupabaseService.client!
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return row?['role'] == 'admin';
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

  Future<Map<String, dynamic>?> fetchListingMapPoint(String? listingId) async {
    if (listingId == null) return null;
    if (!_ready) {
      return {
        'listing_code': 'RENT-CD-2026-000001',
        'title': 'ทรู ทองหล่อ',
        'lat': 13.7234,
        'lng': 100.5794,
        'district': 'วัฒนา',
      };
    }

    try {
      final row = await SupabaseService.client!
          .from('listings_public')
          .select('listing_code, title, lat, lng, district, project_name')
          .eq('id', listingId)
          .maybeSingle();
      return row;
    } catch (_) {
      return {
        'listing_code': 'RENT-CD-2026-000001',
        'title': 'ทรู ทองหล่อ',
        'lat': 13.7234,
        'lng': 100.5794,
        'district': 'วัฒนา',
      };
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
      final data = await SupabaseService.client!
          .from('platform_stats_daily')
          .select()
          .order('stat_date', ascending: false)
          .limit(days);
      return List<Map<String, dynamic>>.from(data as List);
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
    return true;
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

  Future<void> createDemandPost({
    required String title,
    required String description,
    required String transactionType,
    double? maxPriceNet,
    double? minAreaSqm,
    double? maxDistanceBtsKm,
    String acceptedOffererPolicy = 'owner_and_co_agent',
    String? leadSource,
    bool urgentRush = false,
  }) async {
    if (AuthService.instance.trialSimulatesBackend) return;
    final uid = SupabaseService.client!.auth.currentUser!.id;
    await SupabaseService.client!.from('demand_posts').insert({
      'created_by': uid,
      'title': title,
      'description': description,
      'transaction_type': transactionType,
      'property_type': 'condo',
      'max_price_net': maxPriceNet,
      'min_area_sqm': minAreaSqm,
      'max_distance_bts_km': maxDistanceBtsKm,
      'status': 'open',
      'open_until': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'extra_criteria': {
        'accepted_offerer_policy': acceptedOffererPolicy,
        if (leadSource != null) 'lead_source': leadSource,
        if (urgentRush) DemandBoardPostMeta.urgentRushKey: true,
      },
    });
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
        _countRows('chat_admin_inbox'),
        _countRows('appointments', inColumn: 'status', inValues: ['pending', 'confirmed']),
        _countRows('demand_offers', eq: {'capacity_verified': 'pending'}),
        _countRows('listing_images', eq: {'moderation_status': 'pending'}),
        _countOpenModerationFlags(),
        _countRows('listing_imports', inColumn: 'status', inValues: ['queued', 'draft_ready', 'needs_fix']),
        _countRows('profiles'),
        _countRows('demand_posts', eq: {'status': 'open'}),
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
}
