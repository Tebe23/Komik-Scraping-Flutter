import 'package:flutter/material.dart';
import '../models/manga_models.dart';
import '../screens/chapter_screen.dart';

class ChapterListDrawer extends StatelessWidget {
  final List<ChapterInfo> chapters;
  final String currentChapterLink;
  final String mangaTitle;

  const ChapterListDrawer({
    Key? key,
    required this.chapters,
    required this.currentChapterLink,
    required this.mangaTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mangaTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Daftar Chapter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
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
                      fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(chapter.time),
                  selected: isCurrentChapter,
                  selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  onTap: isCurrentChapter
                      ? () => Navigator.pop(context)
                      : () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChapterScreen(
                                chapterLink: chapter.link,
                                mangaTitle: mangaTitle,
                              ),
                            ),
                          );
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
