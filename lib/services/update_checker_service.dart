import 'package:workmanager/workmanager.dart';
import 'favorites_service.dart';
import 'notification_service.dart';
import 'scraping_service.dart';

class UpdateCheckerService {
  static final UpdateCheckerService _instance = UpdateCheckerService._internal();
  factory UpdateCheckerService() => _instance;
  UpdateCheckerService._internal();

  static const taskName = 'checkMangaUpdates';

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == taskName) {
        await checkForUpdates();
      }
      return true;
    });
  }

  static Future<void> checkForUpdates() async {
    final favorites = await FavoritesService().getFavorites();
    final scraping = ScrapingService();
    final notifications = NotificationService();

    for (final manga in favorites) {
      try {
        final details = await scraping.scrapeMangaDetail(manga.link);
        if (details.chapters.isNotEmpty) {
          final latestChapter = details.chapters.first;
          if (latestChapter.title != manga.latestChapter) {
            await notifications.showChapterUpdateNotification(
              mangaTitle: manga.title,
              chapterTitle: latestChapter.title,
              mangaLink: manga.link,
            );
            
            // Update stored latest chapter
            await FavoritesService().updateLatestChapter(
              manga.link, 
              latestChapter.title
            );
          }
        }
      } catch (e) {
        print('Error checking updates for ${manga.title}: $e');
      }
      
      // Add delay between requests
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
