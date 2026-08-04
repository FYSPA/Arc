import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/navigator_controller.dart';
import 'controller/settings_controller.dart';
import 'core/themes.dart';
import 'ui/pages/main_page.dart';
import 'ui/pages/onboarding_page.dart';

class ArcApp extends StatelessWidget {
  const ArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.inst;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: NavigatorController.inst),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Arc',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppThemes.light(settings.mainColor),
            darkTheme: AppThemes.dark(
              settings.mainColor,
              isAmoled: settings.useAmoledBlack,
            ),
            home: settings.isOnboarded
                ? const MainPage()
                : const OnboardingPage(),
          );
        },
      ),
    );
  }
}
