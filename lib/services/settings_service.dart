import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _maxConcurrentDownloadsKey = 'max_concurrent_downloads';
  
  Future<void> setMaxConcurrentDownloads(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxConcurrentDownloadsKey, value);
  }

  Future<int> getMaxConcurrentDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxConcurrentDownloadsKey) ?? 1; // Default 1
  }
}
