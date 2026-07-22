import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/core/app_navigator.dart';
import 'package:flutter_apps/src/core/app_theme.dart';
import 'package:flutter_apps/src/features/auth/splash_page.dart';

class CityGoRemitApp extends StatefulWidget {
  const CityGoRemitApp({super.key});

  @override
  State<CityGoRemitApp> createState() => _CityGoRemitAppState();
}

class _CityGoRemitAppState extends State<CityGoRemitApp> {
  @override
  void initState() {
    super.initState();
    AppLanguageController.load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.notifier,
      builder: (context, language, child) {
        return MaterialApp(
          navigatorKey: AppNavigator.key,
          debugShowCheckedModeBanner: false,
          title: AppText.t('app_title'),
          theme: AppTheme.light(),
          home: const SplashPage(),
        );
      },
    );
  }
}
