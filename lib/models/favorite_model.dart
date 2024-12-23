class FavoriteManga {
  final String title;
  final String link;
  final String image;
  final String latestChapter;
  final DateTime addedAt;

  FavoriteManga({
    required this.title,
    required this.link,
    required this.image,
    required this.latestChapter,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'link': link,
        'image': image,
        'latestChapter': latestChapter,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoriteManga.fromJson(Map<String, dynamic> json) => FavoriteManga(
        title: json['title'],
        link: json['link'],
        image: json['image'],
        latestChapter: json['latestChapter'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}
