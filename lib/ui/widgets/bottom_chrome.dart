import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/enums.dart';
import '../miniplayer/miniplayer_bar.dart';

/// Persistent bottom chrome (miniplayer + navigation bar) shown above every
/// route. Hidden while the full-screen player is open.
class BottomChrome extends StatelessWidget {
  const BottomChrome({super.key});

  static const _tabIcons = <IconData>[
    Broken.home_2,
    Broken.musicnote,
    Broken.music_dashboard,
    Broken.user,
    Broken.folder_open,
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    if (player.isFullPlayerOpen) return const SizedBox.shrink();

    final nav = context.watch<NavigatorController>();
    final theme = Theme.of(context);
    final currentIndex = nav.currentPageIndex;

    return Column(
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
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => nav.navigateTo(i),
            destinations: [
              for (int i = 0; i < LibraryTab.values.length; i++)
                NavigationDestination(
                  icon: Icon(_tabIcons[i]),
                  label: LibraryTab.values[i].label,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
