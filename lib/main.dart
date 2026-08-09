import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation.dart';
import 'screens/azan_playing_screen.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge on Android: draw behind the status/navigation bars (system
  // bars become transparent) rather than reserving opaque bands for them.
  // Every screen already insets its content with SafeArea, so this only
  // changes what's visible *behind* the system bars, not the layout.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const PrayerTimeApp());
}

class PrayerTimeApp extends StatefulWidget {
  final AppState? appState;

  const PrayerTimeApp({super.key, this.appState});

  @override
  State<PrayerTimeApp> createState() => _PrayerTimeAppState();
}

class _PrayerTimeAppState extends State<PrayerTimeApp> with WidgetsBindingObserver {
  late final AppState _appState = widget.appState ?? AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState.notifications.onNotificationTapped = (fired) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AzanPlayingScreen(kind: fired.kind, azanSoundId: fired.azanSoundId),
        ),
      );
    };
    _appState.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catches the user coming straight back from the Now Bar permission
    // screen (see AppState.openNowBarSettings) so Settings reflects the
    // change immediately instead of waiting for the next 1-minute tick.
    if (state == AppLifecycleState.resumed) {
      _appState.refreshNowBarPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder here (rather than deeper down, e.g. in RootShell) is
    // what lets `themeMode` below actually react to Settings changing it —
    // MaterialApp is what resolves light/dark/system into a real theme, so
    // the listener has to sit at or above it.
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Намаз Times',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _appState.themeMode,
          home: _ThemedRoot(appState: _appState),
        );
      },
    );
  }
}

/// Bridges `MaterialApp`'s resolved brightness — light/dark/system, already
/// including live OS theme changes — into [AppColors]' active palette and
/// into the system status/navigation bar icon contrast.
///
/// [AppColors] is a static facade rather than an inherited/context lookup
/// (see its doc comment), so it needs exactly one place to stay in sync;
/// this is that place. It has to sit *below* `MaterialApp` (as `home`) —
/// only there does `Theme.of(context)` see the theme MaterialApp actually
/// picked, rather than whatever (if anything) is above the app.
class _ThemedRoot extends StatelessWidget {
  final AppState appState;

  const _ThemedRoot({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.setDark(isDark);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: RootShell(appState: appState),
    );
  }
}
