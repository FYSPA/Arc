import 'package:flutter/widgets.dart';

import 'player_controller.dart';

class NavigatorController extends ChangeNotifier {
  NavigatorController._();
  static final inst = NavigatorController._();

  /// Root navigator key, used to push routes (e.g. the full player) from
  /// widgets that live outside the navigator tree (the persistent chrome).
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Shared key for the full-player artwork. The miniplayer reads its on-screen
  /// rect (after the player route builds) to drive the open "shared element"
  /// flight that lifts the thumbnail into the player.
  final playerArtworkKey = GlobalKey();

  /// Current track artwork image, published by the miniplayer so the player's
  /// close-flight can reuse the same pixels without re-decoding.
  ImageProvider? currentArtworkImage;

  /// Last on-screen rect of the miniplayer artwork. Used as the close-flight
  /// landing target, since the miniplayer is collapsed while the player is
  /// open (its own key is not in the tree then).
  Rect? miniplayerArtworkRect;

  /// Hides the miniplayer artwork while a flight is in progress so the slot
  /// reads as empty and the airborne artwork doesn't double up.
  final miniplayerArtworkHidden = ValueNotifier<bool>(false);

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  void navigateTo(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// Sets the initial page index without notifying listeners. Used during
  /// [MainPage.initState] so the first build reads the correct index without
  /// triggering a `setState`/`markNeedsBuild` while the tree is still building.
  void initPageIndex(int index) {
    if (index >= 0) _currentPageIndex = index;
  }

  // --- Chrome visibility flags ---------------------------------------------

  /// True while the splash screen is the active route.
  bool _isSplash = true;
  bool get isSplash => _isSplash;
  set isSplash(bool v) {
    if (_isSplash != v) {
      _isSplash = v;
      notifyListeners();
    }
  }

  /// True while the Settings page is pushed on top.
  bool _isSettingsOpen = false;
  bool get isSettingsOpen => _isSettingsOpen;
  set isSettingsOpen(bool v) {
    if (_isSettingsOpen != v) {
      _isSettingsOpen = v;
      notifyListeners();
    }
  }

  /// Depth of album/artist detail pages currently on the stack. The miniplayer
  /// stays visible on top of them but the navigation bar is hidden. Driven by
  /// [ChromeNavigatorObserver], which inspects the navigator route stack.
  int _detailDepth = 0;
  bool get isDetailOpen => _detailDepth > 0;
  void setDetailDepth(int depth) {
    if (_detailDepth != depth) {
      _detailDepth = depth;
      notifyListeners();
    }
  }
}

/// Mirrors the navigator's route stack and drives the bottom-chrome visibility
/// flags from it, so the chrome hides/shows *in sync* with route transitions
/// (at push/pop start) instead of lagging a frame behind mount/dispose.
///
/// Routes opt in by setting [RouteSettings.name] to one of: 'player',
/// 'settings', 'album', 'artist'. The deferred notify avoids firing
/// [ChangeNotifier.notifyListeners] while the navigator is still building.
class ChromeNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final i = _stack.indexOf(oldRoute);
      if (i != -1 && newRoute != null) {
        _stack[i] = newRoute;
      } else if (newRoute != null) {
        _stack.add(newRoute);
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = NavigatorController.inst;
      var isPlayer = false;
      var isSettings = false;
      var detailDepth = 0;
      for (final r in _stack) {
        switch (r.settings.name) {
          case 'player':
            isPlayer = true;
          case 'settings':
            isSettings = true;
          case 'album':
          case 'artist':
            detailDepth++;
        }
      }
      PlayerController.inst.setFullPlayerOpen(isPlayer);
      nav.isSettingsOpen = isSettings;
      nav.setDetailDepth(detailDepth);
    });
  }
}
