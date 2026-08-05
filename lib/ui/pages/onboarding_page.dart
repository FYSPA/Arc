import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../widgets/animated_check_mark.dart';
import 'main_page.dart';
import 'subpages/onboarding_appearance.dart';
import 'subpages/onboarding_library.dart';
import 'subpages/onboarding_permissions.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding(SettingsController settings) {
    settings.completeOnboarding();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    OnboardingAppearancePage(settings: settings),
                    OnboardingPermissionsPage(),
                    OnboardingLibraryPage(settings: settings),
                  ],
                ),
              ),
              _DotIndicators(current: _currentPage, total: 3),
              const SizedBox(height: 8.0),
              _ActionBottomBar(
                currentPage: _currentPage,
                hasPermission: context.watch<IndexerController>().hasPermission,
                onContinue: _nextPage,
                onGrantPermission: () async {
                  await IndexerController.inst.requestPermission();
                },
                onDone: () => _completeOnboarding(settings),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot Indicators
// ---------------------------------------------------------------------------

class _DotIndicators extends StatelessWidget {
  final int current;
  final int total;

  const _DotIndicators({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 8.0 : 6.0,
          height: isActive ? 8.0 : 6.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Bottom Bar
// ---------------------------------------------------------------------------

class _ActionBottomBar extends StatelessWidget {
  final int currentPage;
  final bool hasPermission;
  final VoidCallback onContinue;
  final VoidCallback onGrantPermission;
  final VoidCallback onDone;

  const _ActionBottomBar({
    required this.currentPage,
    required this.hasPermission,
    required this.onContinue,
    required this.onGrantPermission,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentPage == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Done',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (currentPage == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: hasPermission ? null : onGrantPermission,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: hasPermission
                          ? Colors.green.withAlpha(20)
                          : theme.colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        width: 1.0,
                        color: hasPermission
                            ? Colors.green.withAlpha(60)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedCheckMark(size: 16.0, active: hasPermission),
                        const SizedBox(width: 8.0),
                        Text(
                          hasPermission ? 'Granted' : 'Grant Access',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasPermission ? 1.0 : 0.4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: hasPermission ? onContinue : null,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: hasPermission
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Broken.arrow_right,
                      size: 18.0,
                      color: hasPermission
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Page 0: simple Continue button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onContinue,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Broken.arrow_right,
                  size: 18.0,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
