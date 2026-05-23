import 'package:flutter/material.dart';

import 'theme_controller.dart';

class AppColors {
  static Color get primary => ThemeController.primaryColor;
  static Color get secondary => ThemeController.primaryColor;

  static const Color blue = Color(0xFF2563EB);
  static const Color orange = Color(0xFFF97316);
  static const Color purple = Color(0xFF7C3AED);

  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF97316);
  static const Color success = Color(0xFF16A34A);

  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  static Future<void> changeTheme(String color) async {
    await ThemeController.changeTheme(color);
  }
}
