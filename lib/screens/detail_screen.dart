import 'package:flutter/material.dart';
import '../services/scraping_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../models/manga_models.dart';
import '../models/history_model.dart';
import 'chapter_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../services/reading_state_service.dart';
import '../services/download_service.dart';
import '../services/download_manager.dart'; // Add this
import 'dart:async';
import '../models/download_models.dart';

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
  final DownloadService _downloadService = DownloadService();
  final DownloadManager _downloadManager = DownloadManager(); // Add this
  late Future<MangaDetail> _mangaDetailFuture;
  bool _isFavorite = false;
  bool _isChapterReversed = false;
  bool _isExpandedSynopsis = false;
  String? _lastReadChapter;
  List<String> _readChapters = [];
  StreamSubscription? _readingSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _listenToReadingChanges();
  }

  void _listenToReadingChanges() {
    _readingSubscription =
        _readingStateService.onChapterRead.listen((chapterLink) {
      if (_isDisposed) return;
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
    _isDisposed = true;
    _readingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_isDisposed) return;
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

  Future<void> _downloadSelectedChapters(
    List<ChapterInfo> chapters,
    MangaDetail manga, 
    BuildContext contextDialog
  ) async {
    if (!mounted) return;

    try {
      final items = <DownloadItem>[];
      
      // Create download items
      for (var chapter in chapters) {
        final downloadId = '${widget.mangaLink}_${chapter.link}';
        if (_downloadManager.downloads.containsKey(downloadId)) continue;

        final chapterData = await _scrapingService.scrapeChapter(chapter.link);
        if (chapterData.images.isEmpty) continue;

        items.add(DownloadItem(
          id: downloadId,
          mangaTitle: manga.title,
          mangaLink: widget.mangaLink,
          mangaImage: manga.thumbnail,
          chapterTitle: chapter.title,
          chapterLink: chapter.link,
          imageUrls: chapterData.images,
        ));
      }

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tidak ada chapter baru untuk diunduh'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      // Add to download queue
      await _downloadManager.addDownloads(items);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Memulai unduhan ${items.length} chapter'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memulai unduhan'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showDownloadOptions(BuildContext context, MangaDetail manga) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.download_done),
              title: Text('Unduh Semua Chapter (${manga.chapters.length})'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (mounted) {
                  _downloadSelectedChapters(manga.chapters, manga, context);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.new_releases),
              title: Text('Unduh Chapter Belum Dibaca'),
              subtitle: Text(
                '${manga.chapters.where((c) => !_readChapters.contains(c.link)).length} chapter'
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (mounted) {
                  final unreadChapters = manga.chapters
                      .where((chapter) => !_readChapters.contains(chapter.link))
                      .toList();
                  _downloadSelectedChapters(unreadChapters, manga, context);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add_check),
              title: Text('Pilih Chapter untuk Diunduh'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (mounted) {
                  _showChapterSelectionDialog(context, manga);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterSelectionDialog(
      BuildContext parentContext, MangaDetail manga) {
    if (!mounted) return;
    List<ChapterInfo> selectedChapters = [];

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pilih Chapter'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Header dengan tombol Pilih Semua/Hapus Semua
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.select_all),
                      label: Text('Pilih Semua'),
                      onPressed: () => setDialogState(() {
                        selectedChapters = List.from(manga.chapters);
                      }),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.clear_all),
                      label: Text('Hapus Semua'),
                      onPressed: () => setDialogState(() {
                        selectedChapters.clear();
                      }),
                    ),
                  ],
                ),
                Divider(),
                // List chapter yang dapat di-scroll
                Expanded(
                  child: ListView.builder(
                    itemCount: manga.chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = manga.chapters[index];
                      final isSelected = selectedChapters.contains(chapter);

                      return CheckboxListTile(
                        title: Text(
                          chapter.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'Chapter ${manga.chapters.length - index}',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedChapters.add(chapter);
                            } else {
                              selectedChapters.remove(chapter);
                            }
                          });
                        },
                        dense: true,
                        activeColor: Theme.of(context).primaryColor,
                        checkColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Unduh (${selectedChapters.length})'),
              onPressed: selectedChapters.isEmpty
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      if (mounted) {
                        _downloadSelectedChapters(
                          selectedChapters,
                          manga,
                          dialogContext,
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.download,
            color: Colors.white,
          ),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ));
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
                  actions: [
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: () => _showDownloadOptions(context, manga),
                    ),
                  ],
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
                                // Chapter number with fixed width
                                Container(
                                  width: 80, // Fixed width for chapter number
                                  child: Text(
                                    'Chapter ${manga.chapters.length - actualIndex}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: _readChapters.contains(chapter.link)
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Chapter title with flexible width
                                Expanded(
                                  child: Text(
                                    chapter.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: _readChapters.contains(chapter.link)
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Diperbarui ${chapter.time}',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
                                    constraints: BoxConstraints(
                                      minWidth: 40,
                                      maxWidth: 40,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      await _historyService
                                          .removeFromHistory(chapter.link);
                                      await _loadReadChapters();
                                      if (chapter.link == _lastReadChapter) {
                                        await _loadLastRead();
                                      }
                                    },
                                  ),
                                Icon(Icons.chevron_right, size: 20),
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
