import '../models/history_model.dart';

class GroupedHistory {
  final String mangaTitle;
  final String mangaLink;
  final String mangaImage;
  final List<ReadHistory> chapters;

  GroupedHistory({
    required this.mangaTitle,
    required this.mangaLink,
    required this.mangaImage,
    required this.chapters,
  });

  static List<GroupedHistory> groupHistories(List<ReadHistory> histories) {
    final Map<String, GroupedHistory> groups = {};

    for (var history in histories) {
      if (!groups.containsKey(history.mangaLink)) {
        groups[history.mangaLink] = GroupedHistory(
          mangaTitle: history.mangaTitle,
          mangaLink: history.mangaLink,
          mangaImage: history.mangaImage,
          chapters: [],
        );
      }
      groups[history.mangaLink]!.chapters.add(history);
    }

    // Sort chapters by readAt
    for (var group in groups.values) {
      group.chapters.sort((a, b) => b.readAt.compareTo(a.readAt));
    }

    // Sort groups by most recent chapter
    final sortedGroups = groups.values.toList();
    sortedGroups.sort((a, b) {
      final aDate = a.chapters.isNotEmpty ? a.chapters.first.readAt : DateTime(0);
      final bDate = b.chapters.isNotEmpty ? b.chapters.first.readAt : DateTime(0);
      return bDate.compareTo(aDate);
    });

    return sortedGroups;
  }
} 