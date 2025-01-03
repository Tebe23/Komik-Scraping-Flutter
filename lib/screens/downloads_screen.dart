import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/download_manager.dart';
import '../models/download_models.dart';
import 'chapter_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  final DownloadManager _downloadManager = DownloadManager();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Unduhan'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Sedang Diunduh'),
              Tab(text: 'Selesai'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'pause_all':
                    _downloadManager.pauseDownloads();
                    break;
                  case 'resume_all':
                    _downloadManager.resumeDownloads();
                    break;
                  case 'retry_failed':
                    _downloadManager.retryFailed();
                    break;
                  case 'clear_completed':
                    _downloadManager.clearCompleted();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _downloadManager.isPaused ? 'resume_all' : 'pause_all',
                  child: ListTile(
                    leading: Icon(_downloadManager.isPaused ? Icons.play_arrow : Icons.pause),
                    title: Text(_downloadManager.isPaused ? 'Lanjutkan Semua' : 'Jeda Semua'),
                  ),
                ),
                PopupMenuItem(
                  value: 'retry_failed',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Coba Lagi yang Gagal'),
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_completed',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Bersihkan yang Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: StreamBuilder<Map<String, DownloadItem>>(  // Change type here
          stream: _downloadManager.downloadsStream,      // Use downloadsStream instead of downloads
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final allItems = snapshot.data!.values.toList();
            final activeDownloads = allItems.where(
              (item) => item.status == DownloadStatus.downloading || 
                       item.status == DownloadStatus.queued ||
                       item.status == DownloadStatus.paused
            ).toList();

            final completedDownloads = allItems.where(
              (item) => item.status == DownloadStatus.completed || 
                       item.status == DownloadStatus.failed
            ).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildActiveDownloads(activeDownloads),
                _buildCompletedDownloads(completedDownloads),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveDownloads(List<DownloadItem> items) {
    final groups = _downloadManager.getActiveGroups();
    
    if (groups.isEmpty) {
      return Center(child: Text('Tidak ada unduhan aktif'));
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: _buildMangaThumbnail(group.image),
            title: Text(group.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${group.completedCount}/${group.items.length} chapter'),
                LinearProgressIndicator(
                  value: group.totalProgress,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            children: group.items.map((item) => _buildDownloadItem(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDownloadItem(DownloadItem item) {
    return ListTile(
      dense: true,
      title: Text(
        item.chapterTitle,
        style: TextStyle(fontSize: 14),
      ),
      trailing: _buildStatusIcon(item.status),
      subtitle: item.isActive ? LinearProgressIndicator(
        value: item.progress,
        backgroundColor: Colors.grey[200],
      ) : null,
    );
  }

  Widget _buildCompletedDownloads(List<DownloadItem> items) {
    final groups = _downloadManager.getCompletedGroups();
    
    return FutureBuilder<List<MangaDownloadGroup>>(
      future: _verifyDownloadedGroups(groups),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final verifiedGroups = snapshot.data ?? [];
        if (verifiedGroups.isEmpty) {
          return Center(child: Text('Belum ada unduhan selesai'));
        }

        return ListView.builder(
          itemCount: verifiedGroups.length,
          itemBuilder: (context, index) {
            final group = verifiedGroups[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                leading: _buildMangaThumbnail(group.image),
                title: Text(group.title),
                subtitle: Text('${group.items.length} chapter'),
                children: group.items.map((item) => ListTile(
                  dense: true,
                  title: Text(item.chapterTitle),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                  onTap: () async {
                    final path = await _downloadManager.getChapterPath(item);
                    if (await Directory(path).exists()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChapterScreen(
                            chapterLink: item.chapterLink,
                            mangaTitle: item.mangaTitle,
                            isDownloaded: true,
                            localPath: path,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chapter tidak ditemukan di penyimpanan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<MangaDownloadGroup>> _verifyDownloadedGroups(List<MangaDownloadGroup> groups) async {
    final List<MangaDownloadGroup> verifiedGroups = [];
    
    for (var group in groups) {
      final verifiedItems = <DownloadItem>[];
      
      for (var item in group.items) {
        final path = await _downloadManager.getChapterPath(item);
        final dir = Directory(path);
        if (await dir.exists()) {
          try {
            final files = await dir.list().where((f) => f.path.endsWith('.jpg')).toList();
            if (files.length == item.imageUrls.length) {
              verifiedItems.add(item);
            }
          } catch (e) {
            print('Error verifying chapter: $e');
          }
        }
      }
      
      if (verifiedItems.isNotEmpty) {
        verifiedGroups.add(MangaDownloadGroup(
          mangaId: group.mangaId,
          title: group.title,
          image: group.image,
          items: verifiedItems,
        ));
      }
    }
    
    return verifiedGroups;
  }

  Widget _buildMangaThumbnail(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 40,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, size: 20),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadStatus.completed:
        return Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return Icon(Icons.error, color: Colors.red);
      case DownloadStatus.paused:
        return Icon(Icons.pause_circle_filled);
      default:
        return Icon(Icons.download);
    }
  }
}
