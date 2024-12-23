class Manga {
  final String title;
  final String link;
  final String imageUrl;
  final String chapter;
  final String score;
  final String updateTime;
  final String type;
  final String status;

  Manga({
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.chapter,
    required this.score,
    required this.updateTime,
    required this.type,
    required this.status,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['image'] ?? '',
      chapter: json['chapter'] ?? 'N/A',
      score: json['score'] ?? 'N/A',
      updateTime: json['update_time'] ?? '',
      type: json['type'] ?? 'N/A',
      status: json['status'] ?? 'N/A',
    );
  }
}