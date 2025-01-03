import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/download_models.dart';

class DownloadService {
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<String> get _downloadPath async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw 'Storage permission required';
      }
      // Change to more accessible location
      final dir = await getExternalStorageDirectory();
      print('Download path: ${dir?.path}/MangaDownloads'); // Tambah log ini
      return '${dir?.path}/MangaDownloads';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/MangaDownloads';
    }
  }

  String _getChapterPath(DownloadItem item) {
    return '${_sanitizePath(item.mangaTitle)}/${_sanitizePath(item.chapterTitle)}';
  }

  Future<String> getFullChapterPath(DownloadItem item) async {
    final basePath = await _downloadPath;
    return '$basePath/${_getChapterPath(item)}';
  }

  Future<List<String>> getDownloadedImages(DownloadItem item) async {
    try {
      final path = await getFullChapterPath(item);
      final dir = Directory(path);
      if (!await dir.exists()) return [];

      final List<String> images = [];
      final contents = await dir.list().toList();
      for (var file in contents.whereType<File>()) {
        if (file.path.endsWith('.jpg')) {
          images.add(file.path);
        }
      }
      return images..sort();
    } catch (e) {
      print('Error getting downloaded images: $e');
      return [];
    }
  }

  Future<void> downloadChapter(
    DownloadItem item,
    void Function(double) onProgress,
    void Function() onComplete,
    void Function(String) onError,
  ) async {
    String? mangaPath;
    
    try {
      final basePath = await _downloadPath;
      mangaPath = '$basePath/${_sanitizePath(item.mangaTitle)}/${_sanitizePath(item.chapterTitle)}';
      print('Saving to: $mangaPath'); // Tambah log ini
      
      final dir = Directory(mangaPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      int completed = 0;
      final client = http.Client();

      try {
        for (int i = 0; i < item.imageUrls.length; i++) {
          if (item.status == DownloadStatus.paused || 
              item.status == DownloadStatus.canceled) {
            client.close();
            await _cleanupFailedDownload(mangaPath);
            return;
          }

          bool success = false;
          for (int retry = 0; retry < _maxRetries && !success; retry++) {
            try {
              final response = await client
                .get(Uri.parse(item.imageUrls[i]))
                .timeout(_timeout);

              if (response.statusCode == 200) {
                final file = File('$mangaPath/page_$i.jpg');
                await file.writeAsBytes(response.bodyBytes);
                success = true;
                completed++;
                onProgress(completed / item.imageUrls.length);
              }
              
              if (!success && retry < _maxRetries - 1) {
                await Future.delayed(_retryDelay);
              }
            } catch (e) {
              if (retry == _maxRetries - 1) throw e;
              await Future.delayed(_retryDelay);
            }
          }

          if (!success) {
            throw 'Failed to download image $i after $_maxRetries attempts';
          }
        }

        onComplete();
      } finally {
        client.close();
      }
    } catch (e) {
      print('Download error: $e');
      if (mangaPath != null) {
        await _cleanupFailedDownload(mangaPath);
      }
      onError(e.toString());
    }
  }

  Future<void> _cleanupFailedDownload(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  Future<bool> _downloadImage({
    required http.Client client,
    required String url,
    required String outputPath,
    required int retryCount,
  }) async {
    try {
      final response = await client.get(Uri.parse(url))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        await File(outputPath).writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _downloadImage(
          client: client,
          url: url,
          outputPath: outputPath,
          retryCount: retryCount + 1,
        );
      }
    }
    return false;
  }

  String _sanitizePath(String path) {
    return path.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<bool> isChapterDownloaded(DownloadItem item) async {
    final basePath = await _downloadPath;
    final mangaPath = '$basePath/${_sanitizePath(item.mangaTitle)}/${_sanitizePath(item.chapterTitle)}';
    final dir = Directory(mangaPath);
    
    if (!await dir.exists()) return false;
    
    final files = await dir.list().length;
    return files == item.imageUrls.length;
  }
}
