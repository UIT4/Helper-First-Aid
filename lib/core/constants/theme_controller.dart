import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const String _prefKey = 'theme_color';

  static final ValueNotifier<String> themeNameNotifier =
  ValueNotifier<String>('blue');

  static Color get primaryColor {
    switch (themeNameNotifier.value) {
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF7C3AED);
      case 'blue':
      default:
        return const Color(0xFF2563EB);
    }
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeNameNotifier.value = prefs.getString(_prefKey) ?? 'blue';
  }

  static Future<void> changeTheme(String themeName) async {
    themeNameNotifier.value = themeName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, themeName);
  }
}
