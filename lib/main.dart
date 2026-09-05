import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/app_locale.dart';
import 'navigation.dart';
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

class _PrayerTimeAppState extends State<PrayerTimeApp> {
  late final AppState _appState = widget.appState ?? AppState();

  @override
  void initState() {
    super.initState();
    _appState.init();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder here (rather than deeper down, e.g. in RootShell) is
    // what lets `themeMode` below actually react to Settings changing it —
    // MaterialApp is what resolves light/dark/system into a real theme, so
    // the listener has to sit at or above it.
    //
    // `home` is passed in via `child` rather than built inside the builder:
    // every AppState.notifyListeners() call (city, madhab, notif mode, …)
    // would otherwise recreate `_ThemedRoot` — and with it the entire
    // RootShell subtree — from scratch on every change, which is what made
    // toggling the theme (a full recolor on top of that) visibly janky.
    // With `child`, that subtree keeps its widget identity across unrelated
    // state changes; it still rebuilds correctly when the theme itself
    // changes, since `_ThemedRoot.build` reads `Theme.of(context)` and so
    // is separately notified by that InheritedWidget regardless.
    return AnimatedBuilder(
      animation: _appState,
      child: _ThemedRoot(appState: _appState),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Prayer times',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _appState.themeMode,
          locale: _appState.locale.localeValue,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    );
  }
}

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
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: RootShell(appState: appState),
    );
  }
}
