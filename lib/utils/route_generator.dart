import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/download_manager_screen.dart';
import '../models/manga.dart';
import '../models/manga_detail.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      
      case '/search':
        return MaterialPageRoute(builder: (_) => SearchScreen());
      
      case '/detail':
        if (args is Manga) {
          return MaterialPageRoute(
            builder: (_) => DetailScreen(manga: args),
          );
        }
        return _errorRoute();
      
      case '/reader':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ReaderScreen(
              chapter: args['chapter'] as ChapterInfo,
            ),
          );
        }
        return _errorRoute();
      
      case '/favorites':
        return MaterialPageRoute(builder: (_) => FavoritesScreen());
      
      case '/history':
        return MaterialPageRoute(builder: (_) => HistoryScreen());
      
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      
      case '/downloads':
        return MaterialPageRoute(builder: (_) => DownloadManagerScreen());
      
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found'),
        ),
      );
    });
  }
}