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
import '../services/download_service.dart';

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
  final DownloadService _downloadService = DownloadService();
  late Future<ChapterData> _chapterFuture;
  late ScrollController _scrollController;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _autoScrollTimer;
  Timer? _brightnessUpdateTimer;

  double _brightness = 1.0;
  double _systemBrightness = 1.0;
  static const double maxBrightnessMultiplier = 9.0; // Increased from 3.0 to 9.0 (3x)
  bool _autoScroll = false;
  double _scrollSpeed = 2.0; // Default speed increased
  static const double minScrollSpeed = 0.5;
  static const double maxScrollSpeed = 10.0; // Increased max speed
  int _currentPage = 0;
  List<ChapterInfo>? _offlineChapters;

  // Add scaffold key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeBrightness();
    if (widget.isDownloaded) {
      _loadOfflineChapters();
    }
  }

  Future<void> _saveHistory(String title) async {
    if (!mounted) return;
    
    try {
      String chapterLink = widget.chapterLink;
      String chapterTitle = title;

      if (widget.isDownloaded && widget.localPath != null) {
        // Get original metadata for downloaded chapter
        final downloadService = DownloadService();
        final metadata = await downloadService.getChapterMetadata(
          widget.mangaTitle,
          title
        );
        
        if (metadata['originalLink']?.isNotEmpty == true) {
          chapterLink = metadata['originalLink']!;
          chapterTitle = metadata['title'] ?? title;
        }
      }

      await _historyService.addToHistory(
        ReadHistory(
          mangaTitle: widget.mangaTitle,
          mangaLink: widget.mangaLink ?? '',
          mangaImage: widget.mangaImage ?? '',
          chapterTitle: chapterTitle,
          chapterLink: chapterLink,
          readAt: DateTime.now(),
        ),
      );

      _readingStateService.markChapterAsRead(chapterLink);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> _initializeData() async {
    try {
      _chapterFuture = _scrapingService.scrapeChapter(widget.chapterLink);
      _scrollController = ScrollController()..addListener(_handleScroll);
      _startHideTimer();

      final chapterData = await _chapterFuture;
      if (!mounted) return;

      // Simpan ke history setelah data chapter didapat
      await _saveHistory(chapterData.title);
      
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  Future<void> _loadOfflineChapters() async {
    try {
      final groups = await _downloadService.getDownloadedManga();
      final mangaGroup = groups.firstWhere(
        (group) => group.title == widget.mangaTitle,
        orElse: () => throw 'Manga not found',
      );

      final chapters = <ChapterInfo>[];
      for (var item in mangaGroup.items) {
        chapters.add(ChapterInfo(
          title: item.chapterTitle,
          link: item.chapterLink,
          time: '', // Required field but not used for offline
        ));
      }

      if (mounted) {
        setState(() {
          _offlineChapters = chapters;
        });
      }
    } catch (e) {
      print('Error loading offline chapters: $e');
    }
  }

  void _initializeBrightness() async {
    try {
      final window = WidgetsBinding.instance.window;
      _systemBrightness = 1.0;
      // Start with system brightness
      _brightness = 1.0;
      setState(() {});
    } catch (e) {
      print('Error initializing brightness: $e');
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
      backgroundColor: Colors.transparent,
      isDismissible: true, // Changed to true for better UX
      enableDrag: true,    // Changed to true for better UX
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ReaderSettingsSheet(
          brightness: _brightness,  // Simplified brightness handling
          autoScroll: _autoScroll,
          scrollSpeed: _scrollSpeed,
          minScrollSpeed: minScrollSpeed,
          maxScrollSpeed: maxScrollSpeed,
          maxBrightnessMultiplier: maxBrightnessMultiplier,
          onBrightnessChanged: (value) {
            setState(() => _brightness = value);
          },
          onAutoScrollChanged: (value) {
            if (mounted) {
              setState(() {
                _autoScroll = value;
                if (value) _startAutoScroll();
              });
            }
          },
          onScrollSpeedChanged: (value) {
            if (mounted) {
              setState(() {
                _scrollSpeed = value;
                if (_autoScroll) _startAutoScroll();
              });
            }
          },
        ),
      ),
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    if (_autoScroll) {
      _autoScrollTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
        if (!mounted || !_autoScroll) {
          timer.cancel();
          return;
        }
        
        if (_scrollController.hasClients) {
          if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
            timer.cancel();
            setState(() => _autoScroll = false);
          } else {
            _scrollController.jumpTo(
              _scrollController.offset + (_scrollSpeed * 2.0)
            );
          }
        }
      });
    }
  }

  void _updateBrightness(double value) {
    setState(() => _brightness = value.clamp(0.0, 1.0));
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

  Future<String?> _getOfflineChapterPath(String chapterTitle) async {
    try {
      final groups = await _downloadService.getDownloadedManga();
      final mangaGroup = groups.firstWhere(
        (group) => group.title == widget.mangaTitle,
      );
      
      final downloadItem = mangaGroup.items.firstWhere(
        (item) => item.chapterTitle == chapterTitle,
      );
      
      return await _downloadService.getFullChapterPath(downloadItem);
    } catch (e) {
      print('Error getting offline path: $e');
      return null;
    }
  }

  Widget _buildControlPanel(ChapterData chapter) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          if (_autoScroll) Card(
            color: Colors.black.withOpacity(0.7),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.speed, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _scrollSpeed,
                        min: minScrollSpeed,
                        max: maxScrollSpeed,
                        divisions: 19,
                        label: '${_scrollSpeed.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          setState(() {
                            _scrollSpeed = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.black.withOpacity(0.7),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (chapter.prevChapter != null)
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () async {
                        if (widget.isDownloaded) {
                          // Find previous chapter from offline chapters
                          final currentIndex = _offlineChapters?.indexWhere(
                            (c) => c.link == widget.chapterLink
                          ) ?? -1;
                          if (currentIndex > 0 && _offlineChapters != null) {
                            final prevChapter = _offlineChapters![currentIndex - 1];
                            final localPath = await _getOfflineChapterPath(prevChapter.title);
                            _navigateToChapter(prevChapter.link, localPath);
                          }
                        } else {
                          _navigateToChapter(chapter.prevChapter!, null);
                        }
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.list, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  IconButton(
                    icon: Icon(_autoScroll ? Icons.pause : Icons.play_arrow, 
                         color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _autoScroll = !_autoScroll;
                        if (_autoScroll) {
                          _startAutoScroll();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettings,
                  ),
                  if (chapter.nextChapter != null)
                    IconButton(
                      icon: Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () async {
                        if (widget.isDownloaded) {
                          // Find next chapter from offline chapters
                          final currentIndex = _offlineChapters?.indexWhere(
                            (c) => c.link == widget.chapterLink
                          ) ?? -1;
                          if (currentIndex < (_offlineChapters?.length ?? 0) - 1 && 
                              _offlineChapters != null) {
                            final nextChapter = _offlineChapters![currentIndex + 1];
                            final localPath = await _getOfflineChapterPath(nextChapter.title);
                            _navigateToChapter(nextChapter.link, localPath);
                          }
                        } else {
                          _navigateToChapter(chapter.nextChapter!, null);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChapter(String chapterLink, String? newLocalPath) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterScreen(
          chapterLink: chapterLink,
          mangaTitle: widget.mangaTitle,
          chapters: widget.isDownloaded ? _offlineChapters : widget.chapters,
          mangaLink: widget.mangaLink,
          mangaImage: widget.mangaImage,
          isDownloaded: widget.isDownloaded,
          localPath: newLocalPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clamp opacity value to valid range
    final opacity = _brightness.clamp(0.0, 1.0);
    
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
      ),
      child: Scaffold(
        key: _scaffoldKey, // Add scaffold key here
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
        endDrawer: (widget.chapters != null || _offlineChapters != null) ? 
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Drawer(
              child: ChapterListDrawer(
                chapters: widget.isDownloaded && _offlineChapters != null ? 
                  _offlineChapters! : 
                  widget.chapters ?? [],
                currentChapterLink: widget.chapterLink,
                mangaTitle: widget.mangaTitle,
                mangaLink: widget.mangaLink,
                mangaImage: widget.mangaImage,
                isDownloaded: widget.isDownloaded,
              ),
            ),
          ) : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            Opacity(
              opacity: opacity, // Use clamped value
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
                          if (_showControls) _buildControlPanel(chapter),
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
