import 'dart:async';

class ReadingStateService {
  static final ReadingStateService _instance = ReadingStateService._internal();
  factory ReadingStateService() => _instance;
  ReadingStateService._internal();

  final _readingController = StreamController<String>.broadcast();
  Stream<String> get onChapterRead => _readingController.stream;

  void markChapterAsRead(String chapterLink) {
    _readingController.add(chapterLink);
  }

  void dispose() {
    _readingController.close();
  }
}
