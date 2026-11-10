import '../widgets/app_tap.dart';
import '../widgets/app_switch.dart';
import '../services/now_bar_bridge.dart';
import 'now_bar_sheet.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/ambient_surface.dart';
import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/prayer_day.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../models/notif_mode.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/icon_badge.dart';
import '../widgets/app_toast.dart';
import '../widgets/notif_mode_selector.dart';
import '../widgets/notifications_blocked_notice.dart';
import '../widgets/prayer_icon.dart';
import 'city_screen.dart';

/// First-run setup: the handful of choices that decide what the app shows
/// (city above all — prayer times are coordinates) walked through one at a
/// time, each with a line on why it matters.
///
/// Everything here already has a working default, so this is about making
/// those defaults deliberate rather than leaving someone on Tashkent's
/// schedule without noticing. It's shown once — see
/// [AppState.onboardingDone], which also treats a pre-existing install as
/// already set up.
class OnboardingScreen extends StatefulWidget {
  final AppState appState;

  const OnboardingScreen({super.key, required this.appState});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { language, theme, city, method, madhab, notifications, nowBar }

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _location = LocationService();
  final _geocoding = GeocodingService();

  static const _notifOrder = [
    ('fajr', PrayerKind.fajr),
    ('zuhr', PrayerKind.zuhr),
    ('asr', PrayerKind.asr),
    ('maghrib', PrayerKind.maghrib),
    ('isha', PrayerKind.isha),
  ];

  static const _barBridge = NowBarBridge();
  NowBarStatus? _barStatus;
  bool _barEnabled = false;
  bool _barBusy = false;
  AppLifecycleListener? _barLifecycle;

  @override
  void initState() {
    super.initState();
    _barLifecycle = AppLifecycleListener(onResume: _loadBar);
    _loadBar();
  }

  Future<void> _loadBar() async {
    final status = await _barBridge.status();
    if (mounted && status != null && !_barBusy) {
      setState(() {
        _barStatus = status;
        _barEnabled = status.enabled;
      });
    }
  }

