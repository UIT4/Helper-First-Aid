import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/theme_controller.dart';
import 'core/language/app_language.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppLanguage.load();
  await ThemeController.load();

  final prefs = await SharedPreferences.getInstance();

  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isGuest = prefs.getBool('isGuest') ?? false;
  final String? userEmail = prefs.getString('userEmail');
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final bool hasActiveSession =
      isGuest || (isLoggedIn && userEmail != null && userEmail.trim().isNotEmpty);

  runApp(
    RescueAssistant(
      hasActiveSession: hasActiveSession,
      seenOnboarding: seenOnboarding,
    ),
  );
}

class RescueAssistant extends StatelessWidget {
  const RescueAssistant({
    super.key,
    required this.hasActiveSession,
    required this.seenOnboarding,
  });

  final bool hasActiveSession;
  final bool seenOnboarding;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeController.themeNameNotifier,
      builder: (context, themeName, _) {
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
              theme: AppTheme.lightTheme(ThemeController.primaryColor),
              home: hasActiveSession
                  ? const HomeScreen()
                  : seenOnboarding
                  ? const LoginScreen()
                  : const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}