import '../config/env.dart';
import '../data/error_catalog.dart';
import '../models/analytics_period_stats.dart';
import '../models/analytics_platform_daily.dart';
import 'supabase_service.dart';

class AnalyticsPeriodTotals {
  const AnalyticsPeriodTotals({required this.rows});

  final List<AnalyticsPlatformDaily> rows;

  int sum(int Function(AnalyticsPlatformDaily r) pick) =>
      rows.fold(0, (a, r) => a + pick(r));

  double? avg(double? Function(AnalyticsPlatformDaily r) pick) {
    final vals = rows.map(pick).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }
}

class AnalyticsAdminRepository {
  bool get _ready => SupabaseService.isReady && Env.isConfigured;

  Future<List<AnalyticsPlatformDaily>> platformDaily({int days = 30}) async {
    if (!_ready) return _demoPlatform(days);
    try {
      final data = await SupabaseService.client!
          .from('analytics_platform_daily')
          .select()
          .order('stat_date', ascending: false)
          .limit(days);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) {
        await _tryRefreshRollups(days);
        final retry = await SupabaseService.client!
            .from('analytics_platform_daily')
            .select()
            .order('stat_date', ascending: false)
            .limit(days);
        return _mapPlatform(List<Map<String, dynamic>>.from(retry as List));
      }
      return _mapPlatform(rows);
    } catch (_) {
      return _demoPlatform(days);
    }
  }

  Future<List<AnalyticsDistrictRow>> districtBreakdown({int days = 30}) async {
    if (!_ready) return _demoDistricts();
    try {
      final from = DateTime.now().subtract(Duration(days: days));
      final data = await SupabaseService.client!
          .from('analytics_district_daily')
          .select('district, listing_views, leads_created, appointments_created')
          .gte('stat_date', from.toIso8601String().split('T').first);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final merged = <String, AnalyticsDistrictRow>{};
      for (final raw in rows) {
        final row = AnalyticsDistrictRow.fromJson(raw);
        final prev = merged[row.district];
        merged[row.district] = AnalyticsDistrictRow(
          district: row.district,
          listingViews: (prev?.listingViews ?? 0) + row.listingViews,
          leadsCreated: (prev?.leadsCreated ?? 0) + row.leadsCreated,
          appointmentsCreated: (prev?.appointmentsCreated ?? 0) + row.appointmentsCreated,
        );
      }
      final list = merged.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return list.take(12).toList();
    } catch (_) {
      return _demoDistricts();
    }
  }

  Future<List<AnalyticsChatDailyRow>> chatBreakdown({int days = 30}) async {
    if (!_ready) return _demoChat();
    try {
      final from = DateTime.now().subtract(Duration(days: days));
      final data = await SupabaseService.client!
          .from('analytics_chat_daily')
          .select()
          .gte('stat_date', from.toIso8601String().split('T').first);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final merged = <String, AnalyticsChatDailyRow>{};
      for (final raw in rows) {
        final row = AnalyticsChatDailyRow.fromJson(raw);
        final prev = merged[row.category];
        merged[row.category] = AnalyticsChatDailyRow(
          category: row.category,
          volume: (prev?.volume ?? 0) + row.volume,
          claimed: (prev?.claimed ?? 0) + row.claimed,
          resolved: (prev?.resolved ?? 0) + row.resolved,
          slaBreaches: (prev?.slaBreaches ?? 0) + row.slaBreaches,
          avgClaimMinutes: row.avgClaimMinutes ?? prev?.avgClaimMinutes,
        );
      }
      return merged.values.toList()..sort((a, b) => b.volume.compareTo(a.volume));
    } catch (_) {
      return _demoChat();
    }
  }

  Future<List<AnalyticsListingDailyRow>> topListings({int days = 30, int limit = 15}) async {
    if (!_ready) return _demoListings();
    try {
      final from = DateTime.now().subtract(Duration(days: days));
      final data = await SupabaseService.client!
          .from('analytics_listing_daily')
          .select('listing_id, listing_code, views, shares, chat_starts, leads_created')
          .gte('stat_date', from.toIso8601String().split('T').first);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final merged = <String, AnalyticsListingDailyRow>{};
      for (final raw in rows) {
        final row = AnalyticsListingDailyRow.fromJson(raw);
        final prev = merged[row.listingId];
        merged[row.listingId] = AnalyticsListingDailyRow(
          listingId: row.listingId,
          listingCode: row.listingCode,
          views: (prev?.views ?? 0) + row.views,
          shares: (prev?.shares ?? 0) + row.shares,
          chatStarts: (prev?.chatStarts ?? 0) + row.chatStarts,
          leadsCreated: (prev?.leadsCreated ?? 0) + row.leadsCreated,
        );
      }
      final list = merged.values.toList()
        ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
      return list.take(limit).toList();
    } catch (_) {
      return _demoListings();
    }
  }

  Future<List<AnalyticsListingDailyRow>> ownerListingStats({
    required String ownerId,
    int days = 30,
  }) async {
    if (!_ready) return [];
    try {
      final from = DateTime.now().subtract(Duration(days: days));
      final data = await SupabaseService.client!
          .from('analytics_listing_daily')
          .select('listing_id, listing_code, views, shares, chat_starts, leads_created')
          .eq('owner_id', ownerId)
          .gte('stat_date', from.toIso8601String().split('T').first);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final merged = <String, AnalyticsListingDailyRow>{};
      for (final raw in rows) {
        final row = AnalyticsListingDailyRow.fromJson(raw);
        final prev = merged[row.listingId];
        merged[row.listingId] = AnalyticsListingDailyRow(
          listingId: row.listingId,
          listingCode: row.listingCode,
          views: (prev?.views ?? 0) + row.views,
          shares: (prev?.shares ?? 0) + row.shares,
          chatStarts: (prev?.chatStarts ?? 0) + row.chatStarts,
          leadsCreated: (prev?.leadsCreated ?? 0) + row.leadsCreated,
        );
      }
      return merged.values.toList()
        ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    } catch (_) {
      return [];
    }
  }

  Future<void> refreshRollups({int days = 30}) async {
    if (!_ready) return;
    try {
      await SupabaseService.client!.rpc('refresh_analytics_rollups', params: {
        'p_from': DateTime.now()
            .subtract(Duration(days: days))
            .toIso8601String()
            .split('T')
            .first,
        'p_to': DateTime.now().toIso8601String().split('T').first,
      });
    } catch (_) {}
  }

  Future<List<AnalyticsPeriodStats>> periodStats({
    int periodHours = 24,
    int buckets = 14,
  }) async {
    if (!_ready) return _demoPeriod(periodHours, buckets);
    try {
      await refreshPeriodRollups(periodHours: periodHours, buckets: buckets);
      final data = await SupabaseService.client!
          .from('analytics_period_stats')
          .select()
          .eq('period_hours', periodHours)
          .eq('platform', 'all')
          .order('bucket_start', ascending: false)
          .limit(buckets);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) return _demoPeriod(periodHours, buckets);
      return rows.map(AnalyticsPeriodStats.fromJson).toList();
    } catch (_) {
      return _demoPeriod(periodHours, buckets);
    }
  }

  Future<void> refreshPeriodRollups({
    int periodHours = 24,
    int buckets = 14,
  }) async {
    if (!_ready) return;
    try {
      await SupabaseService.client!.rpc('refresh_analytics_period_rollups', params: {
        'p_period_hours': periodHours,
        'p_buckets': buckets,
      });
    } catch (_) {}
  }

  Future<List<ClientErrorSummaryRow>> errorSummary({int limit = 30}) async {
    if (!_ready) return _demoErrors();
    try {
      final data = await SupabaseService.client!
          .from('client_error_summary')
          .select()
          .limit(limit);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) return _demoErrors();
      return rows.map(ClientErrorSummaryRow.fromJson).toList();
    } catch (_) {
      return _demoErrors();
    }
  }

  Future<void> _tryRefreshRollups(int days) async {
    try {
      await refreshRollups(days: days);
    } catch (_) {}
  }

  List<AnalyticsPlatformDaily> _mapPlatform(List<Map<String, dynamic>> rows) =>
      rows.map(AnalyticsPlatformDaily.fromJson).toList();

  List<AnalyticsPlatformDaily> _demoPlatform(int days) {
    final today = DateTime.now();
    return List.generate(days.clamp(1, 30), (i) {
      final d = today.subtract(Duration(days: i));
      final ds = d.toIso8601String().split('T').first;
      final wave = 1 + (i % 5);
      return AnalyticsPlatformDaily(
        statDate: ds,
        listingViews: 120 * wave + i * 3,
        listingShares: 8 + i % 4,
        chatStarts: 15 + i % 6,
        leadsCreated: 10 + wave,
        leadsAccepted: 3 + i % 3,
        leadsNew: 2 + i % 2,
        appointmentsCreated: 5 + i % 3,
        appointmentsConfirmed: 3 + i % 2,
        eContractsSigned: i % 4,
        newUsers: 4 + i % 3,
        listingsPublished: 2 + i % 2,
        chatSlaBreaches: i % 3,
        chatAvgClaimMinutes: 12 + (i % 8).toDouble(),
        dealsClosed: i % 2,
        gmvClosed: (2500000 * (i % 3)).toDouble(),
      );
    });
  }

  List<AnalyticsDistrictRow> _demoDistricts() => const [
        AnalyticsDistrictRow(
          district: 'วัฒนา',
          listingViews: 420,
          leadsCreated: 38,
          appointmentsCreated: 12,
        ),
        AnalyticsDistrictRow(
          district: 'คลองเตย',
          listingViews: 310,
          leadsCreated: 24,
          appointmentsCreated: 9,
        ),
        AnalyticsDistrictRow(
          district: 'บางนา',
          listingViews: 280,
          leadsCreated: 19,
          appointmentsCreated: 7,
        ),
      ];

  List<AnalyticsChatDailyRow> _demoChat() => const [
        AnalyticsChatDailyRow(
          category: 'viewing_request',
          volume: 42,
          claimed: 38,
          resolved: 30,
          slaBreaches: 3,
          avgClaimMinutes: 18,
        ),
        AnalyticsChatDailyRow(
          category: 'escalation',
          volume: 15,
          claimed: 14,
          resolved: 11,
          slaBreaches: 2,
          avgClaimMinutes: 8,
        ),
        AnalyticsChatDailyRow(
          category: 'discovery',
          volume: 88,
          claimed: 70,
          resolved: 65,
          slaBreaches: 5,
          avgClaimMinutes: 25,
        ),
      ];

  List<AnalyticsPeriodStats> _demoPeriod(int periodHours, int buckets) {
    final now = DateTime.now();
    return List.generate(buckets.clamp(1, 28), (i) {
      final start = now.subtract(Duration(hours: periodHours * (i + 1)));
      return AnalyticsPeriodStats(
        bucketStart: start,
        periodHours: periodHours,
        platform: 'all',
        appInstalls: (i % 3) + 1,
        appUninstalls: i % 5 == 0 ? 1 : 0,
        appOpens: 12 + i * 2,
        clientErrors: i % 4,
        listingViews: 40 + i * 5,
        chatStarts: 3 + i % 4,
        leadsCreated: 2 + i % 3,
        newUsers: 1 + i % 2,
      );
    });
  }

  List<ClientErrorSummaryRow> _demoErrors() => [
        ClientErrorSummaryRow(
          errorKey: 'supabase_network',
          occurrenceCount: 8,
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
          affectedSessions: 6,
          topPlatform: 'web',
        ),
        ClientErrorSummaryRow(
          errorKey: 'maps_key_missing',
          occurrenceCount: 5,
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 5)),
          affectedSessions: 5,
          topPlatform: 'web',
        ),
        ClientErrorSummaryRow(
          errorKey: ErrorCatalog.unknownKey,
          occurrenceCount: 2,
          lastSeenAt: DateTime.now().subtract(const Duration(days: 1)),
          affectedSessions: 2,
          topPlatform: 'ios',
        ),
      ];

  List<AnalyticsListingDailyRow> _demoListings() => const [
        AnalyticsListingDailyRow(
          listingId: 'demo-1',
          listingCode: 'RXT-2401',
          views: 186,
          shares: 12,
          chatStarts: 9,
          leadsCreated: 4,
        ),
        AnalyticsListingDailyRow(
          listingId: 'demo-2',
          listingCode: 'RXT-2402',
          views: 142,
          shares: 8,
          chatStarts: 6,
          leadsCreated: 3,
        ),
      ];
}
