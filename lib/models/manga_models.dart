class Manga {
  final String title;
  final String link;
  final String image;
  final String latestChapter;
  final String score;
  final String type;
  final String status;

  Manga({
    required this.title,
    required this.link,
    required this.image,
    required this.latestChapter,
    required this.score,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'link': link,
        'image': image,
        'latestChapter': latestChapter,
        'score': score,
        'type': type,
        'status': status,
      };

  factory Manga.fromJson(Map<String, dynamic> json) => Manga(
        title: json['title'],
        link: json['link'],
        image: json['image'],
        latestChapter: json['latestChapter'],
        score: json['score'],
        type: json['type'],
        status: json['status'],
      );
}

class MangaDetail {
  final String thumbnail;
  final String title;
  final String synopsis;
  final List<String> genres;
  final List<ChapterInfo> chapters;
  final String author; // Add this line

  MangaDetail({
    required this.thumbnail,
    required this.title,
    required this.synopsis,
    required this.genres,
    required this.chapters,
    this.author = 'Unknown', // Add this line
  });
}

class ChapterInfo {
  final String title;
  final String link;
  final String time;

  ChapterInfo ({
    required this.title,
    required this.link,
    required this.time,
  });
}

class ChapterData {
  final String title;
  final String? prevChapter;
  final String? nextChapter;
  final List<String> images;

  ChapterData({
    required this.title,
    this.prevChapter,
    this.nextChapter,
    required this.images,
  });
}
