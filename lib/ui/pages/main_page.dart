import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/navigator_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../miniplayer/miniplayer_bar.dart';
import '../widgets/amoled_glow_effect.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _tabs = LibraryTab.values;

  static const _tabIcons = <IconData>[
    Broken.home_2,
    Broken.musicnote,
    Broken.music_dashboard,
    Broken.user,
    Broken.folder_open,
  ];

  static const _tabPages = <Widget>[
    HomePage(),
    _PlaceholderPage(title: 'Songs'),
    _PlaceholderPage(title: 'Albums'),
    _PlaceholderPage(title: 'Artists'),
    _PlaceholderPage(title: 'Folders'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigatorController>();
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final currentIndex = nav.currentPageIndex;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.appBarTheme.backgroundColor,
        statusBarBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(_tabs[currentIndex].label),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            const AmoledGlowEffect(),
            IndexedStack(index: currentIndex, children: _tabPages),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniplayerBar(accentColor: settings.mainColor),
            NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: theme.navigationBarTheme.backgroundColor,
                indicatorColor: Color.alphaBlend(
                  theme.colorScheme.primary.withAlpha(20),
                  theme.colorScheme.secondaryContainer,
                ),
              ),
              child: NavigationBar(
                animationDuration: const Duration(seconds: 1),
                elevation: 22,
                height: 64.0,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: currentIndex,
                onDestinationSelected: (i) => nav.navigateTo(i),
                destinations: [
                  for (int i = 0; i < _tabs.length; i++)
                    NavigationDestination(
                      icon: Icon(_tabIcons[i]),
                      label: _tabs[i].label,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Broken.musicnote,
            size: 48.0,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Coming soon',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
