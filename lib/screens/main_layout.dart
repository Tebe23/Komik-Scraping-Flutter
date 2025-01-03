import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';
import '../models/download_models.dart';
import '../services/download_manager.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Add stream subscription
  StreamSubscription? _downloadSubscription;
  int _currentIndex = 0;
  int _downloadCount = 0; // Add this

  final List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    DownloadsScreen(),  // Now this will work
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToDownloads();
  }

  void _listenToDownloads() {
    final downloadManager = DownloadManager();
    _downloadSubscription = downloadManager.downloadsStream.listen((downloads) {
      if (mounted) {
        setState(() {
          _downloadCount = downloads.values.where((i) => 
            i.status == DownloadStatus.downloading).length;
        });
      }
    });
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _downloadCount > 0,
              label: Text('$_downloadCount'),
              child: Icon(Icons.download_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _downloadCount > 0, 
              label: Text('$_downloadCount'),
              child: Icon(Icons.download),
            ),
            label: 'Unduhan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Setelan',
          ),
        ],
      ),
    );
  }
}
