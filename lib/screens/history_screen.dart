import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../services/history_service.dart';
import '../models/grouped_history.dart';
import 'chapter_screen.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Baca'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () async {
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
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ReadHistory>>(
        future: _historyService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat baca',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final groupedHistories =
              GroupedHistory.groupHistories(snapshot.data!);

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: groupedHistories.length,
            itemBuilder: (context, index) {
              final group = groupedHistories[index];
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          group.mangaImage,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 50,
                            height: 70,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      title: Text(group.mangaTitle),
                      subtitle: Text('${group.chapters.length} chapter dibaca'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailScreen(mangaLink: group.mangaLink),
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: group.chapters.length,
                      itemBuilder: (context, chapterIndex) {
                        final chapter = group.chapters[chapterIndex];
                        return ListTile(
                          dense: true,
                          title: Text(chapter.chapterTitle),
                          subtitle: Text(
                            'Dibaca ${_formatDate(chapter.readAt)}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              await _historyService
                                  .removeFromHistory(chapter.chapterLink);
                              setState(() {});
                            },
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
                        );
                      },
                    ),
                  ],
                ),
              );
            },
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
}
