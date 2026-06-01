class DemandPost {
  const DemandPost({
    required this.id,
    required this.postCode,
    required this.title,
    required this.transactionType,
    this.description,
    this.maxPriceNet,
    this.minAreaSqm,
    this.maxDistanceBtsKm,
    this.status = 'open',
    this.openUntil,
  });

  final String id;
  final String postCode;
  final String title;
  final String transactionType;
  final String? description;
  final double? maxPriceNet;
  final double? minAreaSqm;
  final double? maxDistanceBtsKm;
  final String status;
  final DateTime? openUntil;

  factory DemandPost.fromJson(Map<String, dynamic> json) {
    return DemandPost(
      id: json['id'] as String,
      postCode: json['post_code'] as String,
      title: json['title'] as String,
      transactionType: json['transaction_type'] as String,
      description: json['description'] as String?,
      maxPriceNet: (json['max_price_net'] as num?)?.toDouble(),
      minAreaSqm: (json['min_area_sqm'] as num?)?.toDouble(),
      maxDistanceBtsKm: (json['max_distance_bts_km'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'open',
      openUntil: json['open_until'] != null
          ? DateTime.tryParse(json['open_until'] as String)
          : null,
    );
  }

  static List<DemandPost> demo() => [
        DemandPost(
          id: 'dm-1',
          postCode: 'DM-2026-000001',
          title: 'หาคอนโดย่านทองหล่อ',
          transactionType: 'rent',
          description:
              'ห่าง BTS ไม่เกิน 1.5 กม. ขนาด 30 ตร.ม. ขึ้นไป ไม่เกิน 15,000 บาท',
          maxPriceNet: 15000,
          minAreaSqm: 30,
          maxDistanceBtsKm: 1.5,
          openUntil: DateTime.now().add(const Duration(days: 14)),
        ),
      ];
}
