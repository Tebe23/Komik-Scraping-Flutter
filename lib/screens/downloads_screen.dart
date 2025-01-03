import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/download_manager.dart';
import '../models/download_models.dart';
import '../services/download_service.dart';
import 'chapter_screen.dart';

class DownloadsScreen extends StatefulWidget {
  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _downloadService = DownloadService();
  final DownloadManager _downloadManager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Unduhan')),
      body: FutureBuilder<List<MangaDownloadGroup>>(
        future: _downloadService.getDownloadedManga(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data unduhan'));
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada unduhan selesai'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) => _buildMangaGroup(groups[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMangaGroup(MangaDownloadGroup group) {
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
}
