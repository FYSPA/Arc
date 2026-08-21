import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/utils.dart';
import 'main_page.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _dataReady = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _preloadData();

    Future.delayed(const Duration(milliseconds: 5870), () {
      if (!mounted || _navigating) return;
      _finishSplash();
    });
  }

  Future<void> _preloadData() async {
    try {
      final indexer = IndexerController.inst;
      final hasPermission = await indexer.checkPermission();
      // Only auto-scan on relaunch (already onboarded). On a fresh install the
      // scan must wait until the user finishes onboarding and chooses folders,
      // otherwise it would index everything with the empty default selection.
      if (hasPermission && SettingsController.inst.isOnboarded) {
        indexer.scanDevice();
      }
      PlayerController.inst.initMediaSessionCommands();
      await PlayerController.inst.restorePlaybackState();
    } catch (e, st) {
      logE('[ARC] splash preload failed: $e', st);
    }
    if (mounted) setState(() => _dataReady = true);
  }

  void _finishSplash() {
    if (_dataReady) {
      _navigating = true;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        _navigateToNext();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _navigating) return;
        _finishSplash();
      });
    }
  }

  void _navigateToNext() {
    final settings = SettingsController.inst;
    final destination = settings.isOnboarded
        ? const MainPage()
        : const OnboardingPage();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );

    // Keep the chrome hidden during the splash's fade-out so it doesn't flash
    // "on top of" the splash; reveal it once the destination is showing. Set
    // the flag unconditionally: it's a global singleton and must flip even
    // after this page is disposed by the pushReplacement.
    Future.delayed(const Duration(milliseconds: 500), () {
      NavigatorController.inst.isSplash = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildGif(bool isDark) {
    final gif = Image.asset(
      'assets/Logos/ArcVideo.gif',
      width: 200.0,
      gaplessPlayback: true,
    );

    if (!isDark) return gif;

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Colors.white],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: gif,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: bgColor,
        statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGif(isDark),
                const SizedBox(height: 16.0),
                Text(
                  'Arc',
                  style: TextStyle(
                    fontFamily: 'LexendDeca',
                    fontWeight: FontWeight.w700,
                    fontSize: 28.0,
                    letterSpacing: 6.0,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
