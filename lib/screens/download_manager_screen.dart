import 'package:flutter/material.dart';
import 'dart:io';
import '../services/download_service.dart';
import '../models/manga_detail.dart';

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  _DownloadManagerScreenState createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final DownloadService _downloadService = DownloadService();
  List<String> downloadedChapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedChapters();
  }

  Future<void> _loadDownloadedChapters() async {
    setState(() => isLoading = true);
    try {
      final chapters = await _downloadService.getDownloadedChapters();
      setState(() {
        downloadedChapters = chapters;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading downloaded chapters: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  Future<void> _deleteChapter(String filepath) async {
    try {
      await _downloadService.deleteDownloadedChapter(filepath);
      setState(() {
        downloadedChapters.remove(filepath);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete chapter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloadedChapters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showDeleteAllDialog();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : downloadedChapters.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No downloaded chapters',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: downloadedChapters.length,
                  itemBuilder: (context, index) {
                    final filepath = downloadedChapters[index];
                    final file = File(filepath);
                    final filename = filepath.split('/').last;
                    
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(filename.replaceAll('.cbz', '')),
                      subtitle: Text(_formatFileSize(file)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(filepath),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openChapter(filepath),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteDialog(String filepath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: const Text('Are you sure you want to delete this chapter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChapter(filepath);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: const Text('Are you sure you want to delete all downloaded chapters?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllChapters();
            },
            child: const Text(
              'DELETE ALL',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllChapters() async {
    try {
      for (String filepath in downloadedChapters) {
        await _downloadService.deleteDownloadedChapter(filepath);
      }
      setState(() {
        downloadedChapters.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chapters deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete all chapters')),
      );
    }
  }

  void _openChapter(String filepath) {
    // Implement chapter viewer
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChapterViewerScreen(filepath: filepath),
    //   ),
    // );
  }
}