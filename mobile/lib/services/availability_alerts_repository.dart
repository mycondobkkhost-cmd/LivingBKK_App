import '../data/admin_demo_data.dart';
import '../models/availability_alert.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// รายการประกาศที่กำลังจะว่าง — จาก `listings.available_again`
class AvailabilityAlertsRepository {
  static final AvailabilityAlertsRepository instance =
      AvailabilityAlertsRepository._();
  AvailabilityAlertsRepository._();

  static const listHorizonDays = 60;
  static const notifyHorizonDays = 30;

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<AvailabilityAlertItem>> fetchUpcoming({
    int withinDays = listHorizonDays,
  }) async {
    if (!_live) return _demoItems(withinDays: withinDays);

    try {
      final now = DateTime.now();
      final end = now.add(Duration(days: withinDays));
      final rows = await SupabaseService.client!
          .from('listings')
          .select(
            'id, listing_code, title, listing_type, status, project_name, district, '
            'available_again, owner_id, owner:profiles!listings_owner_id_fkey(display_name)',
          )
          .gte('available_again', _dateOnly(now))
          .lte('available_again', _dateOnly(end))
          .order('available_again', ascending: true)
          .limit(80);

      final items = (rows as List)
          .whereType<Map>()
          .map((r) => AvailabilityAlertItem.fromListingRow(
                Map<String, dynamic>.from(r),
              ))
          .where((item) => item.listingId.isNotEmpty)
          .toList();
      if (AdminDemoData.useWhenEmpty(items)) return _demoItems(withinDays: withinDays);
      return items;
    } catch (_) {
      return _fetchUpcomingFallback(withinDays: withinDays);
    }
  }

  Future<List<AvailabilityAlertItem>> _fetchUpcomingFallback({
    required int withinDays,
  }) async {
    try {
      final now = DateTime.now();
      final end = now.add(Duration(days: withinDays));
      final rows = await SupabaseService.client!
          .from('listings')
          .select(
            'id, listing_code, title, listing_type, status, project_name, district, '
            'available_again, owner_id',
          )
          .gte('available_again', _dateOnly(now))
          .lte('available_again', _dateOnly(end))
          .order('available_again', ascending: true)
          .limit(80);

      final items = <AvailabilityAlertItem>[];
      for (final raw in rows as List) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final ownerId = row['owner_id']?.toString();
        if (ownerId != null && ownerId.isNotEmpty) {
          final profile = await SupabaseService.client!
              .from('profiles')
              .select('display_name')
              .eq('id', ownerId)
              .maybeSingle();
          if (profile is Map) {
            row['owner'] = profile;
          }
        }
        try {
          items.add(AvailabilityAlertItem.fromListingRow(row));
        } catch (_) {}
      }
      return items;
    } catch (_) {
      return _demoItems(withinDays: withinDays);
    }
  }

  Future<int> countWithinDays(int days) async {
    final items = await fetchUpcoming(withinDays: days);
    return items.length;
  }

  List<AvailabilityAlertItem> _demoItems({required int withinDays}) {
    final now = DateTime.now();
    DateTime onDay(int offset) {
      final d = now.add(Duration(days: offset));
      return DateTime(d.year, d.month, d.day);
    }

    final all = [
      AvailabilityAlertItem(
        listingId: 'demo-avail-1',
        listingCode: 'RENT-CD-2026-000050',
        title: 'ให้เช่า แฮมป์ตัน เรสซิเดนซ์ กรุงเทพ 1 นอน',
        projectName: 'แฮมป์ตัน เรสซิเดนซ์ กรุงเทพ',
        district: 'ห้วยขวาง',
        availableAgain: onDay(28),
        listingType: 'rent',
        status: 'archived',
        ownerName: 'คุณมิ้นท์',
      ),
      AvailabilityAlertItem(
        listingId: 'demo-avail-2',
        listingCode: 'RXT-2026-004522',
        title: 'ให้เช่า ไลฟ์ อ่อนนุช 1 นอน',
        projectName: 'Life Asoke Hype',
        district: 'วัฒนา',
        availableAgain: onDay(14),
        listingType: 'rent',
        status: 'archived',
        ownerName: 'คุณสมชาย',
      ),
      AvailabilityAlertItem(
        listingId: 'demo-avail-3',
        listingCode: 'RXT-2026-004521',
        title: 'ขายคอนโด ไอดีโอ โมบิ สุขุมวิท',
        projectName: 'IDEO Mobi Sukhumvit',
        district: 'บางนา',
        availableAgain: onDay(45),
        listingType: 'sale',
        status: 'hidden',
        ownerName: 'คุณนภา',
      ),
    ];

    return all
        .where((item) => item.daysLeft >= 0 && item.daysLeft <= withinDays)
        .toList()
      ..sort((a, b) => a.availableAgain.compareTo(b.availableAgain));
  }
}
