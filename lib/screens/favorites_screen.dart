import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'dart:convert';
import '../models/manga.dart';
import '../services/manga_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Manga> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList('favorites') ?? [];
      
      setState(() {
        favorites = favoritesJson
            .map((json) => Manga.fromJson(jsonDecode(json)))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _removeFavorite(Manga manga) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList('favorites') ?? [];
      
      favoritesJson.removeWhere((json) {
        final item = Manga.fromJson(jsonDecode(json));
        return item.link == manga.link;
      });
      
      await prefs.setStringList('favorites', favoritesJson);
      
      setState(() {
        favorites.removeWhere((item) => item.link == manga.link);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final manga = favorites[index];
                    return Dismissible(
                      key: Key(manga.link),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) => _removeFavorite(manga),
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 70,
                          child: Image.network(
                            manga.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        title: Text(manga.title),
                        subtitle: Text(manga.chapter),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: manga,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}