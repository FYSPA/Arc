import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';

import '../../core/broken_icons.dart';
import '../pages/settings_page.dart';
import 'library_tabs.dart';
import 'tracks_page.dart';
import '../widgets/amoled_glow_effect.dart';
import 'search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

/// Canonical tabs that have a real destination page. `libraryTabs` (configurable
/// in settings) is filtered against [kLibraryTabs], so unknown entries (e.g.
/// legacy "Genres") are dropped and the nav always has valid pages.
class _MainPageState extends State<MainPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _ensureScan();
    _initDefaultTab();
    _pageController = PageController(
      initialPage: NavigatorController.inst.currentPageIndex,
    );
    NavigatorController.inst.addListener(_onNavChange);
  }

  @override
  void dispose() {
    NavigatorController.inst.removeListener(_onNavChange);
    _pageController.dispose();
    super.dispose();
  }

  void _onNavChange() {
    final i = NavigatorController.inst.currentPageIndex;
    if ((_pageController.page?.round() ?? -1) != i) {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _ensureScan() async {
    final indexer = IndexerController.inst;
    if (indexer.trackList.isNotEmpty || indexer.isLoading) return;
    final has = await indexer.checkPermission();
    if (has && indexer.trackList.isEmpty && !indexer.isLoading) {
      indexer.scanDevice();
    }
  }

  void _initDefaultTab() {
    final tabs = orderedLibraryTabs(SettingsController.inst.libraryTabs);
    final def = SettingsController.inst.defaultLibraryTab;
    final idx = tabs.indexWhere((t) => t.name == def);
    NavigatorController.inst.initPageIndex(idx >= 0 ? idx : 0);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsController>();
    final nav = context.watch<NavigatorController>();
    final theme = Theme.of(context);
    final currentIndex = nav.currentPageIndex;

    final tabs = orderedLibraryTabs(SettingsController.inst.libraryTabs);
    final tabPages = tabs.map((t) => t.page).toList();
    final safeIndex = currentIndex.clamp(0, tabs.length - 1);
    final isSongs = tabs[safeIndex].name == 'Songs';

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
          title: Text(tabs[safeIndex].name),
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
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'settings'),
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const AmoledGlowEffect(),
            PageView(
              controller: _pageController,
              onPageChanged: (i) => nav.navigateTo(i),
              children: tabPages.map((p) => _KeepAlivePage(p)).toList(),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context, isSongs),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isSongs) {
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);

    // On the Songs page the FAB becomes a "locate" button that scrolls the list
    // to the currently playing track (or the next one, per settings).
    if (isSongs) {
      return FloatingActionButton(
        tooltip: 'Ubicar canción',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: player.hasTrack
            ? TracksPageController.inst.jumpToCurrent
            : null,
        child: const Icon(Broken.arrow_down_2, size: 22),
      );
    }

    final type = SettingsController.inst.fabType;

    IconData icon;
    VoidCallback? onPressed;
    switch (type) {
      case 'play':
        icon = player.isPlaying ? Broken.pause : Broken.play;
        onPressed = player.playPause;
      case 'shuffle':
        icon = Broken.shuffle;
        onPressed = player.toggleShuffleMode;
      default:
        icon = Broken.search_normal;
        onPressed = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
    }

    return FloatingActionButton(
      tooltip: type == 'play'
          ? 'Play/Pause'
          : type == 'shuffle'
          ? 'Shuffle'
          : 'Search',
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      onPressed: onPressed,
      child: Icon(icon, size: 22),
    );
  }
}

/// Keeps the library tab page mounted while it is off-screen inside the
/// [PageView], preserving the scroll position and state the previous
/// [IndexedStack] kept alive, without having to edit every tab page.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage(this.child);

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
