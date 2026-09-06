import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/app_locale.dart';
import 'navigation.dart';
import 'screens/onboarding_screen.dart';
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

  // MaterialApp only cares about these two. Tracking them by hand — rather
  // than rebuilding on every AppState change — keeps a prayer being logged,
  // a schedule finishing loading, or a notification toggle from rebuilding
  // the whole app shell for nothing.
  late ThemeMode _themeMode = _appState.themeMode;
  late AppLocale _locale = _appState.locale;

  late final Widget _root = _ThemedRoot(appState: _appState);

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _appState.init();
  }

  void _onAppStateChanged() {
    if (_appState.themeMode == _themeMode && _appState.locale == _locale) {
      return;
    }
    setState(() {
      _themeMode = _appState.themeMode;
      _locale = _appState.locale;
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `home` is [_root], built once in the field above rather than inline:
    // recreating it here would tear down and rebuild the entire RootShell
    // subtree from scratch every time the theme or language changes, on top
    // of the recolor that change already causes.
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Prayer times',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      locale: _locale.localeValue,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _root,
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
      child: _Entry(appState: appState),
    );
  }
}

/// Picks between first-run setup and the app itself.
///
/// Watches only the two flags that decide that, the same narrowing
/// [_PrayerTimeAppState] does for the theme and locale — [RootShell] and
/// [OnboardingScreen] both listen to whatever else they need on their own,
/// and neither wants a rebuild every time a prayer gets logged.
class _Entry extends StatefulWidget {
  final AppState appState;

  const _Entry({required this.appState});

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  late bool _restored = widget.appState.isRestored;
  late bool _onboardingDone = widget.appState.onboardingDone;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    final appState = widget.appState;
    if (appState.isRestored == _restored &&
        appState.onboardingDone == _onboardingDone) {
      return;
    }
    setState(() {
      _restored = appState.isRestored;
      _onboardingDone = appState.onboardingDone;
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Settings are read from disk in milliseconds, but showing setup and
    // then yanking it away once they land would be worse than a blank
    // frame or two of the app's own background.
    if (!_restored) return ColoredBox(color: AppColors.bg);
    if (!_onboardingDone) {
      return OnboardingScreen(appState: widget.appState);
    }
    return RootShell(appState: widget.appState);
  }
}
