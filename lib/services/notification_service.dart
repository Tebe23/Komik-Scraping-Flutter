import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
  }

  Future<void> showChapterUpdateNotification({
    required String mangaTitle,
    required String chapterTitle,
    required String mangaLink,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chapter_updates',
      'Chapter Updates',
      channelDescription: 'Notifications for new manga chapters',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Chapter Baru: $mangaTitle',
      chapterTitle,
      NotificationDetails(android: androidDetails),
      payload: mangaLink,
    );
  }
}
