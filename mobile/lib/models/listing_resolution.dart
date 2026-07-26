class ListingResolution {
  const ListingResolution({
    required this.status,
    this.listingId,
    this.listingCode,
    this.title,
    this.projectName,
    this.listingType,
    this.priceNet,
    this.matchedQuery,
  });

  factory ListingResolution.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ListingResolution(status: 'none');
    return ListingResolution(
      status: json['status'] as String? ?? 'none',
      listingId: json['listing_id']?.toString(),
      listingCode: json['listing_code']?.toString(),
      title: json['title']?.toString(),
      projectName: json['project_name']?.toString(),
      listingType: json['listing_type']?.toString(),
      priceNet: (json['price_net'] as num?)?.toDouble(),
      matchedQuery: json['matched_query']?.toString(),
    );
  }

  final String status;
  final String? listingId;
  final String? listingCode;
  final String? title;
  final String? projectName;
  final String? listingType;
  final double? priceNet;
  final String? matchedQuery;

  bool get isFound => status == 'found';
}
