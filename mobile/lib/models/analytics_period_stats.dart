import '../data/error_catalog.dart';

class AnalyticsPeriodStats {
  const AnalyticsPeriodStats({
    required this.bucketStart,
    required this.periodHours,
    required this.platform,
    required this.appInstalls,
    required this.appUninstalls,
    required this.appOpens,
    required this.clientErrors,
    required this.listingViews,
    required this.chatStarts,
    required this.leadsCreated,
    required this.newUsers,
  });

  final DateTime bucketStart;
  final int periodHours;
  final String platform;
  final int appInstalls;
  final int appUninstalls;
  final int appOpens;
  final int clientErrors;
  final int listingViews;
  final int chatStarts;
  final int leadsCreated;
  final int newUsers;

  factory AnalyticsPeriodStats.fromJson(Map<String, dynamic> json) {
    return AnalyticsPeriodStats(
      bucketStart: DateTime.parse(json['bucket_start'] as String),
      periodHours: (json['period_hours'] as num).toInt(),
      platform: json['platform'] as String? ?? 'all',
      appInstalls: (json['app_installs'] as num?)?.toInt() ?? 0,
      appUninstalls: (json['app_uninstalls'] as num?)?.toInt() ?? 0,
      appOpens: (json['app_opens'] as num?)?.toInt() ?? 0,
      clientErrors: (json['client_errors'] as num?)?.toInt() ?? 0,
      listingViews: (json['listing_views'] as num?)?.toInt() ?? 0,
      chatStarts: (json['chat_starts'] as num?)?.toInt() ?? 0,
      leadsCreated: (json['leads_created'] as num?)?.toInt() ?? 0,
      newUsers: (json['new_users'] as num?)?.toInt() ?? 0,
    );
  }

  String get bucketLabel {
    final d = bucketStart;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:00';
  }
}

class ClientErrorSummaryRow {
  const ClientErrorSummaryRow({
    required this.errorKey,
    required this.occurrenceCount,
    required this.lastSeenAt,
    required this.affectedSessions,
    required this.topPlatform,
  });

  final String errorKey;
  final int occurrenceCount;
  final DateTime? lastSeenAt;
  final int affectedSessions;
  final String? topPlatform;

  factory ClientErrorSummaryRow.fromJson(Map<String, dynamic> json) {
    return ClientErrorSummaryRow(
      errorKey: json['error_key'] as String? ?? ErrorCatalog.unknownKey,
      occurrenceCount: (json['occurrence_count'] as num?)?.toInt() ?? 0,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'] as String)
          : null,
      affectedSessions: (json['affected_sessions'] as num?)?.toInt() ?? 0,
      topPlatform: json['top_platform'] as String?,
    );
  }
}
