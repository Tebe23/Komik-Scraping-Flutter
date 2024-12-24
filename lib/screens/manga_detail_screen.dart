import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MangaDetailScreen extends StatelessWidget {
  final String chapterUrl; // URL chapter yang ingin diunduh
  final String chapterTitle; // Judul chapter

  MangaDetailScreen({required this.chapterUrl, required this.chapterTitle});

  Future<void> downloadChapter(BuildContext context) async {
    try {
      // Minta izin untuk akses penyimpanan
      var status = await Permission.storage.request();
      if (status.isGranted) {
        // Dapatkan direktori penyimpanan
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/$chapterTitle.html'; // Tentukan nama file

        // Mengunduh chapter
        final response = await http.get(Uri.parse(chapterUrl));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chapter berhasil diunduh ke $filePath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunduh chapter')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin akses penyimpanan ditolak')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh chapter: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Chapter'),
      ),
      body: Column(
        children: [
          // Konten detail chapter
          Text(chapterTitle),
          ElevatedButton(
            onPressed: () => downloadChapter(context),
            child: Text('Download Chapter'),
          ),
        ],
      ),
    );
  }
}
