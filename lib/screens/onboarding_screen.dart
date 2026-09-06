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
import '../widgets/app_toast.dart';
import '../widgets/notif_mode_selector.dart';
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

enum _Step { language, theme, city, method, madhab, notifications }

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

  int _index = 0;
  bool _detectingCity = false;
  String? _cityError;
  bool _permissionAsked = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _Step.values.length - 1) {
      widget.appState.completeOnboarding();
      return;
    }
    setState(() => _index++);
    // The system permission dialog belongs *here*, on the step that has
    // just explained what the notifications are for — not on the app's
    // first frame, where it used to fire before anything was on screen.
    if (_Step.values[_index] == _Step.notifications && !_permissionAsked) {
      _permissionAsked = true;
      widget.appState.notifications.requestPermissions();
    }
    _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
    _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final isLast = _index == _Step.values.length - 1;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, padding.top + 20, 18, 0),
                child: _StepProgress(
                  current: _index,
                  total: _Step.values.length,
                  label: t.onboardingStepLabel(_index + 1, _Step.values.length),
                ),
              ),
              Expanded(
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
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, padding.bottom + 18),
                child: Row(
                  children: [
                    if (_index > 0) ...[
                      _SecondaryButton(label: t.onboardingBack, onTap: _back),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _PrimaryButton(
                        label: isLast ? t.onboardingFinish : t.onboardingNext,
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
      title: t.onboardingCityTitle,
      body: t.onboardingCityBody,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
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
        const SizedBox(height: 12),
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
            MaterialPageRoute(builder: (_) => CityScreen(appState: appState)),
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

  Widget _notificationsStep(AppLocalizations t) {
    final appState = widget.appState;
    return _StepShell(
      icon: Icons.notifications_active_rounded,
      title: t.onboardingNotifTitle,
      body: t.onboardingNotifBody,
      children: [
        for (final (key, kind) in _notifOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
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
                    value: appState.notifMode[key] ?? NotifMode.notification,
                    onChanged: (mode) => appState.setNotifMode(key, mode),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
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
        Text(
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

  const _StepShell({
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: AppColors.accent700),
        ),
        const SizedBox(height: 18),
        Text(title, style: AppTextStyles.heading(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          body,
          style: AppTextStyles.body(fontSize: 14, color: AppColors.text)
              .copyWith(
                color: AppColors.text.withValues(alpha: 0.62),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 22),
        ...children,
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent100 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.accent700 : AppColors.text,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (selected)
                Icon(Icons.check_rounded, size: 19, color: AppColors.accent700),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.bg,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
