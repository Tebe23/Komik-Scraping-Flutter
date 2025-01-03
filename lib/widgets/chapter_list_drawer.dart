import 'package:flutter/material.dart';
import '../models/manga_models.dart';
import '../screens/chapter_screen.dart';
import '../services/download_service.dart';

class ChapterListDrawer extends StatelessWidget {
  final List<ChapterInfo> chapters;
  final String currentChapterLink;
  final String mangaTitle;
  final String? mangaLink;
  final String? mangaImage;
  final bool isDownloaded;

  const ChapterListDrawer({
    Key? key,
    required this.chapters,
    required this.currentChapterLink,
    required this.mangaTitle,
    this.mangaLink,
    this.mangaImage,
    this.isDownloaded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              mangaTitle,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrentChapter = chapter.link == currentChapterLink;
                
                return ListTile(
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: isCurrentChapter ? 
                        Theme.of(context).primaryColor : null,
                      fontWeight: isCurrentChapter ? 
                        FontWeight.bold : null,
                    ),
                  ),
                  selected: isCurrentChapter,
                  onTap: () async {
                    if (!isCurrentChapter) {
                      String? localPath;
                      if (isDownloaded) {
                        final downloadService = DownloadService();
                        try {
                          // Get full chapter path for offline reading
                          final groups = await downloadService.getDownloadedManga();
                          final mangaGroup = groups.firstWhere(
                            (group) => group.title == mangaTitle,
                          );
                          final downloadItem = mangaGroup.items.firstWhere(
                            (item) => item.chapterTitle == chapter.title,
                          );
                          localPath = await downloadService.getFullChapterPath(downloadItem);
                        } catch (e) {
                          print('Error getting local path: $e');
                        }
                      }

                      if (!context.mounted) return;

                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChapterScreen(
                            chapterLink: chapter.link,
                            mangaTitle: mangaTitle,
                            chapters: chapters,
                            mangaLink: mangaLink,
                            mangaImage: mangaImage,
                            isDownloaded: isDownloaded,
                            localPath: localPath,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
