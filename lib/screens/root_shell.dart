import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/edge_gesture_guard.dart';
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
  final _pageKeys = List.generate(3, (_) => GlobalKey());
  List<int> _pageOrder = [0, 1, 2];
  bool _switching = false;
  int? _pendingTab;

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

  Future<void> _goToTab(int index) async {
    if (_switching) {
      _pendingTab = index;
      return;
    }
    if (index == _tabIndex) return;
    final source = _tabIndex;
    final shortcut = (index - source).abs() > 1;
    _switching = true;
    setState(() {
      _tabIndex = index;
      // Put the current screen immediately beside the destination for this
      // animation. Stable keys preserve screen state when the order changes.
      if (shortcut) {
        _pageOrder = index > source ? [1, 0, 2] : [0, 2, 1];
      }
    });
    if (shortcut) {
      _pageController.jumpToPage(_pageOrder.indexOf(source));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await _pageController.animateToPage(
      _pageOrder.indexOf(index),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    if (shortcut) {
      setState(() => _pageOrder = [0, 1, 2]);
      _pageController.jumpToPage(index);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    setState(() => _switching = false);
    final pending = _pendingTab;
    _pendingTab = null;
    if (pending != null && pending != _tabIndex) _goToTab(pending);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
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
            // No AnimatedBuilder here — each tab (already) listens to
            // appState on its own for just what it needs, so this stays a
            // stable PageView instead of rebuilding all three tabs together
            // on every single AppState change anywhere in the app.
            Positioned.fill(
              // Left/right guard against Android's own back gesture at the
              // screen edges — needed because this PageView (the tab swipe)
              // reaches all the way to both edges. topExclusion carves out
              // HomeScreen's own top strip (its city row, sitting at rest
              // right under the status bar) from that guard, so that button
              // stays tappable near the edges without the row having to
              // leave HomeScreen's normal scrolling content — see
              // HomeScreen's build() for the matching height. Bottom guards
              // against the swipe-up-to-minimize strip the same way, scoped
              // to just the scrolling content and not FloatingTabBar below.
              child: EdgeGestureGuard(
                left: true,
                right: true,
                bottom: true,
                topExclusion: MediaQuery.paddingOf(context).top + 70,
                child: RepaintBoundary(
                  child: PageView(
                    controller: _pageController,
                    physics: _switching
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (i) {
                      if (!_switching) {
                        setState(() => _tabIndex = _pageOrder[i]);
                      }
                    },
                    children: [
                      for (final i in _pageOrder)
                        KeyedSubtree(
                          key: _pageKeys[i],
                          child: switch (i) {
                            0 => HomeScreen(appState: appState),
                            1 => MoreScreen(appState: appState),
                            _ => SettingsScreen(appState: appState),
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: FloatingTabBar(index: _tabIndex, onSelect: _goToTab),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
