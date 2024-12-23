import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_models.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _popularKey = 'popular_manga';
  static const String _latestKey = 'latest_manga';
  static const String _cacheTimeKey = 'cache_time';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  Future<void> cacheHomeData({
    required List<Manga> popularManga,
    required List<Manga> latestManga,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_popularKey,
          json.encode(popularManga.map((m) => m.toJson()).toList())),
      prefs.setString(
          _latestKey, json.encode(latestManga.map((m) => m.toJson()).toList())),
      prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String()),
    ]);
  }

  Future<Map<String, List<Manga>>?> getCachedHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr == null) return null;

    final cacheTime = DateTime.parse(cacheTimeStr);
    if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
      // Cache expired
      await clearCache();
      return null;
    }

    final popularJson = prefs.getString(_popularKey);
    final latestJson = prefs.getString(_latestKey);
    if (popularJson == null || latestJson == null) return null;

    try {
      return {
        'popular': (json.decode(popularJson) as List)
            .map((m) => Manga.fromJson(m))
            .toList(),
        'latest': (json.decode(latestJson) as List)
            .map((m) => Manga.fromJson(m))
            .toList(),
      };
    } catch (e) {
      print('Error parsing cached data: $e');
      await clearCache();
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_popularKey),
      prefs.remove(_latestKey),
      prefs.remove(_cacheTimeKey),
    ]);
  }
}
