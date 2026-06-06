import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เก็บข้อมูลในเครื่อง (รายการโปรด, ดูล่าสุด, เปรียบเทียบ ฯลฯ)
class LocalPrefsService {
  LocalPrefsService._();
  static final instance = LocalPrefsService._();

  SharedPreferences? _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  Future<List<String>> getStringList(String key) async {
    await init();
    return _prefs!.getStringList(key) ?? const [];
  }

  Future<void> setStringList(String key, List<String> values) async {
    await init();
    await _prefs!.setStringList(key, values);
  }

  Future<Set<String>> getStringSet(String key) async {
    final list = await getStringList(key);
    return list.toSet();
  }

  Future<void> setStringSet(String key, Set<String> values) async {
    await setStringList(key, values.toList());
  }

  Future<Map<String, dynamic>?> getJsonMap(String key) async {
    await init();
    final raw = _prefs!.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LocalPrefsService json decode error ($key): $e');
      return null;
    }
  }

  Future<void> setJsonMap(String key, Map<String, dynamic> value) async {
    await init();
    await _prefs!.setString(key, jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    await init();
    final raw = _prefs!.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('LocalPrefsService json list error ($key): $e');
      return const [];
    }
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> values) async {
    await init();
    await _prefs!.setString(key, jsonEncode(values));
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs!.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    await init();
    await _prefs!.setBool(key, value);
  }

  Future<void> remove(String key) async {
    await init();
    await _prefs!.remove(key);
  }
}
