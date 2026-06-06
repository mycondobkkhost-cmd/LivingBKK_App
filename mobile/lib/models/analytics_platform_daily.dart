class AnalyticsPlatformDaily {
  const AnalyticsPlatformDaily({
    required this.statDate,
    this.listingImpressions = 0,
    this.listingViews = 0,
    this.listingShares = 0,
    this.mapMarkerTaps = 0,
    this.searches = 0,
    this.chatStarts = 0,
    this.chatEscalations = 0,
    this.chatClaimed = 0,
    this.chatResolved = 0,
    this.chatSlaBreaches = 0,
    this.chatAvgClaimMinutes,
    this.leadsCreated = 0,
    this.leadsNew = 0,
    this.leadsAccepted = 0,
    this.leadsDeclined = 0,
    this.eContractsSigned = 0,
    this.appointmentsCreated = 0,
    this.appointmentsConfirmed = 0,
    this.appointmentsCompleted = 0,
    this.appointmentsCancelled = 0,
    this.listingsPublished = 0,
    this.listingsArchived = 0,
    this.newUsers = 0,
    this.demandPostsOpened = 0,
    this.offersSubmitted = 0,
    this.dealsClosed = 0,
    this.gmvClosed = 0,
  });

  final String statDate;
  final int listingImpressions;
  final int listingViews;
  final int listingShares;
  final int mapMarkerTaps;
  final int searches;
  final int chatStarts;
  final int chatEscalations;
  final int chatClaimed;
  final int chatResolved;
  final int chatSlaBreaches;
  final double? chatAvgClaimMinutes;
  final int leadsCreated;
  final int leadsNew;
  final int leadsAccepted;
  final int leadsDeclined;
  final int eContractsSigned;
  final int appointmentsCreated;
  final int appointmentsConfirmed;
  final int appointmentsCompleted;
  final int appointmentsCancelled;
  final int listingsPublished;
  final int listingsArchived;
  final int newUsers;
  final int demandPostsOpened;
  final int offersSubmitted;
  final int dealsClosed;
  final double gmvClosed;

  factory AnalyticsPlatformDaily.fromJson(Map<String, dynamic> json) {
    final date = json['stat_date'];
    return AnalyticsPlatformDaily(
      statDate: date is DateTime
          ? date.toIso8601String().split('T').first
          : date?.toString().substring(0, 10) ?? '—',
      listingImpressions: _i(json['listing_impressions']),
      listingViews: _i(json['listing_views']),
      listingShares: _i(json['listing_shares']),
      mapMarkerTaps: _i(json['map_marker_taps']),
      searches: _i(json['searches']),
      chatStarts: _i(json['chat_starts']),
      chatEscalations: _i(json['chat_escalations']),
      chatClaimed: _i(json['chat_claimed']),
      chatResolved: _i(json['chat_resolved']),
      chatSlaBreaches: _i(json['chat_sla_breaches']),
      chatAvgClaimMinutes: (json['chat_avg_claim_minutes'] as num?)?.toDouble(),
      leadsCreated: _i(json['leads_created'] ?? json['lead_count']),
      leadsNew: _i(json['leads_new'] ?? json['new_count']),
      leadsAccepted: _i(json['leads_accepted'] ?? json['accepted_count']),
      leadsDeclined: _i(json['leads_declined']),
      eContractsSigned: _i(json['e_contracts_signed']),
      appointmentsCreated: _i(json['appointments_created'] ?? json['appointment_count']),
      appointmentsConfirmed:
          _i(json['appointments_confirmed'] ?? json['appointment_confirmed_count']),
      appointmentsCompleted:
          _i(json['appointments_completed'] ?? json['appointment_completed_count']),
      appointmentsCancelled: _i(json['appointments_cancelled']),
      listingsPublished: _i(json['listings_published']),
      listingsArchived: _i(json['listings_archived']),
      newUsers: _i(json['new_users']),
      demandPostsOpened: _i(json['demand_posts_opened']),
      offersSubmitted: _i(json['offers_submitted']),
      dealsClosed: _i(json['deals_closed']),
      gmvClosed: (json['gmv_closed'] as num?)?.toDouble() ?? 0,
    );
  }

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
}

class AnalyticsDistrictRow {
  const AnalyticsDistrictRow({
    required this.district,
    required this.listingViews,
    required this.leadsCreated,
    required this.appointmentsCreated,
  });

  final String district;
  final int listingViews;
  final int leadsCreated;
  final int appointmentsCreated;

  int get score => listingViews + leadsCreated * 3 + appointmentsCreated * 2;

  factory AnalyticsDistrictRow.fromJson(Map<String, dynamic> json) {
    return AnalyticsDistrictRow(
      district: json['district']?.toString() ?? '—',
      listingViews: (json['listing_views'] as num?)?.toInt() ?? 0,
      leadsCreated: (json['leads_created'] as num?)?.toInt() ?? 0,
      appointmentsCreated: (json['appointments_created'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsChatDailyRow {
  const AnalyticsChatDailyRow({
    required this.category,
    required this.volume,
    required this.claimed,
    required this.resolved,
    required this.slaBreaches,
    this.avgClaimMinutes,
  });

  final String category;
  final int volume;
  final int claimed;
  final int resolved;
  final int slaBreaches;
  final double? avgClaimMinutes;

  factory AnalyticsChatDailyRow.fromJson(Map<String, dynamic> json) {
    return AnalyticsChatDailyRow(
      category: json['category']?.toString() ?? 'other',
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      claimed: (json['claimed'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      slaBreaches: (json['sla_breaches'] as num?)?.toInt() ?? 0,
      avgClaimMinutes: (json['avg_claim_minutes'] as num?)?.toDouble(),
    );
  }
}

class AnalyticsListingDailyRow {
  const AnalyticsListingDailyRow({
    required this.listingId,
    required this.listingCode,
    required this.views,
    required this.shares,
    required this.chatStarts,
    required this.leadsCreated,
  });

  final String listingId;
  final String listingCode;
  final int views;
  final int shares;
  final int chatStarts;
  final int leadsCreated;

  int get engagementScore => views + shares * 2 + chatStarts * 3 + leadsCreated * 5;

  factory AnalyticsListingDailyRow.fromJson(Map<String, dynamic> json) {
    return AnalyticsListingDailyRow(
      listingId: json['listing_id']?.toString() ?? '',
      listingCode: json['listing_code']?.toString() ?? '—',
      views: (json['views'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      chatStarts: (json['chat_starts'] as num?)?.toInt() ?? 0,
      leadsCreated: (json['leads_created'] as num?)?.toInt() ?? 0,
    );
  }
}
