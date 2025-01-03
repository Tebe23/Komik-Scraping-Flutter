import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';
import '../models/manga_models.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const String _key = 'favorites';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<FavoriteManga>> getFavorites() async {
    try {
      final prefs = await this.prefs;
      final String? favoritesJson = prefs.getString(_key);
      if (favoritesJson == null || favoritesJson.isEmpty) return [];

      final List<dynamic> decoded = json.decode(favoritesJson);
      return decoded.map((item) => FavoriteManga.fromJson(item)).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  Future<void> addToFavorites(Manga manga) async {
    try {
      final favorites = await getFavorites();
      if (favorites.any((fav) => fav.link == manga.link)) return;

      favorites.add(FavoriteManga(
        title: manga.title,
        link: manga.link,
        image: manga.image,
        latestChapter: manga.latestChapter,
        addedAt: DateTime.now(),
      ));

      final prefs = await this.prefs;
      final encodedData =
          json.encode(favorites.map((f) => f.toJson()).toList());
      await prefs.setString(_key, encodedData);
    } catch (e) {
      print('Error adding to favorites: $e');
      throw Exception('Gagal menambahkan ke favorit');
    }
  }

  Future<void> removeFromFavorites(String mangaLink) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav.link == mangaLink);

      final prefs = await this.prefs;
      final encodedData =
          json.encode(favorites.map((f) => f.toJson()).toList());
      await prefs.setString(_key, encodedData);
    } catch (e) {
      print('Error removing from favorites: $e');
      throw Exception('Gagal menghapus dari favorit');
    }
  }

  Future<bool> isFavorite(String mangaLink) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav.link == mangaLink);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  Future<void> updateLatestChapter(String mangaLink, String newChapter) async {
    try {
      final favorites = await getFavorites();
      final index = favorites.indexWhere((f) => f.link == mangaLink);
      
      if (index != -1) {
        favorites[index] = FavoriteManga(
          title: favorites[index].title,
          link: favorites[index].link,
          image: favorites[index].image,
          latestChapter: newChapter,
          addedAt: favorites[index].addedAt,
        );

        final prefs = await this.prefs;
        await prefs.setString(_key, json.encode(favorites.map((f) => f.toJson()).toList()));
      }
    } catch (e) {
      print('Error updating latest chapter: $e');
    }
  }
}
