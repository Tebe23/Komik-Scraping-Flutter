import 'package:flutter/foundation.dart';

class DownloadProgress extends ChangeNotifier {
  final Map<String, _DownloadStatus> _downloads = {};

  void startDownload(String chapterId) {
    _downloads[chapterId] = _DownloadStatus(
      progress: 0,
      status: DownloadState.downloading,
    );
    notifyListeners();
  }

  void updateProgress(String chapterId, double progress) {
    if (_downloads.containsKey(chapterId)) {
      _downloads[chapterId]!.progress = progress;
      notifyListeners();
    }
  }

  void completeDownload(String chapterId) {
    if (_downloads.containsKey(chapterId)) {
      _downloads[chapterId]!.status = DownloadState.completed;
      _downloads[chapterId]!.progress = 1.0;
      notifyListeners();
    }
  }

  void failDownload(String chapterId) {
    if (_downloads.containsKey(chapterId)) {
      _downloads[chapterId]!.status = DownloadState.failed;
      notifyListeners();
    }
  }

  void removeDownload(String chapterId) {
    _downloads.remove(chapterId);
    notifyListeners();
  }

  DownloadState? getDownloadState(String chapterId) {
    return _downloads[chapterId]?.status;
  }

  double getProgress(String chapterId) {
    return _downloads[chapterId]?.progress ?? 0.0;
  }

  bool isDownloading(String chapterId) {
    return _downloads[chapterId]?.status == DownloadState.downloading;
  }
}

class _DownloadStatus {
  double progress;
  DownloadState status;

  _DownloadStatus({
    required this.progress,
    required this.status,
  });
}

enum DownloadState {
  downloading,
  completed,
  failed,
}