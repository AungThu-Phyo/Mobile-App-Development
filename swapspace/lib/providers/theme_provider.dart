import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themePreferenceKey = 'theme_mode_dark';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;

    _isDarkMode = enabled;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themePreferenceKey, enabled);
  }
}
