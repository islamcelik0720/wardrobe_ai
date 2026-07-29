import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<bool> requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? granted = await androidPlugin?.requestNotificationsPermission();

    return granted ?? false;
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'wardrobe_reminders',
      'Kombin Hatırlatıcıları',
      channelDescription: 'Planlanan kombinler için hatırlatma bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 1,
      title: 'WardrobeAI',
      body: 'Bildirim sistemi başarıyla çalışıyor 🎉',
      notificationDetails: notificationDetails,
    );
  }
}
