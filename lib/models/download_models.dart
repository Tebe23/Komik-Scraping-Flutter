enum DownloadStatus { queued, downloading, paused, completed, failed, canceled }

class MangaDownloadGroup {
  final String mangaId;
  final String title;
  final String image;
  final List<DownloadItem> items;

  MangaDownloadGroup({
    required this.mangaId,
    required this.title,
    required this.image,
    required this.items,
  });

  bool get isCompleted => items.every((item) => item.status == DownloadStatus.completed);
  int get completedCount => items.where((item) => item.status == DownloadStatus.completed).length;
  double get totalProgress {
    if (items.isEmpty) return 0;
    return items.map((i) => i.progress).reduce((a, b) => a + b) / items.length;
  }
}

class DownloadItem {
  final String id; // Unique identifier
  final String mangaTitle;
  final String mangaLink;
  final String mangaImage;
  final String chapterTitle;
  final String chapterLink;
  final List<String> imageUrls;
  DownloadStatus status;
  double progress;
  String? error;
  DateTime? startTime;
  DateTime? endTime;

  DownloadItem({
    String? id,
    required this.mangaTitle,
    required this.mangaLink,
    required this.mangaImage,
    required this.chapterTitle,
    required this.chapterLink,
    required this.imageUrls,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.error,
    this.startTime,
    this.endTime,
  }) : id = id ?? '${mangaLink}_$chapterLink';

  bool get isActive => 
    status == DownloadStatus.downloading || 
    status == DownloadStatus.queued ||
    status == DownloadStatus.paused;

  bool get canRetry =>
    status == DownloadStatus.failed ||
    status == DownloadStatus.canceled;
    
  bool get isPaused => status == DownloadStatus.paused;

  bool get isFinished =>
    status == DownloadStatus.completed || 
    status == DownloadStatus.failed;

  bool isValidId() {
    return id.isNotEmpty && 
           mangaLink.isNotEmpty && 
           chapterLink.isNotEmpty;
  }

  void markAs(DownloadStatus newStatus) {
    status = newStatus;
    if (newStatus == DownloadStatus.completed || 
        newStatus == DownloadStatus.failed) {
      endTime = DateTime.now();
    }
  }

  String get mangaId => mangaLink; // Add this getter
  
  String getLocalPath() {
    final sanitizedManga = mangaTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final sanitizedChapter = chapterTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return 'MangaDownloads/$sanitizedManga/$sanitizedChapter';
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is DownloadItem &&
        runtimeType == other.runtimeType &&
        id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mangaTitle': mangaTitle,
      'mangaLink': mangaLink,
      'mangaImage': mangaImage,
      'chapterTitle': chapterTitle,
      'chapterLink': chapterLink,
      'imageUrls': imageUrls,
      'status': status.index,
      'progress': progress,
      'error': error,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'],
      mangaTitle: map['mangaTitle'],
      mangaLink: map['mangaLink'],
      mangaImage: map['mangaImage'],
      chapterTitle: map['chapterTitle'],
      chapterLink: map['chapterLink'],
      imageUrls: List<String>.from(map['imageUrls']),
      status: DownloadStatus.values[map['status']],
      progress: map['progress'],
      error: map['error'],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }
}
