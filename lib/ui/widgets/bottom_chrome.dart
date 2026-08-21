import 'package:flutter/material.dart';

import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/extensions.dart';
import '../miniplayer/miniplayer_bar.dart';
import '../pages/library_tabs.dart';

/// Persistent bottom chrome (miniplayer + navigation bar) shown above every
/// route. Hidden while the full-screen player is open, on the splash screen and
/// on the settings page. The miniplayer stays visible on top of album/artist
/// detail pages, but the navigation bar is hidden there.
class BottomChrome extends StatelessWidget {
  const BottomChrome({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen directly to the controller singletons instead of relying on
    // `context.watch`. `BottomChrome` is built inside `MaterialApp.builder`,
    // where inherited notifier changes don't reliably trigger a rebuild the
    // way they do for in-route widgets. Listening to the singletons directly
    // guarantees the chrome reacts to every visibility flag change.
    return ListenableBuilder(
      listenable: Listenable.merge([
        PlayerController.inst,
        NavigatorController.inst,
        SettingsController.inst,
      ]),
      builder: (context, _) {
        final player = PlayerController.inst;
        final nav = NavigatorController.inst;
        final settings = SettingsController.inst;

        // Hide the whole chrome on the splash screen, settings, and the full
        // player. The miniplayer stays visible on top of album/artist detail
        // pages, but the navigation bar is hidden there.
        final showChrome =
            !player.isFullPlayerOpen && !nav.isSplash && !nav.isSettingsOpen;

        final showNavBar =
            settings.navbarMode != NavbarMode.hidden && !nav.isDetailOpen;

        final theme = Theme.of(context);
        final currentIndex = nav.currentPageIndex;

        final tabs = orderedLibraryTabs(settings.libraryTabs);

        if (!showChrome) return const SizedBox.shrink();

        final isCompact = settings.navbarMode == NavbarMode.compact;

        return Overlay.wrap(
          alwaysSizeToContent: true,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniplayerBar(),
                if (showNavBar)
                  Material(
                    type: MaterialType.transparency,
                    color: isCompact
                        ? Colors.transparent
                        : theme.navigationBarTheme.backgroundColor,
                    elevation: isCompact ? 0.0 : 22.0,
                    child: _BottomNavBar(
                      tabs: tabs,
                      currentIndex: currentIndex,
                      isCompact: isCompact,
                      indicatorColor: Color.alphaBlend(
                        theme.colorScheme.primary.withAlpha(20),
                        theme.colorScheme.secondaryContainer,
                      ),
                      selectedColor: theme.colorScheme.onSecondaryContainer,
                      unselectedColor: theme.colorScheme.onSurfaceVariant,
                      onTap: (i) => nav.navigateTo(i),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lightweight bottom navigation bar that replaces the framework's
/// [NavigationBar]. Unlike [NavigationBar], which reserves a fixed height and
/// centers its icons (leaving a dead band of empty space above the buttons),
/// this bar hugs its content so it sits flush under the miniplayer.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.isCompact,
    required this.indicatorColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final List<({String name, IconData icon, Widget page})> tabs;
  final int currentIndex;
  final bool isCompact;
  final Color indicatorColor;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 52.0 : 64.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: _NavDestination(
                icon: tabs[i].icon,
                label: tabs[i].name,
                selected: i == currentIndex,
                showLabel: !isCompact && i == currentIndex,
                indicatorColor: indicatorColor,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.indicatorColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final Color indicatorColor;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected ? selectedColor : unselectedColor;
    return InkResponse(
      onTap: onTap,
      containedInkWell: true,
      highlightColor: Colors.transparent,
      splashColor: indicatorColor.withOpacityExt(0.3),
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Container(
                    width: 48.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                Icon(icon, size: 24.0, color: contentColor),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 4.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.0, color: contentColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
