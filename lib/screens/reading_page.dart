import 'package:flutter/material.dart';
import '../widgets/reading_progress_bar.dart';
import 'dart:async';

class ReadingPage extends StatefulWidget {
  final List<String> imageUrls; // Pastikan ini adalah daftar URL gambar

  const ReadingPage({Key? key, required this.imageUrls}) : super(key: key);

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _currentPage = (_currentPage + 1) % widget.imageUrls.length;
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading'),
      ),
      body: widget.imageUrls.isNotEmpty
          ? Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls
                        .length, // Total halaman sesuai dengan jumlah gambar
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage =
                            index; // Update current page saat halaman berubah
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
                ReadingProgressBar(
                  currentPage: _currentPage,
                  totalPages: widget.imageUrls.length,
                  onPageSelected: (page) {
                    _pageController.animateToPage(
                      page,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            )
          : Center(child: Text('No images available')),
    );
  }
}
