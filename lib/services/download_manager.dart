import 'dart:async';
import '../models/download_models.dart';
import 'download_service.dart';
import 'settings_service.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal() {
    // Initialize with empty data
    _emitUpdate();
  }

  final DownloadService _service = DownloadService();
  final Map<String, DownloadItem> _downloads = {};
  final _downloadController = StreamController<Map<String, DownloadItem>>.broadcast();
  bool _isProcessing = false;
  final SettingsService _settingsService = SettingsService();
  
  Stream<Map<String, DownloadItem>> get downloadsStream => _downloadController.stream.asBroadcastStream();
  Map<String, DownloadItem> get downloads => Map.unmodifiable(_downloads);
  List<DownloadItem> get activeDownloads => 
    _downloads.values.where((item) => item.isActive).toList();
  List<DownloadItem> get completedDownloads => 
    _downloads.values.where((item) => item.isFinished).toList();

  Future<void> addDownload(DownloadItem item) async {
    if (_downloads.containsKey(item.id)) return;
    
    _downloads[item.id] = item;
    _emitUpdate();
    
    if (!_isProcessing) {
      _processDownloads();
    }
  }

  Future<void> addDownloads(List<DownloadItem> items) async {
    bool hasNew = false;
    for (var item in items) {
      if (!_downloads.containsKey(item.id)) {
        _downloads[item.id] = item;
        hasNew = true;
      }
    }
    
    if (hasNew) {
      _emitUpdate();
      if (!_isProcessing) {
        _processDownloads();
      }
    }
  }

  void pauseDownload(String id) {
    final item = _downloads[id];
    if (item != null && item.status == DownloadStatus.downloading) {
      item.status = DownloadStatus.paused;
      _emitUpdate();
    }
  }

  void resumeDownload(String id) {
    final item = _downloads[id];
    if (item != null && item.status == DownloadStatus.paused) {
      item.status = DownloadStatus.queued;
      _emitUpdate();
      if (!_isProcessing) {
        _processDownloads();
      }
    }
  }

  void cancelDownload(String id) {
    final item = _downloads[id];
    if (item != null) {
      item.markAs(DownloadStatus.canceled);
      _downloads.remove(id);
      _emitUpdate();
    }
  }

  void retryDownload(String id) {
    final item = _downloads[id];
    if (item != null && item.status == DownloadStatus.failed) {
      item.status = DownloadStatus.queued;
      item.progress = 0;
      item.error = null;
      _emitUpdate();
      if (!_isProcessing) {
        _processDownloads();
      }
    }
  }

  void clearCompleted() {
    _downloads.removeWhere((_, item) => 
      item.status == DownloadStatus.completed || 
      item.status == DownloadStatus.canceled
    );
    _emitUpdate();
  }

  void pauseDownloads() {
    for (var item in _downloads.values) {
      if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.queued) {
        item.status = DownloadStatus.paused;
      }
    }
    _emitUpdate();
  }

  void resumeDownloads() {
    for (var item in _downloads.values) {
      if (item.status == DownloadStatus.paused) {
        item.status = DownloadStatus.queued;
      }
    }
    _emitUpdate();
    if (!_isProcessing) {
      _processDownloads();
    }
  }

  void retryFailed() {
    for (var item in _downloads.values) {
      if (item.status == DownloadStatus.failed) {
        item.status = DownloadStatus.queued;
        item.progress = 0;
        item.error = null;
      }
    }
    _emitUpdate();
    if (!_isProcessing) {
      _processDownloads();
    }
  }

  bool get isPaused => 
    _downloads.values.any((item) => item.status == DownloadStatus.paused);

  void _emitUpdate() {
    if (!_downloadController.isClosed) {
      _downloadController.add(Map.from(_downloads));
    }
  }

  Future<void> _processDownloads() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final maxConcurrent = await _settingsService.getMaxConcurrentDownloads();
      
      // Hitung jumlah manga yang sedang diunduh
      final activeMangaIds = _downloads.values
          .where((item) => item.status == DownloadStatus.downloading)
          .map((item) => item.mangaId)
          .toSet();

      while (_downloads.values.any((item) => item.status == DownloadStatus.queued)) {
        // Jika sudah mencapai batas manga yang diunduh bersamaan
        if (activeMangaIds.length >= maxConcurrent) {
          await Future.delayed(Duration(seconds: 1));
          continue;
        }

        // Cari chapter berikutnya dari manga yang sudah diunduh atau manga baru
        final nextItem = _downloads.values.firstWhere(
          (item) => item.status == DownloadStatus.queued && 
                    (activeMangaIds.isEmpty || activeMangaIds.contains(item.mangaId)),
          orElse: () => _downloads.values.firstWhere(
            (item) => item.status == DownloadStatus.queued,
          ),
        );

        nextItem.status = DownloadStatus.downloading;
        nextItem.startTime = DateTime.now();
        activeMangaIds.add(nextItem.mangaId);
        _emitUpdate();

        // Start download in parallel
        unawaited(_downloadChapter(nextItem).then((_) {
          activeMangaIds.remove(nextItem.mangaId);
        }));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _downloadChapter(DownloadItem item) async {
    try {
      await _service.downloadChapter(
        item,
        (progress) {
          if (item.status == DownloadStatus.downloading) {
            item.progress = progress;
            _emitUpdate();
          }
        },
        () {
          item.status = DownloadStatus.completed;
          item.endTime = DateTime.now();
          _emitUpdate();
        },
        (error) {
          item.status = DownloadStatus.failed;
          item.error = error;
          item.endTime = DateTime.now();
          _emitUpdate();
        },
      );
    } catch (e) {
      print('Download error: $e');
    }
  }

  void dispose() {
    if (!_downloadController.isClosed) {
      _downloadController.close();
    }
  }

  List<MangaDownloadGroup> getDownloadGroups() {
    final groups = <String, MangaDownloadGroup>{};
    
    for (var item in _downloads.values) {
      if (!groups.containsKey(item.mangaId)) {
        groups[item.mangaId] = MangaDownloadGroup(
          mangaId: item.mangaId,
          title: item.mangaTitle,
          image: item.mangaImage,
          items: [],
        );
      }
      groups[item.mangaId]!.items.add(item);
    }
    
    return groups.values.toList();
  }

  List<MangaDownloadGroup> getActiveGroups() {
    return getDownloadGroups()
      .where((g) => g.items.any((i) => i.isActive))
      .toList();
  }

  List<MangaDownloadGroup> getCompletedGroups() {
    return getDownloadGroups()
      .where((g) => g.items.every((i) => i.isFinished))
      .toList();
  }

  Future<String> getChapterPath(DownloadItem item) async {
    final dir = await _service.getFullChapterPath(item);
    return dir;
  }

  Future<bool> isChapterDownloaded(DownloadItem item) async {
    return await _service.isChapterDownloaded(item);
  }
}
