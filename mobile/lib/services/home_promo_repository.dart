import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/home_promo_config.dart';
import '../models/home_promo_banner_row.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class HomePromoRepository {
  bool get _ready =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  /// โหลดโฆษณาที่เปิดใช้งานสำหรับหน้าแรก (สูงสุด 10)
  Future<List<HomePromoItem>> fetchActivePromos() async {
    if (!_ready) return HomePromoConfig.items;
    try {
      final data = await SupabaseService.client!
          .from('home_promo_banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(HomePromoBannerRow.maxActive);
      final rows = (data as List)
          .map((e) => HomePromoBannerRow.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.slug.isNotEmpty)
          .toList();
      if (rows.isEmpty) return HomePromoConfig.items;
      return rows.map((r) => r.toPromoItem()).toList();
    } catch (_) {
      return HomePromoConfig.items;
    }
  }

  /// แอดมิน — ทุกรายการรวมที่ปิดใช้งาน
  Future<List<HomePromoBannerRow>> listAll() async {
    if (!_ready) {
      return HomePromoConfig.items
          .asMap()
          .entries
          .map(
            (e) => HomePromoBannerRow(
              id: 'local-${e.value.id}',
              slug: e.value.id,
              sortOrder: e.key + 1,
              isActive: true,
              titleTh: e.value.titleTh,
              titleEn: e.value.titleEn,
              subtitleTh: e.value.subtitleTh,
              subtitleEn: e.value.subtitleEn,
              detailTh: e.value.detailTh,
              detailEn: e.value.detailEn,
              bulletTh: e.value.bulletTh,
              bulletEn: e.value.bulletEn,
              badgeTh: e.value.badgeTh,
              badgeEn: e.value.badgeEn,
              gradientStart: '#12122B',
              gradientEnd: '#FF5B8A',
              accentColor:
                  '#${e.value.accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
            ),
          )
          .toList();
    }
    final data = await SupabaseService.client!
        .from('home_promo_banners')
        .select()
        .order('sort_order', ascending: true);
    return (data as List)
        .map((e) => HomePromoBannerRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<HomePromoBannerRow> upsert(HomePromoBannerRow row) async {
    if (!_ready) throw Exception('ต้องเชื่อมต่อ Supabase และล็อกอินแอดมิน');
    final payload = Map<String, dynamic>.from(row.toJson())..remove('id');
    if (row.id.isNotEmpty && !row.id.startsWith('local-')) {
      final data = await SupabaseService.client!
          .from('home_promo_banners')
          .update(payload)
          .eq('id', row.id)
          .select()
          .single();
      return HomePromoBannerRow.fromJson(Map<String, dynamic>.from(data));
    }
    final data = await SupabaseService.client!
        .from('home_promo_banners')
        .insert(payload)
        .select()
        .single();
    return HomePromoBannerRow.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(String id) async {
    if (!_ready) throw Exception('ต้องเชื่อมต่อ Supabase และล็อกอินแอดมิน');
    await SupabaseService.client!.from('home_promo_banners').delete().eq('id', id);
  }

  Future<void> swapSortOrder(HomePromoBannerRow a, HomePromoBannerRow b) async {
    if (!_ready) return;
    await SupabaseService.client!.from('home_promo_banners').update({
      'sort_order': b.sortOrder,
    }).eq('id', a.id);
    await SupabaseService.client!.from('home_promo_banners').update({
      'sort_order': a.sortOrder,
    }).eq('id', b.id);
  }

  Future<({String url, String path})> uploadImage({
    required String slug,
    required XFile file,
  }) async {
    if (!_ready) throw Exception('ต้องเชื่อมต่อ Supabase และล็อกอินแอดมิน');
    final ext = _extension(file);
    final path = '$slug/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await SupabaseService.client!.storage.from('home-promo').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url =
        SupabaseService.client!.storage.from('home-promo').getPublicUrl(path);
    return (url: url, path: path);
  }

  String _extension(XFile file) {
    final parts = file.name.split('.');
    if (parts.length > 1) return parts.last.toLowerCase();
    return 'jpg';
  }

  static String friendlyError(Object e) {
    final m = e.toString();
    if (m.contains('home_promo_max_active')) {
      return 'เปิดใช้งานได้สูงสุด 10 โฆษณา — ปิดรายการอื่นก่อน';
    }
    if (m.contains('duplicate key') && m.contains('sort_order')) {
      return 'ลำดับซ้ำ — เปลี่ยนลำดับหรือสลับตำแหน่ง';
    }
    return m;
  }
}
