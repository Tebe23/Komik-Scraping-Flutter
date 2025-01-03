import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../services/history_service.dart';
import '../models/grouped_history.dart';
import '../widgets/shimmer_loading.dart';
import 'chapter_screen.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();

  Widget _buildChapterItem(ReadHistory chapter, int index) {
    return Dismissible(
      key: Key(chapter.chapterLink),
      background: Container(
        color: Colors.red[400],
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await _historyService.removeFromHistory(chapter.chapterLink);
        setState(() {});
      },
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          chapter.chapterTitle,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              _formatDate(chapter.readAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterScreen(
              chapterLink: chapter.chapterLink,
              mangaTitle: chapter.mangaTitle,
              mangaLink: chapter.mangaLink,
              mangaImage: chapter.mangaImage,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMangaHistoryCard(GroupedHistory group) {
    final latestChapter = group.chapters.first; // Get only the latest chapter
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(mangaLink: group.mangaLink),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'manga-${group.mangaLink}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    group.mangaImage,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.mangaTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Terakhir dibaca:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      latestChapter.chapterTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDate(latestChapter.readAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${group.chapters.length} chapter dibaca',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add loading shimmer effect
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        margin: EdgeInsets.only(bottom: 16),
        child: Container(
          height: 140,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              ShimmerLoading(
                width: 80,
                height: 120,
                borderRadius: 10,
                margin: EdgeInsets.zero, // Add margin
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 20,
                      borderRadius: 4,
                      margin: EdgeInsets.zero, // Add margin
                    ),
                    SizedBox(height: 8),
                    ShimmerLoading(
                      width: 100,
                      height: 16,
                      borderRadius: 4,
                      margin: EdgeInsets.zero, // Add margin
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Baca'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Hapus Semua',
            onPressed: _showClearHistoryDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<ReadHistory>>(
        future: _historyService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat baca',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mulai baca manga favoritmu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.book),
                    label: Text('Jelajahi Manga'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedHistories = GroupedHistory.groupHistories(snapshot.data!);

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: groupedHistories.length,
            itemBuilder: (context, index) => _buildMangaHistoryCard(groupedHistories[index]),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showClearHistoryDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Riwayat'),
        content: Text('Hapus semua riwayat baca?'),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Hapus'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearHistory();
      setState(() {});
    }
  }
}
