class MangaDetail {
  final String thumbnail;
  final String title;
  final String nativeTitle;
  final String synopsis;
  final List<String> genres;
  final String release;
  final String author;
  final String status;
  final String type;
  final String totalChapter;
  final String updatedOn;
  final String rating;
  final List<ChapterInfo> chapters;

  MangaDetail({
    required this.thumbnail,
    required this.title,
    required this.nativeTitle,
    required this.synopsis,
    required this.genres,
    required this.release,
    required this.author,
    required this.status,
    required this.type,
    required this.totalChapter,
    required this.updatedOn,
    required this.rating,
    required this.chapters,
  });
}

class ChapterInfo {
  final String title;
  final String link;
  final String time;

  ChapterInfo({
    required this.title,
    required this.link,
    required this.time,
  });
}