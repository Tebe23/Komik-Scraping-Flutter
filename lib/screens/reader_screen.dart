import 'package:flutter/material.dart';
import '../models/manga_detail.dart';
import '../services/manga_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReaderScreen extends StatefulWidget {
  final ChapterInfo chapter;

  const ReaderScreen({super.key, required this.chapter});

  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final MangaService _mangaService = MangaService();
  List<String> images = [];
  bool isLoading = true;
  bool showControls = true;

  @override
  void initState() {
    super.initState();
    _loadChapterImages();
  }

  Future<void> _loadChapterImages() async {
    try {
      setState(() => isLoading = true);
      final chapterData = await _mangaService.getChapterImages(widget.chapter.link);
      setState(() {
        images = chapterData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading chapter images: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load chapter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() => showControls = !showControls);
        },
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      );
                    },
                  ),
            if (showControls)
              _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.chapter.title),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.navigate_before),
                    color: Colors.white,
                    onPressed: () {
                      // Navigate to previous chapter
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_next),
                    color: Colors.white,
                    onPressed: () {
                      // Navigate to next chapter
                    },
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