import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

class HistoryService {
  static const String _key = 'reading_history';

  Future<List<ReadHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_key);
    if (historyJson == null) return [];

    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((item) => ReadHistory.fromJson(item)).toList();
  }

  Future<void> addToHistory(ReadHistory history) async {
    final histories = await getHistory();

    // Remove if exists and add to top
    histories.removeWhere((h) =>
        h.mangaLink == history.mangaLink &&
        h.chapterLink == history.chapterLink);
    histories.insert(0, history);

    // Keep only last 100 items
    if (histories.length > 100) {
      histories.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(histories.map((h) => h.toJson()).toList()));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<String> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString(_key) ?? '[]';
    final favorites = prefs.getString('favorites') ?? '[]';

    return json.encode({
      'history': json.decode(history),
      'favorites': json.decode(favorites),
    });
  }

  Future<void> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_key, json.encode(data['history']));
      await prefs.setString('favorites', json.encode(data['favorites']));
    } catch (e) {
      throw Exception('Invalid backup data');
    }
  }

  Future<void> removeFromHistory(String chapterLink) async {
    try {
      final history = await getHistory();
      history.removeWhere((h) => h.chapterLink == chapterLink);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        json.encode(history.map((h) => h.toJson()).toList()),
      );
    } catch (e) {
      print('Error removing from history: $e');
      throw Exception('Gagal menghapus dari riwayat');
    }
  }
}
