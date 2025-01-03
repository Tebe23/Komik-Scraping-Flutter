import 'package:flutter/material.dart';
import '../services/download_manager.dart';
import '../models/download_models.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadProgressScreen extends StatefulWidget {
  @override
  _DownloadProgressScreenState createState() => _DownloadProgressScreenState();
}

class _DownloadProgressScreenState extends State<DownloadProgressScreen> {
  final DownloadManager _downloadManager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proses Unduhan'),
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
            ],
          ),
        ],
      ),
      body: StreamBuilder<Map<String, DownloadItem>>(
        stream: _downloadManager.downloadsStream,
        initialData: {},
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          final groups = _downloadManager.getActiveGroups();

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tidak ada unduhan yang sedang berlangsung'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: group.image,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(group.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${group.items.length} chapter'),
                      LinearProgressIndicator(
                        value: group.totalProgress,
                        backgroundColor: Colors.grey[200],
                      ),
                      Text(
                        '${(group.totalProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  children: group.items.map((item) => ListTile(
                    dense: true,
                    title: Text(item.chapterTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.status == DownloadStatus.failed)
                          Text(
                            item.error ?? 'Gagal mengunduh',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          )
                        else
                          LinearProgressIndicator(value: item.progress),
                        Text(
                          '${(item.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: _buildActionButton(item),
                  )).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: Icon(Icons.pause),
          onPressed: () => _downloadManager.pauseDownload(item.id),
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () => _downloadManager.resumeDownload(item.id),
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () => _downloadManager.retryDownload(item.id),
        );
      default:
        return Icon(Icons.downloading);
    }
  }
}
