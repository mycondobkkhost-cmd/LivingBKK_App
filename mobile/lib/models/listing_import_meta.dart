/// อ้างอิงรายการนำเข้าที่ซ้ำ (มีอยู่แล้วในคิว)
class ImportDuplicateRef {
  const ImportDuplicateRef({
    required this.importId,
    this.listingId,
    this.listingCode,
    this.titlePreview,
    required this.status,
    required this.sourceUrl,
    this.sourceExternalId,
  });

  final String importId;
  final String? listingId;
  final String? listingCode;
  final String? titlePreview;
  final String status;
  final String sourceUrl;
  final String? sourceExternalId;

  factory ImportDuplicateRef.fromJson(Map<String, dynamic> j) {
    return ImportDuplicateRef(
      importId: j['import_id'] as String? ?? j['id'] as String? ?? '',
      listingId: j['listing_id'] as String?,
      listingCode: j['listing_code'] as String?,
      titlePreview: j['title_preview'] as String?,
      status: j['status'] as String? ?? 'unknown',
      sourceUrl: j['source_url'] as String? ?? '',
      sourceExternalId: j['source_external_id'] as String?,
    );
  }
}

/// ข้อมูลต้นทางจาก Facebook / OG (เก็บใน parsed.source_meta)
class ImportSourceMeta {
  const ImportSourceMeta({
    this.postUrl,
    this.postText,
    this.posterName,
    this.posterUrl,
    this.postLinks = const [],
  });

  final String? postUrl;
  final String? postText;
  final String? posterName;
  final String? posterUrl;
  final List<String> postLinks;

  factory ImportSourceMeta.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ImportSourceMeta();
    final links = j['postLinks'] ?? j['post_links'];
    return ImportSourceMeta(
      postUrl: j['postUrl'] as String? ?? j['post_url'] as String?,
      postText: j['postText'] as String? ?? j['post_text'] as String?,
      posterName: j['posterName'] as String? ?? j['poster_name'] as String?,
      posterUrl: j['posterUrl'] as String? ?? j['poster_url'] as String?,
      postLinks: links is List ? links.map((e) => e.toString()).toList() : const [],
    );
  }
}
