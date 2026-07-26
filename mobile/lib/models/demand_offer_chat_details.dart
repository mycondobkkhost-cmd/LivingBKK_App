/// ข้อมูลเสริมสำหรับบันทึกแชทหลังส่งข้อเสนอทรัพย์
class DemandOfferChatDetails {
  const DemandOfferChatDetails({
    this.listingId,
    this.listingCode,
    this.listingTitle,
    this.listingPrice,
    this.externalNote,
    this.tags = const [],
    this.offererCapacity,
    this.transactionType,
    this.demandPostId,
    this.fromStockPick = false,
    this.coverUrl,
    this.contactName,
    this.contactPhone,
  });

  final String? listingId;
  final String? listingCode;
  final String? listingTitle;
  final double? listingPrice;
  final String? externalNote;
  final List<String> tags;
  final String? offererCapacity;
  final String? transactionType;
  final String? demandPostId;
  final bool fromStockPick;
  final String? coverUrl;
  final String? contactName;
  final String? contactPhone;

  Map<String, dynamic> toJson() => {
        if (listingId != null && listingId!.isNotEmpty) 'listing_id': listingId,
        if (listingCode != null && listingCode!.isNotEmpty)
          'listing_code': listingCode,
        if (listingTitle != null && listingTitle!.isNotEmpty)
          'listing_title': listingTitle,
        if (listingPrice != null) 'listing_price': listingPrice,
        if (externalNote != null && externalNote!.trim().isNotEmpty)
          'external_note': externalNote!.trim(),
        if (tags.isNotEmpty) 'tags': tags,
        if (offererCapacity != null) 'offerer_capacity': offererCapacity,
        if (transactionType != null) 'transaction_type': transactionType,
        if (demandPostId != null) 'demand_post_id': demandPostId,
        'from_stock_pick': fromStockPick,
        if (coverUrl != null && coverUrl!.isNotEmpty) 'cover_url': coverUrl,
        if (contactName != null) 'contact_name': contactName,
        if (contactPhone != null) 'contact_phone': contactPhone,
      };
}
