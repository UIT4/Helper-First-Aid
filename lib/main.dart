import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/constants/app_theme.dart';
import 'core/language/app_language.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppLanguage.load();

  runApp(const RescueAssistant());
}

class RescueAssistant extends StatelessWidget {
  const RescueAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLanguage.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rescue Assistant',
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme(),
          home: const SplashScreen(),
        );
      },
    );
  }
}