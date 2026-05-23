import 'package:flutter/material.dart';

class AppColors {

  static Color primary =
  const Color(0xFF2563EB);

  static Color secondary =
  const Color(0xFF2563EB);

  static const Color blue =
  Color(0xFF2563EB);

  static const Color orange =
  Color(0xFFF97316);

  static const Color purple =
  Color(0xFF7C3AED);

  static const Color danger =
  Color(0xFFDC2626);

  static const Color warning =
  Color(0xFFF97316);

  static const Color success =
  Color(0xFF16A34A);

  static const Color background =
  Color(0xFFF8FAFC);

  static const Color card =
  Color(0xFFF1F5F9);

  static const Color textPrimary =
  Color(0xFF0F172A);

  static const Color textSecondary =
  Color(0xFF475569);

  static void changeTheme(
      String color,
      ) {

    switch (color) {

      case 'orange':

        primary = orange;
        secondary = orange;
        break;

      case 'purple':

        primary = purple;
        secondary = purple;
        break;

      default:

        primary = blue;
        secondary = blue;
    }
  }
}