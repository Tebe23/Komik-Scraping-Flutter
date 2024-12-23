import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import '../models/manga_detail.dart';
import '../utils/constants.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  Future<void> downloadChapter(ChapterInfo chapter, List<String> imageUrls) async {
    try {
      final archive = Archive();
      int index = 0;

      for (String url in imageUrls) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final filename = '${index.toString().padLeft(3, '0')}.jpg';
          archive.addFile(
            ArchiveFile(filename, response.bodyBytes.length, response.bodyBytes)
          );
          index++;
        }
      }

      final outputStream = ZipEncoder().encode(archive);
      if (outputStream != null) {
        final file = await _localFile('${chapter.title}.cbz');
        await file.writeAsBytes(outputStream);
      }
    } catch (e) {
      print('Error downloading chapter: $e');
      rethrow;
    }
  }

  Future<List<String>> getDownloadedChapters() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      return dir
          .listSync()
          .where((item) => item.path.endsWith('.cbz'))
          .map((item) => item.path)
          .toList();
    } catch (e) {
      print('Error getting downloaded chapters: $e');
      return [];
    }
  }

  Future<void> deleteDownloadedChapter(String filepath) async {
    try {
      final file = File(filepath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting chapter: $e');
      rethrow;
    }
  }
}