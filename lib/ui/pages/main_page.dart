import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/navigator_controller.dart';

import '../../core/broken_icons.dart';
import '../../core/enums.dart';
import '../miniplayer/miniplayer_bar.dart';
import '../pages/settings_page.dart';
import '../widgets/amoled_glow_effect.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'folders_page.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'tracks_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _tabs = LibraryTab.values;

  @override
  void initState() {
    super.initState();
    _ensureScan();
  }

  Future<void> _ensureScan() async {
    final indexer = IndexerController.inst;
    if (indexer.trackList.isNotEmpty || indexer.isLoading) return;
    final has = await indexer.checkPermission();
    if (has && indexer.trackList.isEmpty && !indexer.isLoading) {
      indexer.scanDevice();
    }
  }

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
    FoldersPage(),
  ];

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
              icon: const Icon(Broken.search_normal, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Broken.settings, size: 22),
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
