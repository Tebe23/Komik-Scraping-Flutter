import 'package:flutter/material.dart';
import '../services/scraping_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../models/manga_models.dart';
import '../models/history_model.dart';
import 'chapter_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../services/reading_state_service.dart';
import 'dart:async';

class DetailScreen extends StatefulWidget {
  final String mangaLink;

  const DetailScreen({Key? key, required this.mangaLink}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  final FavoritesService _favoritesService = FavoritesService();
  final HistoryService _historyService = HistoryService();
  final ReadingStateService _readingStateService = ReadingStateService();
  late Future<MangaDetail> _mangaDetailFuture;
  bool _isFavorite = false;
  bool _isChapterReversed = false;
  bool _isExpandedSynopsis = false;
  String? _lastReadChapter;
  List<String> _readChapters = [];
  StreamSubscription? _readingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _listenToReadingChanges();
  }

  void _listenToReadingChanges() {
    _readingSubscription =
        _readingStateService.onChapterRead.listen((chapterLink) {
      if (!mounted) return;
      if (!_readChapters.contains(chapterLink)) {
        setState(() {
          _readChapters.add(chapterLink);
        });
      }
    });
  }

  @override
  void dispose() {
    _readingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _mangaDetailFuture = _scrapingService.scrapeMangaDetail(widget.mangaLink);
      await Future.wait([
        _checkFavoriteStatus(),
        _loadReadChapters(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      if (!mounted) return;
      final isFavorite = await _favoritesService.isFavorite(widget.mangaLink);
      if (!mounted) return;
      setState(() => _isFavorite = isFavorite);
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite(Manga manga) async {
    try {
      if (!mounted) return;
      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(widget.mangaLink);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dihapus dari favorit')),
        );
      } else {
        await _favoritesService.addToFavorites(manga);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ditambahkan ke favorit')),
        );
      }
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status favorit')),
      );
    }
  }

  Future<void> _loadLastRead() async {
    try {
      final history = await _historyService.getHistory();
      final lastRead = history.firstWhere(
        (h) => h.mangaLink == widget.mangaLink,
        orElse: () => ReadHistory(
          mangaTitle: '',
          mangaLink: '',
          mangaImage: '',
          chapterTitle: '',
          chapterLink: '',
          readAt: DateTime.now(),
        ),
      );
      if (mounted) {
        setState(() => _lastReadChapter = lastRead.chapterLink);
      }
    } catch (e) {
      print('Error loading last read: $e');
    }
  }

  Future<List<String>> _getReadChapters() async {
    try {
      final history = await _historyService.getHistory();
      return history
          .where((h) => h.mangaLink == widget.mangaLink)
          .map((h) => h.chapterLink)
          .toList();
    } catch (e) {
      print('Error getting read chapters: $e');
      return [];
    }
  }

  Future<void> _loadReadChapters() async {
    final readChapters = await _getReadChapters();
    if (mounted) {
      setState(() => _readChapters = readChapters);
    }
  }

  Manga _convertToManga(MangaDetail detail) {
    return Manga(
      title: detail.title,
      link: widget.mangaLink,
      image: detail.thumbnail,
      latestChapter: detail.chapters.first.title,
      score: '',
      type: '',
      status: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<MangaDetail>(
        future: _mangaDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final manga = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _mangaDetailFuture =
                    _scrapingService.scrapeMangaDetail(widget.mangaLink);
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(manga.title),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Hero(
                                    tag: 'manga-${widget.mangaLink}',
                                    child: Image.network(
                                      manga.thumbnail,
                                      width: 120,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 120,
                                        height: 180,
                                        color: Colors.grey[300],
                                        child:
                                            Icon(Icons.broken_image, size: 48),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    manga.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Author: ${manga.author}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        icon: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              _isFavorite ? Colors.red : null,
                                        ),
                                        label: Text(
                                          _isFavorite
                                              ? 'Favorit'
                                              : 'Tambah Favorit',
                                        ),
                                        onPressed: () => _toggleFavorite(
                                            _convertToManga(manga)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Genres
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: manga.genres
                              .map((genre) => Chip(
                                    label: Text(
                                      genre,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                  ))
                              .toList(),
                        ),
                        SizedBox(height: 16),
                        // Synopsis
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Synopsis',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manga.synopsis,
                                  maxLines: _isExpandedSynopsis ? null : 3,
                                  overflow: _isExpandedSynopsis
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _isExpandedSynopsis =
                                        !_isExpandedSynopsis);
                                  },
                                  child: Text(_isExpandedSynopsis
                                      ? 'Show Less'
                                      : 'Show More'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Chapters Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chapters',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              icon: Icon(_isChapterReversed
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward),
                              label: Text(
                                  _isChapterReversed ? 'Terlama' : 'Terbaru'),
                              onPressed: () {
                                setState(() =>
                                    _isChapterReversed = !_isChapterReversed);
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _readChapters.isEmpty
                                  ? ElevatedButton.icon(
                                      icon: Icon(Icons.book),
                                      label: Text('Mulai Baca'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(0, 48),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChapterScreen(
                                              chapterLink:
                                                  manga.chapters.last.link,
                                              mangaTitle: manga.title,
                                              chapters: manga.chapters,
                                              mangaLink: widget.mangaLink,
                                              mangaImage: manga.thumbnail,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : ElevatedButton.icon(
                                      icon: Icon(Icons.play_arrow),
                                      label: Text('Lanjutkan Baca'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(0, 48),
                                      ),
                                      onPressed: () {
                                        final targetChapter =
                                            manga.chapters.firstWhere(
                                          (c) => c.link == _lastReadChapter,
                                          orElse: () => manga.chapters.first,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChapterScreen(
                                              chapterLink: targetChapter.link,
                                              mangaTitle: manga.title,
                                              chapters: manga.chapters,
                                              mangaLink: widget.mangaLink,
                                              mangaImage: manga.thumbnail,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Chapters List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actualIndex = _isChapterReversed
                          ? manga.chapters.length - 1 - index
                          : index;
                      final chapter = manga.chapters[actualIndex];

                      return Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  'Chapter ${manga.chapters.length - actualIndex}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: _readChapters.contains(chapter.link)
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chapter.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color:
                                          _readChapters.contains(chapter.link)
                                              ? Theme.of(context).primaryColor
                                              : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'Diperbarui ${chapter.time}',
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (_readChapters.contains(chapter.link)) ...[
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_readChapters.contains(chapter.link))
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      await _historyService
                                          .removeFromHistory(chapter.link);
                                      await _loadReadChapters();
                                      if (chapter.link == _lastReadChapter) {
                                        await _loadLastRead();
                                      }
                                    },
                                  ),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterScreen(
                                    chapterLink: chapter.link,
                                    mangaTitle: manga.title,
                                    chapters: manga.chapters,
                                    mangaLink: widget.mangaLink,
                                    mangaImage: manga.thumbnail,
                                  ),
                                ),
                              );

                              // Refresh status baca setelah kembali dari chapter
                              if (mounted) {
                                await _loadReadChapters();
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: manga.chapters.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
