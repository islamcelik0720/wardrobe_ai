import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends ChangeNotifier {
  static const String _notificationKey = 'notifications_enabled';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  bool _notificationsEnabled = false;

  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> loadNotificationSetting() async {
    _notificationsEnabled =
        await _preferences.getBool(_notificationKey) ?? false;

    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    await _preferences.setBool(_notificationKey, value);
  }
}

final NotificationController notificationController = NotificationController();
