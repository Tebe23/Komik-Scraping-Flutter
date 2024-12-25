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
  String _selectedType = 'All';

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
              expandedHeight: 120,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.fromLTRB(16, 60, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'KomikApp',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.search, size: 28),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null)
              SliverFillRemaining(
                child: ErrorScreen(
                  message: 'Koneksi Error',
                  onRetry: _loadMangaLists,
                ),
              )
            else ...[
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Cari manga...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor.withOpacity(0.8),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

              // Popular Manga Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Komik Populer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Action for viewing more popular manga
                        },
                        child: Text(
                          'Lihat Lainnya',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Popular Manga List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: _isLoadingPopular
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 5,
                          itemBuilder: (context, index) => ShimmerLoading(
                            width: 180,
                            height: 280,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _popularMangaList.length,
                          itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: 180,
                              child: MangaCard(manga: _popularMangaList[index]),
                            ),
                          ),
                        ),
                ),
              ),

              // Latest Manga Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Komik Terbaru',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            icon: Icon(Icons.keyboard_arrow_down),
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedType = newValue!;
                              });
                            },
                            items: <String>['All', 'Manga', 'Manhua', 'Manhwa']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Latest Manga Grid
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filteredList = _latestMangaList
                          .where((manga) =>
                              _selectedType == 'All' ||
                              manga.type == _selectedType)
                          .toList();
                      return MangaCard(manga: filteredList[index]);
                    },
                    childCount: _latestMangaList
                        .where((manga) =>
                            _selectedType == 'All' ||
                            manga.type == _selectedType)
                        .length,
                  ),
                ),
              ),

              // View More Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Action for viewing more latest manga
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Lihat Lainnya'),
                    ),
                  ),
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
