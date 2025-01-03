import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import '../services/scraping_service.dart';
import '../models/manga_models.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/chapter_list_drawer.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/advanced_image.dart';
import '../widgets/reading_progress_bar.dart';
import '../services/history_service.dart';
import '../models/history_model.dart';
import '../services/reading_state_service.dart';

class ChapterScreen extends StatefulWidget {
  final String chapterLink;
  final String mangaTitle;
  final List<ChapterInfo>? chapters;
  final String? mangaLink;
  final String? mangaImage;
  final bool isDownloaded;
  final String? localPath;

  const ChapterScreen({
    Key? key,
    required this.chapterLink,
    required this.mangaTitle,
    this.chapters,
    this.mangaLink,
    this.mangaImage,
    this.isDownloaded = false,
    this.localPath,
  }) : super(key: key);

  @override
  _ChapterScreenState createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  final HistoryService _historyService = HistoryService();
  final ReadingStateService _readingStateService = ReadingStateService();
  late Future<ChapterData> _chapterFuture;
  late ScrollController _scrollController;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _autoScrollTimer;
  Timer? _brightnessUpdateTimer;

  double _brightness = 1.0;
  bool _autoScroll = false;
  double _scrollSpeed = 1.0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _chapterFuture = _scrapingService.scrapeChapter(widget.chapterLink);
      _scrollController = ScrollController()..addListener(_handleScroll);
      _startHideTimer();

      await _historyService.addToHistory(
        ReadHistory(
          mangaTitle: widget.mangaTitle,
          mangaLink: widget.mangaLink ?? '',
          mangaImage: widget.mangaImage ?? '',
          chapterTitle: 'Chapter ${widget.chapterLink}',
          chapterLink: widget.chapterLink,
          readAt: DateTime.now(),
        ),
      );

      final chapterData = await _chapterFuture;
      if (!mounted) return;

      await _historyService.addToHistory(
        ReadHistory(
          mangaTitle: widget.mangaTitle,
          mangaLink: widget.mangaLink ?? '',
          mangaImage: widget.mangaImage ?? '',
          chapterTitle: chapterData.title,
          chapterLink: widget.chapterLink,
          readAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final page = (currentScroll / MediaQuery.of(context).size.height).floor();

      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReaderSettingsSheet(
        brightness: _brightness,
        autoScroll: _autoScroll,
        scrollSpeed: _scrollSpeed,
        onBrightnessChanged: (value) {
          setState(() => _brightness = value);
        },
        onAutoScrollChanged: (value) {
          setState(() => _autoScroll = value);
          _startAutoScroll();
        },
        onScrollSpeedChanged: (value) {
          setState(() => _scrollSpeed = value);
          if (_autoScroll) _startAutoScroll();
        },
      ),
    );
  }

