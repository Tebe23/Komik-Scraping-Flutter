import 'package:flutter/material.dart';
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  final FavoritesService _favoritesService = FavoritesService();
  String _sortBy = 'name'; // 'name', 'date', 'rating'

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorit'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              if (!mounted) return;
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Text('Nama'),
              ),
              PopupMenuItem(
                value: 'date',
                child: Text('Tanggal Ditambahkan'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<FavoriteManga>>(
        future: _favoritesService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada manga favorit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final favorites = List<FavoriteManga>.from(snapshot.data!);

          // Urutkan berdasarkan pilihan
          switch (_sortBy) {
            case 'name':
              favorites.sort((a, b) => a.title.compareTo(b.title));
              break;
            case 'date':
              favorites.sort((a, b) => b.addedAt.compareTo(a.addedAt));
              break;
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final manga = favorites[index];
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      manga.image,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 70,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  title: Text(manga.title),
                  subtitle: Text(manga.latestChapter),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      try {
                        await _favoritesService.removeFromFavorites(manga.link);
                        if (!mounted) return;
                        setState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Gagal menghapus dari favorit')),
                        );
                      }
                    },
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(mangaLink: manga.link),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
