import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';

import '../../core/broken_icons.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../miniplayer/miniplayer_bar.dart';
import '../pages/settings_page.dart';
import '../widgets/amoled_glow_effect.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'home_page.dart';
import 'tracks_page.dart';

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
    TracksPage(),
    AlbumsPage(),
    ArtistsPage(),
    _PlaceholderPage(title: 'Folders'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission = await IndexerController.inst.checkPermission();
      if (hasPermission) {
        IndexerController.inst.scanDevice();
      }
      PlayerController.inst.initMediaSessionCommands();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigatorController>();
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
          actions: [
            IconButton(
              icon: const Icon(Broken.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
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
            const MiniplayerBar(),
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