  void _startAutoScroll() {
    if (_autoScroll) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
        if (_scrollController.hasClients) {
          final newOffset = _scrollController.offset + (_scrollSpeed * 0.5);
          if (newOffset >= _scrollController.position.maxScrollExtent) {
            timer.cancel();
            setState(() => _autoScroll = false);
          } else {
            _scrollController.animateTo(
              newOffset,
              duration: Duration(milliseconds: 16),
              curve: Curves.linear,
            );
          }
        }
      });
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _updateBrightness(double value) {
    setState(() => _brightness = value);
    _brightnessUpdateTimer?.cancel();
    _brightnessUpdateTimer = Timer(Duration(milliseconds: 16), () {
      if (mounted) setState(() {});
    });
  }

  Future<List<String>> _getLocalImages() async {
    if (!widget.isDownloaded || widget.localPath == null) return [];

    try {
      final path = widget.localPath!;
      print('Reading from: $path'); // Tambah log ini
      
      final dir = Directory(path);
      if (!await dir.exists()) {
        print('Directory does not exist: $path'); // Tambah log ini
        return [];
      }

      final List<String> images = [];
      final contents = await dir.list().toList();
      print('Found ${contents.length} files'); // Tambah log ini
      
      for (var file in contents) {
        print('Found file: ${file.path}'); // Tambah log ini
        if (file is File && file.path.endsWith('.jpg')) {
          images.add(file.path);
        }
      }
      
      images.sort();
      print('Found ${images.length} images'); // Tambah log ini
      return images;
    } catch (e) {
      print('Error loading local images: $e');
      return [];
    }
  }

  Widget _buildImageList(ChapterData chapter) {
    if (widget.isDownloaded) {
      return FutureBuilder<List<String>>(
        future: _getLocalImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Tidak dapat memuat gambar lokal'),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return Image.file(
                File(snapshot.data![index]),
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    height: 400,
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64),
                        Text('Failed to load image'),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }

    // Online reading
    return ListView.builder(
      controller: _scrollController,
      itemCount: chapter.images.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: chapter.images[index],
          placeholder: (context, url) => ShimmerLoading(
            width: double.infinity,
            height: 400,
          ),
          errorWidget: (context, url, error) => Container(
            height: 400,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64),
                Text('Failed to load image'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _showControls
            ? AppBar(
                elevation: 0,
                title: FutureBuilder<ChapterData>(
                  future: _chapterFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!.title,
                        style: TextStyle(color: Colors.white),
                      );
                    }
                    return Text(widget.mangaTitle);
                  },
                ),
              )
            : null,
        endDrawer: widget.chapters != null
            ? ChapterListDrawer(
                chapters: widget.chapters!,
                currentChapterLink: widget.chapterLink,
                mangaTitle: widget.mangaTitle,
              )
            : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            Opacity(
              opacity: _brightness,
              child: SafeArea(
                child: FutureBuilder<ChapterData>(
                  future: _chapterFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _chapterFuture = _scrapingService
                                      .scrapeChapter(widget.chapterLink);
                                });
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) => ShimmerLoading(
                          width: double.infinity,
                          height: 400,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),
                      );
                    }

                    final chapter = snapshot.data!;
                    return GestureDetector(
                      onTap: _toggleControls,
                      child: Stack(
                        children: [
                          _buildImageList(chapter),
                          if (_showControls)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Card(
                                color: Colors.black.withOpacity(0.7),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (chapter.prevChapter != null)
                                        IconButton(
                                          icon: Icon(Icons.skip_previous,
                                              color: Colors.white),
                                          onPressed: () =>
                                              Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChapterScreen(
                                                chapterLink:
                                                    chapter.prevChapter!,
                                                mangaTitle: widget.mangaTitle,
                                                chapters: widget.chapters,
                                                mangaLink: widget.mangaLink,
                                                mangaImage: widget.mangaImage,
                                              ),
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.list,
                                            color: Colors.white),
                                        onPressed: () => Scaffold.of(context)
                                            .openEndDrawer(),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.settings,
                                            color: Colors.white),
                                        onPressed: _showSettings,
                                      ),
                                      if (chapter.nextChapter != null)
                                        IconButton(
                                          icon: Icon(Icons.skip_next,
                                              color: Colors.white),
                                          onPressed: () =>
                                              Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChapterScreen(
                                                chapterLink:
                                                    chapter.nextChapter!,
                                                mangaTitle: widget.mangaTitle,
                                                chapters: widget.chapters,
                                                mangaLink: widget.mangaLink,
                                                mangaImage: widget.mangaImage,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _showControls
            ? Container(
                color: Colors.black.withOpacity(0.5),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<ChapterData>(
                        future: _chapterFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox.shrink();
                          return ReadingProgressBar(
                            currentPage: _currentPage,
                            totalPages: snapshot.data!.images.length,
                            onPageSelected: (page) {
                              _scrollController.animateTo(
                                page * MediaQuery.of(context).size.height,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _autoScrollTimer?.cancel();
    _brightnessUpdateTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
