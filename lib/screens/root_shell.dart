import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_tab_bar.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'settings_screen.dart';

/// Root tab shell hosting the primary screens (Намаз / Ещё / Настройки).
/// The tab bar floats over the content rather than reserving its own
/// row, so screens scroll underneath it.
class RootShell extends StatefulWidget {
  final AppState appState;

  const RootShell({super.key, required this.appState});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  void _goToTab(int index) => setState(() => _tabIndex = index);

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
                  return IndexedStack(
                    index: _tabIndex,
                    children: [
                      HomeScreen(
                        key: ValueKey('${appState.selectedCity}|${appState.method}|${appState.madhab}'),
                        appState: appState,
                      ),
                      MoreScreen(),
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
