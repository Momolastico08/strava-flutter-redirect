// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  MaterialColor _primaryColor = Colors.orange;

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    final color = prefs.getString('accentColor') ?? 'orange';

    _themeMode = _parseThemeMode(mode);
    _primaryColor = _parseColor(color);

    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
    _themeMode = _parseThemeMode(mode);
    notifyListeners();
  }

  Future<void> setThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', color);
    _primaryColor = _parseColor(color);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  MaterialColor _parseColor(String color) {
    switch (color) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
      default:
        return Colors.orange;
    }
  }
}

