import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<String> get _metadataPath async {
    final basePath = await _downloadPath;
    return '$basePath/metadata.json';
  }

  Future<void> saveMetadata(DownloadItem item) async {
    try {
      final path = await _metadataPath;
      final file = File(path);
      Map<String, dynamic> metadata = {};
      
      if (await file.exists()) {
        final content = await file.readAsString();
        metadata = Map<String, dynamic>.from(json.decode(content));
      }

      // Simpan metadata per manga
      if (!metadata.containsKey(item.mangaTitle)) {
        metadata[item.mangaTitle] = {
          'title': item.mangaTitle,
          'link': item.mangaLink,
          'image': item.mangaImage,
          'chapters': {},
        };
      }

      // Simpan metadata chapter
      metadata[item.mangaTitle]['chapters'][item.chapterTitle] = {
        'title': item.chapterTitle,
        'link': item.chapterLink,
        'downloadedAt': DateTime.now().toIso8601String(),
        'imageCount': item.imageUrls.length,
      };

      await file.writeAsString(json.encode(metadata));
    } catch (e) {
      print('Error saving metadata: $e');
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

        await saveMetadata(item);
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

  Future<List<MangaDownloadGroup>> getDownloadedManga() async {
    try {
      final basePath = await _downloadPath;
      final baseDir = Directory(basePath);
      final metadataFile = File('$basePath/metadata.json');
      
      if (!await baseDir.exists()) return [];
      
      Map<String, dynamic> metadata = {};
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        metadata = Map<String, dynamic>.from(json.decode(content));
      }

      final groups = <MangaDownloadGroup>[];
      
      for (var mangaDir in await baseDir.list().where((e) => e is Directory).toList()) {
        if (mangaDir is! Directory) continue;
        
        final mangaName = mangaDir.path.split('/').last;
        final mangaMetadata = metadata[mangaName];
        if (mangaMetadata == null) continue;

        final items = <DownloadItem>[];
        
        for (var chapterDir in await mangaDir.list().where((e) => e is Directory).toList()) {
          if (chapterDir is! Directory) continue;
          
          final chapterName = chapterDir.path.split('/').last;
          final chapterMetadata = mangaMetadata['chapters'][chapterName];
          if (chapterMetadata == null) continue;

          // Verifikasi file gambar
          final imageFiles = await chapterDir
              .list()
              .where((e) => e.path.endsWith('.jpg'))
              .toList();

          if (imageFiles.length == chapterMetadata['imageCount']) {
            items.add(DownloadItem(
              mangaTitle: mangaName,
              mangaLink: mangaMetadata['link'] ?? '',
              mangaImage: mangaMetadata['image'] ?? '',
              chapterTitle: chapterName,
              chapterLink: chapterMetadata['link'] ?? '',
              imageUrls: imageFiles.map((e) => e.path).toList(),
              status: DownloadStatus.completed,
            ));
          }
        }

        if (items.isNotEmpty) {
          groups.add(MangaDownloadGroup(
            mangaId: mangaMetadata['link'] ?? mangaName,
            title: mangaMetadata['title'] ?? mangaName,
            image: mangaMetadata['image'] ?? '',
            items: items,
          ));
        }
      }

      return groups;
    } catch (e) {
      print('Error reading downloaded manga: $e');
      return [];
    }
  }
}
