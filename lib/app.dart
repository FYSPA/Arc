import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/current_color_controller.dart';
import 'controller/indexer_controller.dart';
import 'controller/navigator_controller.dart';
import 'controller/player_controller.dart';
import 'controller/settings_controller.dart';
import 'core/themes.dart';
import 'ui/pages/splash_page.dart';

class ArcApp extends StatelessWidget {
  const ArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.inst;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: NavigatorController.inst),
        ChangeNotifierProvider.value(value: IndexerController.inst),
        ChangeNotifierProvider.value(value: PlayerController.inst),
        ChangeNotifierProvider.value(value: CurrentColorController.inst),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Arc',
            debugShowCheckedModeBanner: false,
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            themeMode: settings.themeMode,
            theme: AppThemes.light(settings.mainColor),
            darkTheme: AppThemes.dark(
              settings.mainColor,
              isAmoled: settings.useAmoledBlack,
            ),
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