  Future<void> _toggleBar(bool enabled) async {
    if (_barBusy) return;
    setState(() {
      _barBusy = true;
      _barEnabled = enabled;
    });
    if (enabled && !widget.appState.notificationsAllowed) {
      await widget.appState.notifications.requestPermissions();
      await widget.appState.refreshNotificationsAllowed();
    }
    await _barBridge.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _barBusy = false);
    await _loadBar();
  }

  int _index = 0;
  bool _transitioning = false;
  bool _detectingCity = false;
  String? _cityError;
  bool _permissionAsked = false;

  /// Set once the system prompt has been answered. Until then the
  /// notifications step shows the modes as they are rather than as blocked
  /// — permission isn't granted yet while the prompt is still up over it.
  bool _permissionAnswered = false;

  @override
  void dispose() {
    _barLifecycle?.dispose();
    _geocoding.close();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_transitioning) return;
    if (_index == _Step.values.length - 1) {
      setState(() => _transitioning = true);
      widget.appState.completeOnboarding();
      return;
    }
    setState(() {
      _index++;
      _transitioning = true;
    });
    // The system permission dialog belongs *here*, on the step that has
    // just explained what the notifications are for — not on the app's
    // first frame, where it used to fire before anything was on screen.
    if (_Step.values[_index] == _Step.notifications && !_permissionAsked) {
      _permissionAsked = true;
      _askPermission();
    }
    _pageController
        .animateToPage(
          _index,
          duration: _motion(context),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
          if (mounted) setState(() => _transitioning = false);
        });
  }

  Future<void> _askPermission() async {
    try {
      await widget.appState.notifications.requestPermissions();
    } catch (_) {
      // Whatever the platform says next is still the answer to show.
    }
    await widget.appState.refreshNotificationsAllowed();
    if (mounted) setState(() => _permissionAnswered = true);
  }

  void _back() {
    if (_index == 0 || _transitioning) return;
    setState(() {
      _index--;
      _transitioning = true;
    });
    _pageController
        .animateToPage(
          _index,
          duration: _motion(context),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
          if (mounted) setState(() => _transitioning = false);
        });
  }

  /// Same flow as CityScreen's own "detect automatically": GPS fix, reverse
  /// geocode for a display name, then hand the coordinates to AppState.
  Future<void> _detectCity() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _detectingCity = true;
      _cityError = null;
    });

    try {
      final position = await _location.determinePosition();
      if (!mounted) return;
      final geocoded = await _geocoding.reverse(
        position.latitude,
        position.longitude,
        language: t.localeName,
      );
      if (!mounted) return;

      final applied = await widget.appState.selectCity(
        City(
          id: City.customId(position.latitude, position.longitude),
          englishCity: geocoded?.city ?? t.cityCurrentLocation,
          englishCountry: geocoded?.country ?? '',
          latitude: position.latitude,
          longitude: position.longitude,
          timeZone: '',
          isCustom: true,
        ),
      );
      if (!mounted) return;
      setState(() => _detectingCity = false);
      if (!applied) {
        AppToast.show(
          context,
          t.errorOfflineSettingsChange,
          icon: Icons.wifi_off_rounded,
        );
      }
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _detectingCity = false;
        _cityError = switch (e.error) {
          LocationError.serviceDisabled => t.cityLocationServiceDisabled,
          LocationError.permissionDenied ||
          LocationError.permissionDeniedForever =>
            t.cityLocationPermissionDenied,
          LocationError.unknown => t.cityLocationErrorGeneric,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detectingCity = false;
        _cityError = t.cityLocationErrorGeneric;
      });
    }
  }

  /// City, method and madhab all need a fetch to take effect (see
  /// AppState), so an offline tap is refused rather than silently ignored.
  Future<void> _applyOrWarn(Future<bool> Function() change) async {
    final t = AppLocalizations.of(context)!;
    final applied = await change();
    if (!mounted || applied) return;
    AppToast.show(
      context,
      t.errorOfflineSettingsChange,
      icon: Icons.wifi_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isLast = _index == _Step.values.length - 1;
        return AmbientScaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, 0),
                child: _StepProgress(
                  current: _index,
                  total: _Step.values.length,
                  label: t.onboardingStepLabel(_index + 1, _Step.values.length),
                ),
              ),
              Expanded(
                child: AmbientPageMotion(
                  positions: [
                    for (var i = 0; i < _Step.values.length; i++)
                      AmbientNavigationObserver.positions[i %
                          AmbientNavigationObserver.positions.length],
                  ],
                  child: PageView(
                    controller: _pageController,
                    // Driven by the buttons only: a stray swipe shouldn't skip
                    // past the city, which is the one choice that actually
                    // changes what the app shows.
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _languageStep(t),
                      _themeStep(t),
                      _cityStep(t),
                      _methodStep(t),
                      _madhabStep(t),
                      _notificationsStep(t),
                      _nowBarStep(t),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, padding.bottom + 16),
                child: Row(
                  children: [
                    AnimatedSize(
                      duration: _motion(context),
                      curve: Curves.easeInOutCubic,
                      child: IgnorePointer(
                        ignoring: _index == 0 || _transitioning,
                        child: AnimatedSwitcher(
                          duration: _motion(context),
                          child: _index > 0
                              ? Padding(
                                  key: const ValueKey('setup-back'),
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _SecondaryButton(
                                    label: t.onboardingBack,
                                    onTap: _back,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PrimaryButton(
                        label: isLast
                            ? (_barEnabled
                                  ? t.onboardingFinish
                                  : t.onboardingSkip)
                            : t.onboardingNext,
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageStep(AppLocalizations t) {
    final appState = widget.appState;
    return _StepShell(
      icon: Icons.translate_rounded,
      title: t.onboardingLanguageTitle,
      body: t.onboardingLanguageBody,
      children: [
        for (final locale in AppLocale.values)
          _OptionTile(
            label: locale.label,
            selected: appState.locale == locale,
            onTap: () => appState.setLocale(locale),
          ),
      ],
    );
  }

  Widget _themeStep(AppLocalizations t) {
    final appState = widget.appState;
    const modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    return _StepShell(
      icon: Icons.palette_rounded,
      title: t.onboardingThemeTitle,
      body: t.onboardingThemeBody,
      children: [
        for (final mode in modes)
          _OptionTile(
            icon: switch (mode) {
              ThemeMode.light => Icons.light_mode_rounded,
              ThemeMode.dark => Icons.dark_mode_rounded,
              ThemeMode.system => Icons.brightness_auto_rounded,
            },
            label: switch (mode) {
              ThemeMode.light => t.themeLight,
              ThemeMode.dark => t.themeDark,
              ThemeMode.system => t.themeSystem,
            },
            selected: appState.themeMode == mode,
            onTap: () => appState.setThemeMode(mode),
          ),
      ],
    );
  }

  Widget _cityStep(AppLocalizations t) {
    final appState = widget.appState;
    return _StepShell(
      icon: Icons.location_on_rounded,
      grouped: false,
      title: t.onboardingCityTitle,
      body: t.onboardingCityBody,
      children: [
        GlassPanel(
          key: const ValueKey('setup-selected-city'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.onboardingCitySelected.toUpperCase(),
                style: AppTextStyles.body(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent700,
                ).copyWith(letterSpacing: 0.9),
              ),
              const SizedBox(height: 4),
              Text(
                appState.cityLabel(t),
                style: AppTextStyles.heading(fontSize: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          key: const ValueKey('setup-city-actions'),
          child: GroupRows(
            children: [
              _OptionTile(
                icon: Icons.my_location_rounded,
                label: t.onboardingCityDetect,
                selected: false,
                trailing: _detectingCity
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : null,
                onTap: _detectingCity ? null : _detectCity,
              ),
              _OptionTile(
                icon: Icons.search_rounded,
                label: t.onboardingCityManual,
                selected: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CityScreen(appState: appState),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_cityError != null) ...[
          const SizedBox(height: 10),
          Text(
            _cityError!,
            style: AppTextStyles.body(
              fontSize: 13,
              color: AppColors.text,
            ).copyWith(color: AppColors.text.withValues(alpha: 0.6)),
          ),
        ],
      ],
    );
  }

  Widget _methodStep(AppLocalizations t) {
    final appState = widget.appState;
    return _StepShell(
      icon: Icons.calculate_rounded,
      title: t.onboardingMethodTitle,
      body: t.onboardingMethodBody,
      children: [
        for (final method in ReferenceData.methods)
          _OptionTile(
            label: methodLabelFor(t, method.id),
            selected: appState.method == method.id,
            onTap: () => _applyOrWarn(() => appState.selectMethod(method.id)),
          ),
      ],
    );
  }

  Widget _madhabStep(AppLocalizations t) {
    final appState = widget.appState;
    return _StepShell(
      icon: Icons.menu_book_rounded,
      title: t.onboardingMadhabTitle,
      body: t.onboardingMadhabBody,
      children: [
        for (final (id, label) in [
          ('hanafi', t.madhabHanafi),
          ('shafi', t.madhabShafi),
        ])
          _OptionTile(
            label: label,
            selected: appState.madhab == id,
            onTap: () => _applyOrWarn(() => appState.selectMadhab(id)),
          ),
      ],
    );
  }

  Widget _nowBarStep(AppLocalizations t) {
    final status = _barStatus;
    final samsung = status?.isNowBar ?? false;
    return _StepShell(
      icon: Icons.notifications_active_rounded,
      grouped: false,
      title: samsung ? t.nowBarTitle : t.persistentNotifTitle,
      body: t.onboardingNowBarBody,
      children: [
        GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AnimatedCopy(
                    samsung
                        ? t.nowBarSwitchLabel
                        : t.persistentNotifSwitchLabel,
                    style: AppTextStyles.body(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                IgnorePointer(
                  ignoring: _barBusy,
                  child: AppSwitch(value: _barEnabled, onChanged: _toggleBar),
                ),
              ],
            ),
          ),
        ),
        if (_barEnabled && !widget.appState.notificationsAllowed) ...[
          const SizedBox(height: 16),
          NotificationsBlockedNotice(
            onAllow: widget.appState.allowNotifications,
          ),
        ],
        if (_barEnabled && status != null && status.needsDeveloperSwitch) ...[
          const SizedBox(height: 16),
          NowBarDeveloperSwitchCard(status: status),
        ],
      ],
    );
  }

  Widget _notificationsStep(AppLocalizations t) {
    final appState = widget.appState;
    final blocked = _permissionAnswered && !appState.notificationsAllowed;
    return _StepShell(
      icon: Icons.notifications_active_rounded,
      grouped: false,
      title: t.onboardingNotifTitle,
      body: t.onboardingNotifBody,
      children: [
        AnimatedSize(
          duration: _motion(context),
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: _motion(context),
            child: blocked
                ? Padding(
                    key: const ValueKey('setup-notifications-blocked'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NotificationsBlockedNotice(
                      onAllow: appState.allowNotifications,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        GlassPanel(
          key: const ValueKey('setup-notification-prayers'),
          child: GroupRows(
            children: [
              for (final (key, kind) in _notifOrder)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        iconForPrayer(kind),
                        size: 18,
                        color: AppColors.accent700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nameForPrayer(t, kind),
                          style: AppTextStyles.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NotifModeSelector(
                        value:
                            appState.notifMode[key] ?? NotifMode.notification,
                        onChanged: (mode) => appState.setNotifMode(key, mode),
                        enabled: !blocked,
                        onBlockedTap: () => AppToast.show(
                          context,
                          t.notifBlockedToast,
                          icon: Icons.notifications_off_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // The selector is three icons wide with nothing naming them, so the
        // key sits underneath rather than leaving people to guess which is
        // "silent" and which is "off".
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final mode in NotifMode.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode.icon,
                    size: 15,
                    color: AppColors.text.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    notifModeLabel(t, mode),
                    style: AppTextStyles.body(
                      fontSize: 12.5,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int current;
  final int total;
  final String label;

  const _StepProgress({
    required this.current,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: _motion(context),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppColors.accent
                        : AppColors.text.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _AnimatedCopy(
          label,
          style: AppTextStyles.body(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ).copyWith(color: AppColors.text.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

/// The shared frame every step sits in: mark, headline, the "why", then
/// whatever that step actually asks for.
class _StepShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;
  final bool grouped;

  const _StepShell({
    this.grouped = true,
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedCopy(title, style: AppTextStyles.heading(fontSize: 26)),
          const SizedBox(height: 8),
          _AnimatedCopy(
            body,
            style: AppTextStyles.body(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: .62),
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: grouped
                ? GlassPanel(
                    key: const ValueKey('setup-options-panel'),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [GroupRows(children: children)],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: BackdropGroup(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: children,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final row = AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: _motion(context),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: selected ? .12 : 0),
              AppColors.accent.withValues(alpha: selected ? .02 : 0),
            ],
          ),
        ),
        child: AppPressContent(
          child: Row(
            children: [
              if (icon != null) ...[
                IconBadge(icon!, size: 32, iconSize: 16),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _AnimatedCopy(
                  label,
                  style: AppTextStyles.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.accent700 : AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing!
              else
                AnimatedSwitcher(
                  duration: _motion(context),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey(true),
                          size: 19,
                          color: AppColors.accent700,
                        )
                      : const SizedBox(
                          key: ValueKey(false),
                          width: 19,
                          height: 19,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
    return row;
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) =>
      _SetupButton(label: label, onTap: onTap, primary: true);
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) =>
      _SetupButton(label: label, onTap: onTap);
}

class _SetupButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _SetupButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      child: GlassPanel(
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: primary ? AppColors.selectionGradient : null,
          ),
          alignment: Alignment.center,
          child: AppPressContent(
            child: _AnimatedCopy(
              label,
              style: AppTextStyles.body(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primary ? AppColors.accent700 : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration _motion(BuildContext context) =>
    Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 300);

class _AnimatedCopy extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _AnimatedCopy(this.text, {required this.style});
  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: _motion(context),
    curve: Curves.easeInOutCubic,
    alignment: Alignment.topLeft,
    child: AnimatedSwitcher(
      duration: _motion(context),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      child: Text(text, key: ValueKey(text), style: style),
    ),
  );
}
