import 'package:flutter/foundation.dart';

import '../config/home_promo_config.dart';
import 'home_promo_repository.dart';

/// Cache โฆษณาหน้าแรก — โหลดจาก Supabase หรือ fallback config
class HomePromoService extends ChangeNotifier {
  HomePromoService._();
  static final HomePromoService instance = HomePromoService._();

  final _repo = HomePromoRepository();
  List<HomePromoItem> _items = HomePromoConfig.items;
  bool _loaded = false;

  List<HomePromoItem> get items => _items;
  bool get loaded => _loaded;

  Future<void> load() async {
    _items = await _repo.fetchActivePromos();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _items = await _repo.fetchActivePromos();
    notifyListeners();
  }
}
