import '../models/listing_public.dart';

/// รูปหน้าปก + พรีวิวประกาศของเจ้าของ
abstract final class OwnerListingMedia {
  static String? coverUrl(Map<String, dynamic> row) {
    final direct = row['cover_image_url']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final thumb = row['thumbnail_url']?.toString();
    if (thumb != null && thumb.isNotEmpty) return thumb;

    final urls = row['image_urls'];
    if (urls is List && urls.isNotEmpty) {
      final first = urls.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    }
    if (urls is String && urls.isNotEmpty) {
      return urls.split(',').first.trim();
    }

    return placeholderUrl(row);
  }

  static String placeholderUrl(Map<String, dynamic> row) {
    final seed = Uri.encodeComponent(
      row['listing_code']?.toString() ??
          row['id']?.toString() ??
          'listing',
    );
    return 'https://picsum.photos/seed/$seed/240/180';
  }

  static bool canPreviewOnline(Map<String, dynamic> row) {
    return row['status']?.toString() == 'published';
  }

  static ListingPublic toListingPublic(Map<String, dynamic> row) {
    final cover = coverUrl(row);
    return ListingPublic(
      id: row['id']?.toString() ?? '',
      listingCode: row['listing_code']?.toString() ?? '',
      listingType: row['listing_type']?.toString() ?? 'rent',
      title: row['title']?.toString() ?? '',
      priceNet: (row['price_net'] as num?)?.toDouble() ?? 0,
      priceSaleNet: (row['price_sale_net'] as num?)?.toDouble(),
      promoPriceNet: (row['price_internal'] as num?)?.toDouble(),
      promoSalePriceNet: (row['price_sale_promo_net'] as num?)?.toDouble(),
      district: row['district']?.toString(),
      projectName: row['project_name']?.toString(),
      propertyType: row['property_type']?.toString() ?? 'condo',
      imageUrls: cover == null ? const [] : [cover],
      description: row['description']?.toString(),
    );
  }
}
