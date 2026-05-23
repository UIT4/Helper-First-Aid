import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {

  static const String key = 'app_language';

  static final ValueNotifier<Locale?> localeNotifier =
  ValueNotifier<Locale?>(null);

  static Future<void> load() async {

    final prefs = await SharedPreferences.getInstance();

    final lang = prefs.getString(key) ?? 'auto';

    localeNotifier.value = _localeFromLang(lang);
  }

  static Future<void> setLanguage(String lang) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, lang);

    localeNotifier.value = _localeFromLang(lang);
  }

  static Future<String> getLanguage() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(key) ?? 'auto';
  }

  static Locale? _localeFromLang(String lang) {

    switch (lang) {

      case 'ar':
        return const Locale('ar');

      case 'en':
        return const Locale('en');

      default:
        return null;
    }
  }

  static bool isArabicContext(BuildContext context) {

    return Localizations.localeOf(context)
        .languageCode ==
        'ar';
  }

  static String text(
      BuildContext context,
      String en,
      String ar,
      ) {

    return isArabicContext(context)
        ? ar
        : en;
  }
}