import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/navigator_controller.dart';

import '../../core/broken_icons.dart';
import '../../core/enums.dart';
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
      ),
    );
  }
}
