class VaultAssetSummary {
  const VaultAssetSummary({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.sourcePlatform,
    this.titlePreview,
    this.listingId,
    this.listingCode,
    this.profileId,
    this.importId,
    this.capturedAt,
    this.updatedAt,
    this.hasPhones = false,
    this.hasLines = false,
    this.sourceUrl,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String? sourcePlatform;
  final String? titlePreview;
  final String? listingId;
  final String? listingCode;
  final String? profileId;
  final String? importId;
  /// วันที่บันทึกเข้าคลัง (`captured_at`)
  final DateTime? capturedAt;
  /// อัปเดตล่าสุดจากระบบ (`updated_at`)
  final DateTime? updatedAt;
  final bool hasPhones;
  final bool hasLines;
  final String? sourceUrl;

  factory VaultAssetSummary.fromJson(Map<String, dynamic> j) {
    return VaultAssetSummary(
      id: j['id'] as String? ?? j['entity_id'] as String? ?? '',
      entityType: j['entity_type'] as String? ?? '',
      entityId: j['entity_id'] as String? ?? '',
      sourcePlatform: j['source_platform'] as String?,
      titlePreview: j['title_preview'] as String?,
      listingId: j['listing_id'] as String?,
      listingCode: j['listing_code'] as String?,
      profileId: j['profile_id'] as String?,
      importId: j['import_id'] as String?,
      capturedAt: j['captured_at'] != null
          ? DateTime.tryParse(j['captured_at'].toString())
          : null,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
      hasPhones: j['has_phones'] == true,
      hasLines: j['has_lines'] == true,
      sourceUrl: j['source_url'] as String?,
    );
  }

  String get displayCode =>
      listingCode ??
      (importId != null ? 'IMP-${importId!.substring(0, 8)}' : null) ??
      'ENT-${entityId.substring(0, 8)}';
}

class VaultAssetDetail {
  const VaultAssetDetail({
    required this.summary,
    required this.payload,
    this.capturedAt,
  });

  final VaultAssetSummary summary;
  final Map<String, dynamic> payload;
  final DateTime? capturedAt;

  factory VaultAssetDetail.fromJson(Map<String, dynamic> j) {
    final payload = j['payload'] is Map
        ? Map<String, dynamic>.from(j['payload'] as Map)
        : <String, dynamic>{};
    return VaultAssetDetail(
      summary: VaultAssetSummary.fromJson(j),
      payload: payload,
      capturedAt: j['captured_at'] != null
          ? DateTime.tryParse(j['captured_at'].toString())
          : null,
    );
  }

  List<String> get phones {
    final fromList = payload['phones'];
    if (fromList is List) {
      return fromList.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final single = payload['owner_phone'];
    if (single != null && single.toString().isNotEmpty) {
      return [single.toString()];
    }
    return const [];
  }

  List<String> get lines {
    final fromList = payload['lines'];
    if (fromList is List) {
      return fromList.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final single = payload['owner_line'] ?? payload['line_id'];
    if (single != null && single.toString().isNotEmpty) {
      return [single.toString()];
    }
    return const [];
  }

  String? get postTextFull =>
      payload['post_text_full']?.toString() ??
      payload['description_public']?.toString();

  String? get sourceUrl =>
      payload['source_url']?.toString() ?? payload['post_url']?.toString();

  List<String> get postLinks {
    final raw = payload['post_links'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// มุมมองแอดมินทั่วไป — ตัด PII / ลิงก์ต้นทาง
  VaultAssetDetail censored() {
    final safe = Map<String, dynamic>.from(payload);
    for (final key in [
      'phones',
      'lines',
      'owner_phone',
      'owner_line',
      'phone',
      'line_id',
      'post_text_full',
      'contact_private',
      'source_url',
      'post_url',
      'post_links',
      'poster_url',
      'source_meta',
    ]) {
      safe.remove(key);
    }
    return VaultAssetDetail(
      summary: summary,
      payload: safe,
      capturedAt: capturedAt,
    );
  }
}
