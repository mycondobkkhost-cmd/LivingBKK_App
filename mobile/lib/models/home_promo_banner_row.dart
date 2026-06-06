import 'package:flutter/material.dart';

import '../config/home_promo_config.dart';
import '../theme/living_bkk_brand.dart';

/// แถวจาก `home_promo_banners` (แอดมิน) หรือ fallback จาก config
class HomePromoBannerRow {
  const HomePromoBannerRow({
    required this.id,
    required this.slug,
    required this.sortOrder,
    required this.isActive,
    required this.titleTh,
    required this.titleEn,
    required this.subtitleTh,
    required this.subtitleEn,
    required this.detailTh,
    required this.detailEn,
    required this.bulletTh,
    required this.bulletEn,
    this.badgeTh,
    this.badgeEn,
    this.imageUrl,
    this.imageStoragePath,
    this.gradientStart = '#12122B',
    this.gradientEnd = '#FF5B8A',
    this.accentColor = '#FFD54F',
  });

  final String id;
  final String slug;
  final int sortOrder;
  final bool isActive;
  final String titleTh;
  final String titleEn;
  final String subtitleTh;
  final String subtitleEn;
  final String detailTh;
  final String detailEn;
  final List<String> bulletTh;
  final List<String> bulletEn;
  final String? badgeTh;
  final String? badgeEn;
  final String? imageUrl;
  final String? imageStoragePath;
  final String gradientStart;
  final String gradientEnd;
  final String accentColor;

  static const int maxActive = 10;

  static List<String> _bulletList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  factory HomePromoBannerRow.fromJson(Map<String, dynamic> json) {
    return HomePromoBannerRow(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] == true,
      titleTh: json['title_th']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      subtitleTh: json['subtitle_th']?.toString() ?? '',
      subtitleEn: json['subtitle_en']?.toString() ?? '',
      detailTh: json['detail_th']?.toString() ?? '',
      detailEn: json['detail_en']?.toString() ?? '',
      bulletTh: _bulletList(json['bullet_th']),
      bulletEn: _bulletList(json['bullet_en']),
      badgeTh: json['badge_th']?.toString(),
      badgeEn: json['badge_en']?.toString(),
      imageUrl: json['image_url']?.toString(),
      imageStoragePath: json['image_storage_path']?.toString(),
      gradientStart: json['gradient_start']?.toString() ?? '#12122B',
      gradientEnd: json['gradient_end']?.toString() ?? '#FF5B8A',
      accentColor: json['accent_color']?.toString() ?? '#FFD54F',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'slug': slug,
        'sort_order': sortOrder,
        'is_active': isActive,
        'title_th': titleTh,
        'title_en': titleEn,
        'subtitle_th': subtitleTh,
        'subtitle_en': subtitleEn,
        'detail_th': detailTh,
        'detail_en': detailEn,
        'bullet_th': bulletTh,
        'bullet_en': bulletEn,
        'badge_th': badgeTh,
        'badge_en': badgeEn,
        'image_url': imageUrl,
        'image_storage_path': imageStoragePath,
        'gradient_start': gradientStart,
        'gradient_end': gradientEnd,
        'accent_color': accentColor,
      };

  static Color _parseHex(String hex, Color fallback) {
    var h = hex.trim();
    if (h.isEmpty) return fallback;
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v == null) return fallback;
    return Color(v);
  }

  HomePromoItem toPromoItem() {
    final bundled = HomePromoConfig.assetBySlug[slug];
    return HomePromoItem(
      id: slug,
      titleTh: titleTh,
      titleEn: titleEn,
      subtitleTh: subtitleTh,
      subtitleEn: subtitleEn,
      detailTh: detailTh,
      detailEn: detailEn,
      bulletTh: bulletTh,
      bulletEn: bulletEn,
      imageAsset: bundled?.imageAsset,
      imageUrl: imageUrl,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _parseHex(gradientStart, LivingBkkBrand.propNavy),
          _parseHex(gradientEnd, LivingBkkBrand.piterPink),
        ],
      ),
      accentColor: _parseHex(accentColor, const Color(0xFFFFD54F)),
      badgeTh: badgeTh,
      badgeEn: badgeEn,
    );
  }

  HomePromoBannerRow copyWith({
    String? id,
    String? slug,
    int? sortOrder,
    bool? isActive,
    String? titleTh,
    String? titleEn,
    String? subtitleTh,
    String? subtitleEn,
    String? detailTh,
    String? detailEn,
    List<String>? bulletTh,
    List<String>? bulletEn,
    String? badgeTh,
    String? badgeEn,
    String? imageUrl,
    String? imageStoragePath,
    String? gradientStart,
    String? gradientEnd,
    String? accentColor,
  }) {
    return HomePromoBannerRow(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      titleTh: titleTh ?? this.titleTh,
      titleEn: titleEn ?? this.titleEn,
      subtitleTh: subtitleTh ?? this.subtitleTh,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      detailTh: detailTh ?? this.detailTh,
      detailEn: detailEn ?? this.detailEn,
      bulletTh: bulletTh ?? this.bulletTh,
      bulletEn: bulletEn ?? this.bulletEn,
      badgeTh: badgeTh ?? this.badgeTh,
      badgeEn: badgeEn ?? this.badgeEn,
      imageUrl: imageUrl ?? this.imageUrl,
      imageStoragePath: imageStoragePath ?? this.imageStoragePath,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
