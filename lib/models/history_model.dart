class ReadHistory {
  final String mangaTitle;
  final String mangaLink;
  final String mangaImage;
  final String chapterTitle;
  final String chapterLink;
  final DateTime readAt;

  ReadHistory({
    required this.mangaTitle,
    required this.mangaLink,
    required this.mangaImage,
    required this.chapterTitle,
    required this.chapterLink,
    required this.readAt,
  });

  Map<String, dynamic> toJson() => {
        'mangaTitle': mangaTitle,
        'mangaLink': mangaLink,
        'mangaImage': mangaImage,
        'chapterTitle': chapterTitle,
        'chapterLink': chapterLink,
        'readAt': readAt.toIso8601String(),
      };

  factory ReadHistory.fromJson(Map<String, dynamic> json) => ReadHistory(
        mangaTitle: json['mangaTitle'],
        mangaLink: json['mangaLink'],
        mangaImage: json['mangaImage'],
        chapterTitle: json['chapterTitle'],
        chapterLink: json['chapterLink'],
        readAt: DateTime.parse(json['readAt']),
      );
}
