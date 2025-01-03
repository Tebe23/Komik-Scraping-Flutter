class DownloadedChapterMetadata {
  final String localPath;
  final String originalLink;
  final String chapterTitle;
  final DateTime downloadedAt;

  DownloadedChapterMetadata({
    required this.localPath,
    required this.originalLink,
    required this.chapterTitle,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'localPath': localPath,
    'originalLink': originalLink,
    'chapterTitle': chapterTitle,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory DownloadedChapterMetadata.fromJson(Map<String, dynamic> json) {
    return DownloadedChapterMetadata(
      localPath: json['localPath'],
      originalLink: json['originalLink'],
      chapterTitle: json['chapterTitle'],
      downloadedAt: DateTime.parse(json['downloadedAt']),
    );
  }
}
