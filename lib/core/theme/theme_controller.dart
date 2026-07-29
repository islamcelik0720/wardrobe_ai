import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemeMode() async {
    final savedTheme = await _preferences.getString(_themeKey);

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final String themeValue;

    switch (mode) {
      case ThemeMode.light:
        themeValue = 'light';
        break;

      case ThemeMode.dark:
        themeValue = 'dark';
        break;

      case ThemeMode.system:
        themeValue = 'system';
        break;
    }

    await _preferences.setString(_themeKey, themeValue);
  }
}

final ThemeController themeController = ThemeController();
