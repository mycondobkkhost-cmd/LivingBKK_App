/// ตั้งค่า Exclusive จาก `app_platform_settings` (แอดมินแก้หลังบ้าน)
class PlatformExclusiveSettings {
  const PlatformExclusiveSettings({
    this.rentBumpHours = 6,
    this.saleBumpHours = 24,
    this.ownerFeedBoost = 45,
    this.agentFeedBoost = 55,
    this.hotBadgeEnabled = true,
    this.hotViewsPerHourThreshold = 100,
  });

  final int rentBumpHours;
  final int saleBumpHours;
  final int ownerFeedBoost;
  final int agentFeedBoost;
  /// เปิดป้าย HOT บนการ์ดประกาศแนะนำ
  final bool hotBadgeEnabled;
  /// วิวขั้นต่ำใน 1 ชม. สำหรับแสดงป้าย HOT
  final int hotViewsPerHourThreshold;

  static const defaults = PlatformExclusiveSettings();

  factory PlatformExclusiveSettings.fromJson(Map<String, dynamic> json) {
    int i(String k, int d) => (json[k] as num?)?.toInt() ?? d;
    return PlatformExclusiveSettings(
      rentBumpHours: i('exclusive_rent_bump_hours', 6),
      saleBumpHours: i('exclusive_sale_bump_hours', 24),
      ownerFeedBoost: i('exclusive_owner_feed_boost', 45),
      agentFeedBoost: i('exclusive_agent_feed_boost', 55),
      hotBadgeEnabled: json['hot_badge_enabled'] as bool? ?? true,
      hotViewsPerHourThreshold: i('hot_views_per_hour_threshold', 100),
    );
  }

  Map<String, dynamic> toUpdatePayload() => {
        'exclusive_rent_bump_hours': rentBumpHours,
        'exclusive_sale_bump_hours': saleBumpHours,
        'exclusive_owner_feed_boost': ownerFeedBoost,
        'exclusive_agent_feed_boost': agentFeedBoost,
        'hot_badge_enabled': hotBadgeEnabled,
        'hot_views_per_hour_threshold': hotViewsPerHourThreshold,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
