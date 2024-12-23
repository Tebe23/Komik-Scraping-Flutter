import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/manga_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MangaService _mangaService = MangaService();
  final _searchController = TextEditingController();
  List<Manga> searchResults = [];
  bool isLoading = false;
  bool hasSearched = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final results = await _mangaService.searchManga(query);
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching manga: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching manga')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search manga...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _performSearch,
        ),
      ),
      body: Column(
        children: [
          if (isLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: !hasSearched
                ? const Center(
                    child: Text('Search for your favorite manga'),
                  )
                : searchResults.isEmpty
                    ? const Center(
                        child: Text('No results found'),
                      )
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final manga = searchResults[index];
                          return _buildMangaListItem(manga);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMangaListItem(Manga manga) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: manga.imageUrl,
            width: 50,
            height: 70,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        title: Text(
          manga.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(manga.chapter),
            Text(
              '${manga.type} • ${manga.status}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/detail',
            arguments: manga,
          );
        },
      ),
    );
  }
}