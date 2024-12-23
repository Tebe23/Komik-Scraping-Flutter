import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../models/manga_detail.dart';
import '../services/manga_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailScreen extends StatefulWidget {
  final Manga manga;

  const DetailScreen({super.key, required this.manga});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final MangaService _mangaService = MangaService();
  MangaDetail? mangaDetail;
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadMangaDetail();
    _checkFavoriteStatus();
  }

  Future<void> _loadMangaDetail() async {
    try {
      setState(() => isLoading = true);
      final detail = await _mangaService.getMangaDetail(widget.manga.link);
      setState(() {
        mangaDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading manga detail: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load manga details')),
      );
    }
  }

  Future<void> _checkFavoriteStatus() async {
    // Implement favorite checking logic using SharedPreferences
  }

  Future<void> _toggleFavorite() async {
    // Implement favorite toggle logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildDetailContent(),
                ),
                _buildChapterList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleFavorite,
        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
        label: Text(isFavorite ? 'Remove Favorite' : 'Add to Favorite'),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.manga.title,
          style: TextStyle(
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.manga.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => 
                const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (mangaDetail == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Status', mangaDetail!.status),
          _buildInfoRow('Type', mangaDetail!.type),
          _buildInfoRow('Author', mangaDetail!.author),
          _buildInfoRow('Release', mangaDetail!.release),
          _buildInfoRow('Total Chapters', mangaDetail!.totalChapter),
          
          const SizedBox(height: 16),
          
          const Text(
            'Synopsis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(mangaDetail!.synopsis),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            children: mangaDetail!.genres.map((genre) {
              return Chip(label: Text(genre));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    if (mangaDetail == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = mangaDetail!.chapters[index];
          return ListTile(
            title: Text(chapter.title),
            subtitle: Text(chapter.time),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/reader',
                arguments: chapter,
              );
            },
          );
        },
        childCount: mangaDetail!.chapters.length,
      ),
    );
  }
}