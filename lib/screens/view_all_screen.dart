import 'package:flutter/material.dart';
import '../models/manga_models.dart';
import '../services/scraping_service.dart';
import '../widgets/shimmer_loading.dart';
import 'home_screen.dart';
import 'detail_screen.dart';

class ViewAllScreen extends StatefulWidget {
  final String title;
  final bool isPopular;

  const ViewAllScreen({
    Key? key,
    required this.title,
    required this.isPopular,
  }) : super(key: key);

  @override
  _ViewAllScreenState createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  final ScrollController _scrollController = ScrollController();
  List<Manga> _mangaList = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _hasMore) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (_isLoading && _currentPage != 1) return;

    try {
      List<Manga> newManga;
      if (widget.isPopular) {
        newManga = await _scrapingService.scrapePopularManga(page: _currentPage);
      } else {
        newManga = await _scrapingService.scrapeLatestManga(page: _currentPage);
      }

      if (!mounted) return;
      
      setState(() {
        _mangaList.addAll(newManga);
        _currentPage++;
        _hasMore = newManga.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _mangaList.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading && _mangaList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _mangaList.length + (_hasMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= _mangaList.length) {
                    return ShimmerLoading(
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailScreen(mangaLink: _mangaList[index].link),
                      ),
                    ),
                    child: MangaCard(manga: _mangaList[index]),
                  );
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
