import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_tab_bar.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  final AppState appState;

  const RootShell({super.key, required this.appState});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    // Sliding across more than one tab in a single animated scroll forces
    // the skipped-over page to build mid-animation, which is what caused
    // the jank jumping straight from "Намаз" to "Настройки". A plain
    // instant switch for multi-tab jumps avoids that; adjacent taps keep
    // the animated slide.
    final distance = (index - _tabIndex).abs();
    setState(() => _tabIndex = index);
    if (distance <= 1) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return PopScope(
      // On "Ещё"/"Настройки", back should land on "Намаз" first, like a
      // normal bottom-nav — only exit the app once already there.
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToTab(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: appState,
                builder: (context, _) {
                  return PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _tabIndex = i),
                    children: [
                      HomeScreen(
                        key: ValueKey('${appState.selectedCityId}|${appState.method}|${appState.madhab}'),
                        appState: appState,
                      ),
                      MoreScreen(appState: appState),
                      SettingsScreen(appState: appState),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingTabBar(index: _tabIndex, onSelect: _goToTab),
            ),
          ],
        ),
      ),
    );
  }
}
