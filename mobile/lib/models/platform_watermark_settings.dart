/// ลายน้ำรูปประกาศ — ตั้งจากแอดมิน (`app_platform_settings`)
class PlatformWatermarkSettings {
  const PlatformWatermarkSettings({
    this.enabled = true,
    this.storagePath,
    this.publicUrl,
    this.opacity = 72,
    this.sizeRatio = 0.08,
  });

  final bool enabled;
  final String? storagePath;
  final String? publicUrl;
  final int opacity;
  final double sizeRatio;

  static const defaults = PlatformWatermarkSettings();

  bool get hasCustomImage =>
      storagePath != null && storagePath!.trim().isNotEmpty;

  factory PlatformWatermarkSettings.fromJson(Map<String, dynamic> json) {
    return PlatformWatermarkSettings(
      enabled: json['listing_watermark_enabled'] as bool? ?? true,
      storagePath: json['listing_watermark_storage_path'] as String?,
      publicUrl: json['listing_watermark_public_url'] as String?,
      opacity: (json['listing_watermark_opacity'] as num?)?.toInt() ?? 72,
      sizeRatio: (json['listing_watermark_size_ratio'] as num?)?.toDouble() ?? 0.08,
    );
  }

  Map<String, dynamic> toUpdatePayload() => {
        'listing_watermark_enabled': enabled,
        if (storagePath != null) 'listing_watermark_storage_path': storagePath,
        if (publicUrl != null) 'listing_watermark_public_url': publicUrl,
        'listing_watermark_opacity': opacity.clamp(20, 200),
        'listing_watermark_size_ratio': sizeRatio.clamp(0.04, 0.2),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
