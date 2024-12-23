import 'package:flutter/material.dart';
import '../services/scraping_service.dart';
import '../models/manga_models.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_screen.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import '../services/cache_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  final CacheService _cacheService = CacheService();
  List<Manga> _popularMangaList = [];
  List<Manga> _latestMangaList = [];
  bool _isLoadingPopular = true;
  bool _isLoadingLatest = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPopular = true;
      _isLoadingLatest = true;
      _error = null;
    });

    try {
      // Try to load from cache first
      final cachedData = await _cacheService.getCachedHomeData();
      if (cachedData != null) {
        if (!mounted) return;
        setState(() {
          _popularMangaList = cachedData['popular']!;
          _latestMangaList = cachedData['latest']!;
          _isLoadingPopular = false;
          _isLoadingLatest = false;
        });
        return;
      }

      // If no cache, load from network
      await _loadMangaLists();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingPopular = false;
        _isLoadingLatest = false;
      });
    }
  }

  Future<void> _loadMangaLists() async {
    try {
      final futures = await Future.wait([
        _scrapingService.scrapePopularManga(),
        _scrapingService.scrapeLatestManga(),
      ]);

      if (!mounted) return;
      setState(() {
        _popularMangaList = futures[0];
        _latestMangaList = futures[1];
        _isLoadingPopular = false;
        _isLoadingLatest = false;
      });

      // Cache the data
      await _cacheService.cacheHomeData(
        popularManga: _popularMangaList,
        latestManga: _latestMangaList,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingPopular = false;
        _isLoadingLatest = false;
      });
    }
  }

  Widget _buildMangaSection(
      String title, List<Manga> mangaList, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: isLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 5,
                  itemBuilder: (context, index) => ShimmerLoading(
                    width: 160,
                    height: 280,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: mangaList.length,
                  itemBuilder: (context, index) => SizedBox(
                    width: 160,
                    child: MangaCard(manga: mangaList[index]),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMangaLists,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'KomikApp',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Cari manga...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (query) {
                      if (query.isNotEmpty) {
                        _searchFocus.unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchScreen(initialQuery: query),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    );
                  },
                ),
              ],
            ),
            if (_error != null)
              SliverFillRemaining(
                child: ErrorScreen(
                  message: 'Koneksi Error',
                  onRetry: _loadMangaLists,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMangaSection(
                      'Komik Populer',
                      _popularMangaList,
                      _isLoadingPopular,
                    ),
                    _buildMangaSection(
                      'Komik Terbaru',
                      _latestMangaList,
                      _isLoadingLatest,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

class MangaCard extends StatelessWidget {
  final Manga manga;

  const MangaCard({Key? key, required this.manga}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailScreen(mangaLink: manga.link)),
      ),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'manga-${manga.link}',
                    child: Image.network(
                      manga.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        manga.type,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            manga.score,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            manga.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            manga.latestChapter,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
